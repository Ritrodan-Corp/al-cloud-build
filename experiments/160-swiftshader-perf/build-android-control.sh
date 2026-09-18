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

# The GitHub-hosted runner is disposable. Reclaim unrelated preinstalled
# payloads before syncing AOSP, but do not prune the selected Android source or
# host toolchain after repo sync.
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

# Use Android 14 r45's platform PDK selection plus packages/modules/common.
# r45 puts several PDK-consumed Mainline defaults in packages/modules/common
# even though that project itself is tagged pdk-fs rather than plain pdk.
# Selecting its implicit path group restores those authoritative defaults
# without pulling the entire pdk-fs source set. Darwin host projects remain
# excluded because the Actions runner is Linux.
"$REPO_BIN" init \
  -u https://android.googlesource.com/platform/manifest \
  -b "$TAG" \
  -g 'pdk,path:packages/modules/common,-darwin' \
  -p linux \
  --depth=1 \
  --no-tags \
  --no-clone-bundle

"$REPO_BIN" sync \
  -c \
  -j4 \
  --no-tags \
  --no-clone-bundle

# Preserve the exact resolved source closure used by the control build.
"$REPO_BIN" manifest -r -o "$ART/pdk-manifest.xml"
"$REPO_BIN" list -p | sort -u > "$ART/synced-projects.txt"
printf 'synced_project_count=%s\n' "$(wc -l < "$ART/synced-projects.txt")"

# Verify the intended release, build-system bootstrap closure, target product,
# Mainline defaults needed by PDK source projects, and Linux host toolchain
# before invoking Soong.
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
test -f packages/modules/common/sdk/ModuleDefaults.bp
test -d prebuilts/bazel/common
test -d prebuilts/bazel/linux-x86_64
test -d prebuilts/clang/host/linux-x86
test -d prebuilts/go/linux-x86
test -d prebuilts/jdk/jdk17

grep -Fq 'name: "framework-module-common-defaults"' \
  packages/modules/common/sdk/ModuleDefaults.bp
grep -Fq 'name: "framework-system-server-module-defaults"' \
  packages/modules/common/sdk/ModuleDefaults.bp
grep -Fq 'name: "framework-sources-module-defaults"' \
  packages/modules/common/sdk/ModuleDefaults.bp
grep -Fq 'name: "non-updatable-framework-module-defaults"' \
  packages/modules/common/sdk/ModuleDefaults.bp

test ! -e prebuilts/bazel/darwin-x86_64
test ! -e prebuilts/clang/host/darwin-x86
test ! -e prebuilts/go/darwin-x86

ACTUAL_SWIFTSHADER_COMMIT="$(git -C external/swiftshader rev-parse HEAD)"
printf '%s\n' "$ACTUAL_SWIFTSHADER_COMMIT" | tee "$ART/source-commit.txt"
test "$ACTUAL_SWIFTSHADER_COMMIT" = "$SWIFTSHADER_COMMIT"

grep -F 'ClangDefaultVersion      = "clang-r487747c"' \
  build/soong/cc/config/global.go
grep -q 'name: "vulkan.pastel"' external/swiftshader/src/Android.bp

# Run 11 exposed why packages/modules/common is required in addition to plain
# pdk: packages/modules/Media inherits framework-system-server-module-defaults.
# Android.bp is free to format the defaults list across multiple lines, so only
# assert that the pinned Media file contains both the target module and the
# authoritative defaults module rather than matching one exact formatting form.
grep -Fq 'name: "service-media-s"' \
  packages/modules/Media/apex/service/Android.bp
grep -Fq '"framework-system-server-module-defaults"' \
  packages/modules/Media/apex/service/Android.bp

# The selected source checkout remains intentionally not globally closed.
# Android 14 r45 supports this through ALLOW_MISSING_DEPENDENCIES. Guard against
# accidentally relying on behavior absent from the pinned release: soong_build
# must read the setting and bp2build must propagate it.
grep -Fq 'configuration.Getenv("ALLOW_MISSING_DEPENDENCIES") == "true"' \
  build/soong/cmd/soong_build/main.go
