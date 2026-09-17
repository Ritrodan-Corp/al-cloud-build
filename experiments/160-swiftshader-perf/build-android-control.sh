#!/usr/bin/env bash
set -Eeuo pipefail

readonly TAG='android-14.0.0_r45'
readonly SWIFTSHADER_COMMIT='32ad39a320606948f09692cb91b71e1cd95d0e51'
readonly ROOT="${RUNNER_TEMP:?}/aosp-r45-pastel"
readonly OUT_DIR_BUILD="${RUNNER_TEMP:?}/aosp-r45-pastel-out"
readonly ART="${GITHUB_WORKSPACE:?}/experiments/160-swiftshader-perf/out-control"
readonly REPO_BIN="${RUNNER_TEMP:?}/repo"

rm -rf "$ROOT" "$OUT_DIR_BUILD" "$ART"
mkdir -p "$ROOT" "$ART"

log_disk() {
  echo "== disk =="
  df -h /
  du -sh "$ROOT" 2>/dev/null || true
}

# The runner is ephemeral. Prefer a complete, reproducible build-tool closure
# over prematurely minimizing checkout size. Reclaim unrelated runner payloads
# first, but do not prune AOSP host toolchains after they are synced.
sudo rm -rf \
  /usr/share/dotnet \
  /usr/local/lib/android \
  /opt/ghc \
  /usr/local/share/boost \
  /opt/hostedtoolcache/CodeQL 2>/dev/null || true
sudo apt-get clean || true
log_disk

curl -LfsS https://storage.googleapis.com/git-repo-downloads/repo -o "$REPO_BIN"
chmod 0755 "$REPO_BIN"

cd "$ROOT"
"$REPO_BIN" init \
  -u https://android.googlesource.com/platform/manifest \
  -b "$TAG" \
  --depth=1 \
  --no-clone-bundle

# Bootstrap the source-of-truth build-tool dependency list from the r45
# prebuilts/build-tools repository itself. Its manifest.xml is the closure
# Google uses to produce Android host build tools, and includes support
# projects such as spdx-tools, go-cmp and starlark-go that a hand-maintained
# minimal list repeatedly missed.
"$REPO_BIN" sync -c -j4 --no-tags --no-clone-bundle prebuilts/build-tools

test -s prebuilts/build-tools/manifest.xml
sha256sum prebuilts/build-tools/manifest.xml | tee "$ART/build-tools-manifest-sha256.txt"

mapfile -t BUILD_TOOL_PROJECTS < <(
  python3 - <<'PY'
import xml.etree.ElementTree as ET
root = ET.parse('prebuilts/build-tools/manifest.xml').getroot()
paths = set()
for project in root.findall('project'):
    path = project.attrib.get('path')
    if not path:
        continue
    # The Actions host is Linux; Darwin host prebuilts are not useful here.
    if '/darwin' in path or path.startswith('prebuilts/go/darwin'):
        continue
    paths.add(path)
for path in sorted(paths):
    print(path)
PY
)

# Projects needed specifically to build Android 14's ARM64 SwiftShader/Pastel
# HAL. Some are already in the build-tools manifest; the final union is
# deduplicated below. JDK17/Bazel are explicit because they are release build
# requirements even if the historical build-tools manifest contains older host
# variants.
PASTEL_PROJECTS=(
  build/make
  build/bazel
  build/bazel_common_rules
  build/blueprint
  build/soong
  external/bazel-skylib
  external/swiftshader
  external/libcxx
  external/libcxxabi
  external/zlib
  external/googletest
  bionic
  frameworks/native
  hardware/interfaces
  hardware/libhardware
  system/core
  system/libbase
  system/libhidl
  system/logging
  system/tools/hidl
  system/libfmq
  system/tools/aidl
  system/tools/xsdc
  packages/modules/common
  prebuilts/bazel/common
  prebuilts/bazel/linux-x86_64
  prebuilts/clang/host/linux-x86
  prebuilts/go/linux-x86
  prebuilts/jdk/jdk17
  prebuilts/build-tools
)

