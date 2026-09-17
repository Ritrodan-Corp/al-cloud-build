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

# Use Android 14 r45's own platform PDK selection. The PDK group supplies the
# complete build-system bootstrap closure and the platform sources needed for
# module development, while avoiding a full Android checkout. Darwin host
# projects are excluded because the Actions runner is Linux.
"$REPO_BIN" init \
  -u https://android.googlesource.com/platform/manifest \
  -b "$TAG" \
  -g 'pdk,-darwin' \
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
# and Linux host toolchain before invoking Soong.
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

test ! -e prebuilts/bazel/darwin-x86_64
test ! -e prebuilts/clang/host/darwin-x86
test ! -e prebuilts/go/darwin-x86

ACTUAL_SWIFTSHADER_COMMIT="$(git -C external/swiftshader rev-parse HEAD)"
printf '%s\n' "$ACTUAL_SWIFTSHADER_COMMIT" | tee "$ART/source-commit.txt"
test "$ACTUAL_SWIFTSHADER_COMMIT" = "$SWIFTSHADER_COMMIT"

grep -F 'ClangDefaultVersion      = "clang-r487747c"' \
  build/soong/cc/config/global.go
grep -q 'name: "vulkan.pastel"' external/swiftshader/src/Android.bp

# A plain PDK source checkout is intentionally not a globally closed Android.bp
# graph. Android 14 r45 supports this through ALLOW_MISSING_DEPENDENCIES. Guard
# against accidentally relying on behavior that is absent from the pinned
# release: soong_build must read the setting and bp2build must propagate it.
grep -Fq 'configuration.Getenv("ALLOW_MISSING_DEPENDENCIES") == "true"' \
  build/soong/cmd/soong_build/main.go
grep -Fq 'ctx.SetAllowMissingDependencies(ctx.Config().AllowMissingDependencies())' \
  build/soong/cmd/soong_build/main.go
log_disk

export OUT_DIR="$OUT_DIR_BUILD"
unset TARGET_BUILD_APPS || true

# Run 10 proved that the PDK checkout has the full Soong/Blueprint bootstrap
# closure, but several unrelated Android tests/framework modules refer to
# providers in pdk-fs/pdk-cw-fs projects. Permit those global graph holes using
# AOSP's partial-source mechanism. Missing dependencies are retained on the
# affected Android modules as error build rules, so this cannot make the
# requested vulkan.pastel target succeed if its own transitive closure is
# incomplete.
export ALLOW_MISSING_DEPENDENCIES=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true

# AOSP envsetup/lunch functions intentionally probe optional unset variables,
# so nounset must be disabled while using the Android build environment.
set +u
source build/envsetup.sh
lunch module_arm64only-eng

# Reassert and print the settings after lunch so the Actions log proves exactly
# what the subsequent Soong invocation receives.
export ALLOW_MISSING_DEPENDENCIES=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true
[ "$ALLOW_MISSING_DEPENDENCIES" = true ]
[ "$SOONG_ALLOW_MISSING_DEPENDENCIES" = true ]
printf 'ALLOW_MISSING_DEPENDENCIES=%s\n' "$ALLOW_MISSING_DEPENDENCIES"
printf 'SOONG_ALLOW_MISSING_DEPENDENCIES=%s\n' "$SOONG_ALLOW_MISSING_DEPENDENCIES"

# Keep compile parallelism conservative on the standard 15.6 GB hosted runner.
# Building only this target remains the validation: any missing dependency in
# vulkan.pastel's reachable graph becomes an error rule and stops the build.
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
Global partial graph mode: ALLOW_MISSING_DEPENDENCIES=true
Target validation: vulkan.pastel and its reachable dependency graph must build successfully
Live target path: /vendor/lib64/hw/vulkan.pastel.so
Live SHA-256 reference: 67c210363a565a8a9376c4e6ddaa349f79e2aa08828c9a2151f18aa932398f90
Live build ID reference: a84688481a52cf740d0af7938960f25e
EOF

log_disk