grep -Fq 'ctx.SetAllowMissingDependencies(ctx.Config().AllowMissingDependencies())' \
  build/soong/cmd/soong_build/main.go

# Run 13's remaining failure came from mixed Bazel analysis of an unrelated
# Timezone test, not from vulkan.pastel's reachable dependency graph. r45 Soong
# exposes BUILD_BROKEN_DISABLE_BAZEL as the force-disable switch for that mixed
# analysis path. Verify the pinned source has that mechanism before using it.
grep -Fq 'IsBazelMixedBuildForceDisabled' build/soong/ui/build/config.go
grep -Fq 'BUILD_BROKEN_DISABLE_BAZEL' build/soong/ui/build/config.go

# vulkan.pastel is a Soong module. Do not invoke legacy Make/Kati for this
# control build: the broad PDK checkout contains unrelated Android.mk tests
# whose optional source closures are intentionally absent. r45's Soong driver
# must explicitly support --skip-make before we rely on this narrow path.
grep -Fq 'arg == "--skip-make"' build/soong/ui/build/config.go
log_disk

export OUT_DIR="$OUT_DIR_BUILD"
unset TARGET_BUILD_APPS || true

# Keep AOSP's partial-source mechanism for unrelated tests/framework modules
# whose providers live in other pdk-fs/pdk-cw-fs projects. The authoritative
# shared Mainline defaults are present explicitly, so those omissions can no
# longer silently change java_sdk_library API-scope semantics. Missing target
# dependencies remain error build rules and will stop vulkan.pastel itself.
export ALLOW_MISSING_DEPENDENCIES=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true
export BUILD_BROKEN_DISABLE_BAZEL=true

# AOSP envsetup/lunch functions intentionally probe optional unset variables,
# so nounset must be disabled while using the Android build environment.
set +u
source build/envsetup.sh
lunch module_arm64only-eng

# Reassert and print the settings after lunch so the Actions log proves exactly
# what the subsequent Soong invocation receives.
export ALLOW_MISSING_DEPENDENCIES=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true
export BUILD_BROKEN_DISABLE_BAZEL=true
[ "$ALLOW_MISSING_DEPENDENCIES" = true ]
[ "$SOONG_ALLOW_MISSING_DEPENDENCIES" = true ]
[ "$BUILD_BROKEN_DISABLE_BAZEL" = true ]
printf 'ALLOW_MISSING_DEPENDENCIES=%s\n' "$ALLOW_MISSING_DEPENDENCIES"
printf 'SOONG_ALLOW_MISSING_DEPENDENCIES=%s\n' "$SOONG_ALLOW_MISSING_DEPENDENCIES"
printf 'BUILD_BROKEN_DISABLE_BAZEL=%s\n' "$BUILD_BROKEN_DISABLE_BAZEL"

# Keep compile parallelism conservative on the standard 15.6 GB hosted runner.
# --skip-make prevents Kati from traversing unrelated Android.mk modules while
# retaining normal Soong analysis and Ninja execution for this Android.bp
# target. Any missing dependency in vulkan.pastel's reachable Soong graph still
# becomes an error rule and stops the build.
m --skip-make -j2 vulkan.pastel 2>&1 | tee "$ART/build.log"
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
Variant: unmodified stock-control SwiftShader source
Source closure: Android 14 r45 platform manifest groups pdk,path:packages/modules/common,-darwin on Linux
Global partial graph mode: ALLOW_MISSING_DEPENDENCIES=true
Mixed Bazel analysis: disabled with BUILD_BROKEN_DISABLE_BAZEL=true
Target validation: vulkan.pastel and its reachable dependency graph must build successfully
Live target path: /vendor/lib64/hw/vulkan.pastel.so
Live SHA-256 reference: 67c210363a565a8a9376c4e6ddaa349f79e2aa08828c9a2151f18aa932398f90
Live build ID reference: a84688481a52cf740d0af7938960f25e
EOF

log_disk
