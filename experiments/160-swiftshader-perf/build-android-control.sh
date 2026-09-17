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

# GitHub's hosted runner is disposable. Reclaim large unrelated preinstalled
# payloads before the AOSP checkout, but do not prune anything from the r45 PDK
# source/toolchain after repo sync. The first successful control build should
# prioritize reproducibility over minimum checkout size.
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

# Android 14 r45's own platform manifest is the source of truth. The pdk group
# contains the platform build system and development dependencies needed for
# module builds, including Soong/Blueprint, SwiftShader, graphics/HIDL sources,
# SPDX/go-cmp/starlark support, and the host toolchain. Explicitly exclude
# Darwin-host projects and select the Linux host platform.
"$REPO_BIN" init \
  -u https://android.googlesource.com/platform/manifest \
  -b "$TAG" \
  -g 'pdk,-darwin' \
  -p linux \
  --depth=1 \
  --no-tags \
  --no-clone-bundle

# Sync the complete r45 PDK selection instead of manually predicting Soong's
# dependency closure. Keep network parallelism moderate for runner stability.
"$REPO_BIN" sync \
  -c \
  -j4 \
  --no-tags \
  --no-clone-bundle

# Preserve the exact resolved source closure used for the control build.
"$REPO_BIN" manifest -r -o "$ART/pdk-manifest.xml"
"$REPO_BIN" list -p | sort -u > "$ART/synced-projects.txt"
printf 'synced_project_count=%s\n' "$(wc -l < "$ART/synced-projects.txt")"

# Verify the checkout is the intended Android release and Linux-only PDK
# environment before invoking Soong.
test -f build/envsetup.sh
test -f build/make/target/product/module_arm64only.mk
test -f build/make/target/board/module_arm64only/BoardConfig.mk
test -d build/blueprint
test -d build/soong
test -d external/go-cmp
test -d external/golang-protobuf/proto
test -d external/spdx-tools
test -d external/starlark-go/starlark
test -d external/swiftshader
test -d frameworks/native
test -d hardware/interfaces
test -f hardware/libhardware/Android.bp
test -d prebuilts/bazel/common
test -d prebuilts/bazel/linux-x86_64
test -d prebuilts/clang/host/linux-x86
test -d prebuilts/go/linux-x86
test -d prebuilts/jdk/jdk17

# Darwin host prebuilts should have been filtered by the manifest group.
test ! -e prebuilts/bazel/darwin-x86_64
test ! -e prebuilts/clang/host/darwin-x86
test ! -e prebuilts/go/darwin-x86

# Pin the exact SwiftShader source identity previously identified for r45.
ACTUAL_SWIFTSHADER_COMMIT="$(git -C external/swiftshader rev-parse HEAD)"
printf '%s\n' "$ACTUAL_SWIFTSHADER_COMMIT" | tee "$ART/source-commit.txt"
test "$ACTUAL_SWIFTSHADER_COMMIT" = "$SWIFTSHADER_COMMIT"

grep -F 'ClangDefaultVersion      = "clang-r487747c"' \
  build/soong/cc/config/global.go

grep -q 'name: "vulkan.pastel"' external/swiftshader/src/Android.bp
log_disk

export OUT_DIR="$OUT_DIR_BUILD"
unset ALLOW_MISSING_DEPENDENCIES || true
unset TARGET_BUILD_APPS || true

# AOSP envsetup/lunch functions intentionally probe optional unset variables,
# so nounset must be disabled while using the Android build environment.
set +u
source build/envsetup.sh
lunch module_arm64only-eng

# The standard hosted runner is close to AOSP's minimum recommended memory.
# Keep compile parallelism conservative for the first stock control build.
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
Source closure: Android 14 r45 platform manifest group pdk,-darwin on Linux
Missing dependencies allowed: no
Live target path: /vendor/lib64/hw/vulkan.pastel.so
Live SHA-256 reference: 67c210363a565a8a9376c4e6ddaa349f79e2aa08828c9a2151f18aa932398f90
Live build ID reference: a84688481a52cf740d0af7938960f25e
EOF

log_disk