# Only request paths that exist in the r45 platform manifest, and fail before
# the expensive sync if either upstream closure contains an unavailable path.
mapfile -t AVAILABLE_PROJECTS < <("$REPO_BIN" list -p | sort -u)
declare -A AVAILABLE=()
for path in "${AVAILABLE_PROJECTS[@]}"; do
  AVAILABLE["$path"]=1
done

ALL_PROJECTS=()
declare -A SEEN=()
for path in "${BUILD_TOOL_PROJECTS[@]}" "${PASTEL_PROJECTS[@]}"; do
  if [[ -z "${AVAILABLE[$path]:-}" ]]; then
    echo "required r45 project not present in platform manifest: $path" >&2
    exit 1
  fi
  if [[ -z "${SEEN[$path]:-}" ]]; then
    ALL_PROJECTS+=("$path")
    SEEN["$path"]=1
  fi
done

printf 'build_tools_manifest_projects=%s\n' "${#BUILD_TOOL_PROJECTS[@]}"
printf 'total_synced_projects=%s\n' "${#ALL_PROJECTS[@]}"
printf '%s\n' "${ALL_PROJECTS[@]}" > "$ART/synced-projects.txt"

"$REPO_BIN" sync -c -j4 --no-tags --no-clone-bundle "${ALL_PROJECTS[@]}"

# Verify exact source identity and core platform inputs before invoking Soong.
test "$(git -C external/swiftshader rev-parse HEAD)" = "$SWIFTSHADER_COMMIT"
printf '%s\n' "$SWIFTSHADER_COMMIT" > "$ART/source-commit.txt"
grep -F 'ClangDefaultVersion      = "clang-r487747c"' \
  build/soong/cc/config/global.go
test -d external/spdx-tools
test -d external/golang-protobuf/proto
test -d external/starlark-go/starlark
test -d frameworks/native
test -f hardware/libhardware/Android.bp
log_disk

export ALLOW_MISSING_DEPENDENCIES=true
export OUT_DIR="$OUT_DIR_BUILD"
export TARGET_BUILD_APPS=

# AOSP envsetup/lunch functions intentionally probe optional unset variables.
set +u
source build/envsetup.sh
lunch module_arm64only-eng

# The hosted runner reports 15.6 GB RAM while AOSP warns that ~16 GB is the
# minimum. Favor reliability over compile speed for the first stock control.
m -j2 vulkan.pastel 2>&1 | tee "$ART/build.log"
set -u

LIB=$(find "$OUT_DIR_BUILD" -type f \
  -path '*/vendor/lib64/hw/vulkan.pastel.so' -print -quit)
if [ -z "$LIB" ]; then
  LIB=$(find "$OUT_DIR_BUILD" -type f -name 'vulkan.pastel.so' -print -quit)
fi
[ -n "$LIB" ] && [ -f "$LIB" ]

cp "$LIB" "$ART/vulkan.pastel.so"
sha256sum "$ART/vulkan.pastel.so" | tee "$ART/sha256.txt"
file "$ART/vulkan.pastel.so" | tee "$ART/file.txt"
readelf -h "$ART/vulkan.pastel.so" > "$ART/elf-header.txt"
readelf -n "$ART/vulkan.pastel.so" > "$ART/elf-notes.txt" || true
readelf -d "$ART/vulkan.pastel.so" > "$ART/dynamic.txt"
nm -D --defined-only "$ART/vulkan.pastel.so" > "$ART/dynsym.txt" || true

cat > "$ART/control-manifest.txt" <<EOF
Android tag: ${TAG}
SwiftShader commit: ${SWIFTSHADER_COMMIT}
Soong target: vulkan.pastel
Product: module_arm64only-eng
Variant: unmodified stock-control source
Build-tool closure: r45 prebuilts/build-tools/manifest.xml + Pastel-specific union
Live target path: /vendor/lib64/hw/vulkan.pastel.so
Live SHA-256 reference: 67c210363a565a8a9376c4e6ddaa349f79e2aa08828c9a2151f18aa932398f90
Live build ID reference: a84688481a52cf740d0af7938960f25e
EOF

log_disk
