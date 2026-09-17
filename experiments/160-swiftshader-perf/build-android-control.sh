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

# Standard public runners are free for this public repository. Reclaim image
# payloads unrelated to an Android platform build before syncing AOSP.
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

# Source projects needed by Soong itself and by the Android SwiftShader Pastel
# module. Large host-prebuilt projects are fetched separately below so that
# only the required host payloads are checked out. This list is intentionally
# evidence-driven: add a project only when Soong proves that the trimmed tree
# needs it.
SOURCE_PROJECTS=(
  build/make
  build/blueprint
  build/soong
  external/swiftshader
  external/libcxx
  external/libcxxabi
  external/zlib
  external/googletest
  external/golang-protobuf
  bionic
  frameworks/native
  hardware/interfaces
  system/core
  system/libbase
  system/libhidl
  system/logging
  system/tools/hidl
  system/libfmq
  system/tools/aidl
  system/tools/xsdc
)
"$REPO_BIN" sync -c -j4 --no-tags --no-clone-bundle "${SOURCE_PROJECTS[@]}"

test "$(git -C external/swiftshader rev-parse HEAD)" = "$SWIFTSHADER_COMMIT"
printf '%s\n' "$SWIFTSHADER_COMMIT" > "$ART/source-commit.txt"

clone_full() {
  local name="$1" path="$2"
  mkdir -p "$(dirname "$path")"
  git clone -q --depth=1 --branch "$TAG" \
    "https://android.googlesource.com/${name}" "$path"
}

clone_sparse() {
  local name="$1" path="$2"
  shift 2
  mkdir -p "$(dirname "$path")"
  git clone -q --depth=1 --branch "$TAG" --filter=blob:none --sparse \
    "https://android.googlesource.com/${name}" "$path"
  git -C "$path" sparse-checkout set "$@"
}

# r45 default compiler is clang-r487747c. Keep clang-3289846 because Soong
# still defines the legacy RenderScript tool path, plus stable tools/profiles.
clone_sparse platform/prebuilts/clang/host/linux-x86 \
  prebuilts/clang/host/linux-x86 \
  clang-r487747c clang-3289846 clang-stable llvm-binutils-stable profiles soong

clone_sparse platform/prebuilts/jdk/jdk17 \
  prebuilts/jdk/jdk17 \
  linux-x86

clone_full platform/prebuilts/go/linux-x86 \
  prebuilts/go/linux-x86

clone_full platform/prebuilts/build-tools \
  prebuilts/build-tools
rm -rf \
  prebuilts/build-tools/darwin-x86 \
  prebuilts/build-tools/linux_musl-arm64

# Verify the selected compiler before discarding repo metadata.
grep -F 'ClangDefaultVersion      = "clang-r487747c"' \
  build/soong/cc/config/global.go

# No further repo operations are needed. Reclaim shallow Git object storage.
rm -rf .repo
log_disk

export ALLOW_MISSING_DEPENDENCIES=true
export OUT_DIR="$OUT_DIR_BUILD"
export TARGET_BUILD_APPS=

# AOSP envsetup/lunch functions are not compatible with bash nounset because
# they intentionally probe optional variables such as TOP. Keep errexit and
# pipefail, but disable nounset only while using the AOSP shell environment.
set +u
source build/envsetup.sh
lunch module_arm64only-eng

# Build only the stock Android module. This must succeed unchanged before any
# Reactor optimization candidate is considered valid.
m -j4 vulkan.pastel 2>&1 | tee "$ART/build.log"
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
Live target path: /vendor/lib64/hw/vulkan.pastel.so
Live SHA-256 reference: 67c210363a565a8a9376c4e6ddaa349f79e2aa08828c9a2151f18aa932398f90
Live build ID reference: a84688481a52cf740d0af7938960f25e
EOF

log_disk
