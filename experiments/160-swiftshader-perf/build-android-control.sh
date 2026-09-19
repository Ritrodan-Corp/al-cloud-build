#!/usr/bin/env bash
set -Eeuo pipefail

readonly TAG='android-14.0.0_r45'
readonly SWIFTSHADER_COMMIT='32ad39a320606948f09692cb91b71e1cd95d0e51'
readonly ROOT="${RUNNER_TEMP:?}/aosp-r45-pastel"
readonly OUT_DIR_BUILD="${RUNNER_TEMP:?}/aosp-r45-pastel-out"
readonly ART="${GITHUB_WORKSPACE:?}/experiments/160-swiftshader-perf/out-control"
readonly REPO_BIN="${RUNNER_TEMP:?}/repo"
readonly PASTEL_VARIANT="${PASTEL_VARIANT:-stock}"

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

case "$PASTEL_VARIANT" in
  stock)
    VARIANT_DESC='unmodified stock-control SwiftShader source'
    ;;
  jit-neoverse-n1)
    python3 - <<'PY'
from pathlib import Path

path = Path("external/swiftshader/src/Reactor/LLVMJIT.cpp")
text = path.read_text()
needle = "llvm::sys::getHostCPUName()"
assert text.count(needle) == 2, "unexpected r45 JIT host-CPU call count"
text = text.replace(needle, '"neoverse-n1"')
path.write_text(text)
PY
    grep -Fq 'jitTargetMachineBuilder.setCPU("neoverse-n1")'       external/swiftshader/src/Reactor/LLVMJIT.cpp
    VARIANT_DESC='Reactor JIT CPU forced to LLVM 10 neoverse-n1 processor model'
    git -C external/swiftshader diff -- src/Reactor/LLVMJIT.cpp | tee "$ART/swiftshader-variant.patch"
    ;;
  marl-worker-race)
    MARL_PATCH="$ART/marl-worker-race.patch"
    curl -LfsS \
      https://github.com/google/marl/commit/535d49182e6c87e4d999ac25f61c729a66687be8.patch \
      -o "$MARL_PATCH"
    printf '%s  %s\n' \
      '3a1463dcc62c581fae2787fd4ba21dfedf2f27f1babc0143b7e973e610ba1b64' \
      "$MARL_PATCH" | sha256sum -c -
    git -C external/swiftshader apply --check \
      --directory=third_party/marl "$MARL_PATCH"
    git -C external/swiftshader apply \
      --directory=third_party/marl "$MARL_PATCH"
    grep -Fq 'void spinForWorkAndLock() ACQUIRE(work.mutex);' \
      external/swiftshader/third_party/marl/include/marl/scheduler.h
    grep -Fq 'nextSpinningWorkerIdx % cfg.workerThread.count' \
      external/swiftshader/third_party/marl/src/scheduler.cpp
    grep -Fq 'void Scheduler::Worker::spinForWorkAndLock()' \
      external/swiftshader/third_party/marl/src/scheduler.cpp
    VARIANT_DESC='upstream Marl 535d49182 worker sleep-race fix'
    git -C external/swiftshader diff -- \
      third_party/marl/include/marl/scheduler.h \
      third_party/marl/src/scheduler.cpp \
      third_party/marl/src/scheduler_bench.cpp \
      > "$ART/swiftshader-variant.patch"
    ;;
  aot-neoverse-n1)
    python3 - <<'PY'
from pathlib import Path

path = Path("external/swiftshader/src/Android.bp")
text = path.read_text()

anchors = [
    '''cc_defaults {
    name: "libswiftshadervk_llvm_defaults",

    header_libs:''',
    '''cc_defaults {
    name: "libvk_swiftshader_defaults",
    vendor: true,

    defaults: [ "swiftshader_common" ],

    cflags: [
        "-D_GNU_SOURCE",''',
]
assert all(anchor in text for anchor in anchors), "unexpected pinned SwiftShader Android.bp"

reactor_old = '''    cflags: [
        "-DREACTOR_ANONYMOUS_MMAP_NAME=swiftshader_jit",'''
reactor_new = '''    cflags: [
        "-mcpu=neoverse-n1",
        "-DREACTOR_ANONYMOUS_MMAP_NAME=swiftshader_jit",'''
assert text.count(reactor_old) == 1
text = text.replace(reactor_old, reactor_new)

renderer_old = '''    cflags: [
        "-D_GNU_SOURCE",'''
renderer_new = '''    cflags: [
        "-mcpu=neoverse-n1",
        "-D_GNU_SOURCE",'''
assert text.count(renderer_old) == 1
text = text.replace(renderer_old, renderer_new)

path.write_text(text)
PY
    test "$(grep -c -- '-mcpu=neoverse-n1' external/swiftshader/src/Android.bp)" -eq 2
    grep -Fq '"neoverse-n1"' \
      prebuilts/clang/host/linux-x86/clang-r487747c/include/llvm/TargetParser/AArch64TargetParser.h
    VARIANT_DESC='AOT SwiftShader renderer and Reactor host code targeted to Neoverse N1'
    git -C external/swiftshader diff -- src/Android.bp \
      > "$ART/swiftshader-variant.patch"
    ;;
  aot-neoverse-n1-reactor-ir-cleanup)
    python3 - <<'PY'
from pathlib import Path

bp = Path("external/swiftshader/src/Android.bp")
text = bp.read_text()
reactor_old = '''    cflags: [
        "-DREACTOR_ANONYMOUS_MMAP_NAME=swiftshader_jit",'''
reactor_new = '''    cflags: [
        "-mcpu=neoverse-n1",
        "-DREACTOR_ANONYMOUS_MMAP_NAME=swiftshader_jit",'''
renderer_old = '''    cflags: [
        "-D_GNU_SOURCE",'''
renderer_new = '''    cflags: [
        "-mcpu=neoverse-n1",
        "-D_GNU_SOURCE",'''
assert text.count(reactor_old) == 1
assert text.count(renderer_old) == 1
text = text.replace(reactor_old, reactor_new, 1)
text = text.replace(renderer_old, renderer_new, 1)
bp.write_text(text)

jit = Path("external/swiftshader/src/Reactor/LLVMJIT.cpp")
text = jit.read_text()
old = '''\tif(optimizationLevel > 0)
\t{
\t\tpassManager.add(llvm::createSROAPass());
\t\tpassManager.add(llvm::createInstructionCombiningPass());
\t}'''
new = '''\tif(optimizationLevel > 0)
\t{
\t\tpassManager.add(llvm::createSROAPass());
\t\tpassManager.add(llvm::createSCCPPass());
\t\tpassManager.add(llvm::createCFGSimplificationPass());
\t\tpassManager.add(llvm::createEarlyCSEPass());
\t\tpassManager.add(llvm::createCFGSimplificationPass());
\t\tpassManager.add(llvm::createInstructionCombiningPass());
\t}'''
assert text.count(old) == 1, "unexpected LLVM10 Reactor pass sequence"
jit.write_text(text.replace(old, new, 1))
PY
    test "$(grep -c -- '-mcpu=neoverse-n1' external/swiftshader/src/Android.bp)" -eq 2
    grep -Fq 'int optimizationLevel = 2;  // Default' external/swiftshader/src/Reactor/Pragma.cpp
    grep -Fq 'passManager.add(llvm::createSCCPPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp
    grep -Fq 'passManager.add(llvm::createEarlyCSEPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp
    test "$(grep -c 'passManager.add(llvm::createCFGSimplificationPass());' external/swiftshader/src/Reactor/LLVMJIT.cpp)" -eq 2
    VARIANT_DESC='AOT Neoverse-N1 plus historical SwiftShader Vulkan LLVM10 IR cleanup: SROA/SCCP/SimplifyCFG/EarlyCSE/SimplifyCFG/InstCombine; backend Default'
    git -C external/swiftshader diff -- src/Android.bp src/Reactor/LLVMJIT.cpp \
      > "$ART/swiftshader-variant.patch"
    ;;
  aot-neoverse-n1-reactor-ir-cleanup-profile)
    python3 - <<'PY2'
from pathlib import Path

bp = Path("external/swiftshader/src/Android.bp")
text = bp.read_text()
reactor_old = '''    cflags: [
        "-DREACTOR_ANONYMOUS_MMAP_NAME=swiftshader_jit",'''
reactor_new = '''    cflags: [
        "-mcpu=neoverse-n1",
        "-DREACTOR_ANONYMOUS_MMAP_NAME=swiftshader_jit",'''
renderer_old = '''    cflags: [
        "-D_GNU_SOURCE",'''
renderer_new = '''    cflags: [
        "-mcpu=neoverse-n1",
        "-D_GNU_SOURCE",'''
assert text.count(reactor_old) == 1
assert text.count(renderer_old) == 1
text = text.replace(reactor_old, reactor_new, 1)
text = text.replace(renderer_old, renderer_new, 1)
bp.write_text(text)
PY2
    git -C external/swiftshader apply \
      "$GITHUB_WORKSPACE/experiments/160-swiftshader-perf/reactor-ir-pass-profile.patch"
    test "$(grep -c -- '-mcpu=neoverse-n1' external/swiftshader/src/Android.bp)" -eq 2
    grep -Fq 'ALCLOUD_JIT_PASS' external/swiftshader/src/Reactor/LLVMJIT.cpp
    grep -Fq 'ALCLOUD_JIT_BACKEND' external/swiftshader/src/Reactor/LLVMJIT.cpp
    grep -Fq 'ALCLOUD_JIT_ROUTINE' external/swiftshader/src/Reactor/LLVMJIT.cpp
    grep -Fq 'runProfiledPass("EarlyCSE"' external/swiftshader/src/Reactor/LLVMJIT.cpp
    grep -Fq 'int optimizationLevel = 2;  // Default' external/swiftshader/src/Reactor/Pragma.cpp
    VARIANT_DESC='AOT N1 + winning IR cleanup + pass timing/IR-count/backend/materialization instrumentation only'
    git -C external/swiftshader diff -- src/Android.bp src/Reactor/LLVMJIT.cpp \
      > "$ART/swiftshader-variant.patch"
    ;;
  raster-pitch-precompute)
    python3 - <<'PY'
from pathlib import Path

path = Path("external/swiftshader/src/Device/QuadRasterizer.cpp")
text = path.read_text()

old_decl = '''\tPointer<Byte> cBuffer[MAX_COLOR_BUFFERS];
\tPointer<Byte> zBuffer;
\tPointer<Byte> sBuffer;

\tInt clusterCountLog2 = 31 - Ctlz(UInt(clusterCount), false);'''
new_decl = '''\tPointer<Byte> cBuffer[MAX_COLOR_BUFFERS];
\tPointer<Byte> zBuffer;
\tPointer<Byte> sBuffer;
\tInt cBufferStride[MAX_COLOR_BUFFERS];
\tInt zBufferStride;
\tInt sBufferStride;

\tInt clusterCountLog2 = 31 - Ctlz(UInt(clusterCount), false);
\tInt clusterPitchShift = 1 + clusterCountLog2;'''
assert text.count(old_decl) == 1
text = text.replace(old_decl, new_decl)

old_color = '''\t\tif(state.colorWriteActive(index))
\t\t{
\t\t\tcBuffer[index] = *Pointer<Pointer<Byte>>(data + OFFSET(DrawData, colorBuffer[index])) + yMin * *Pointer<Int>(data + OFFSET(DrawData, colorPitchB[index]));
\t\t}'''
new_color = '''\t\tif(state.colorWriteActive(index))
\t\t{
\t\t\tInt pitch = *Pointer<Int>(data + OFFSET(DrawData, colorPitchB[index]));
\t\t\tcBuffer[index] = *Pointer<Pointer<Byte>>(data + OFFSET(DrawData, colorBuffer[index])) + yMin * pitch;
\t\t\tcBufferStride[index] = pitch << clusterPitchShift;
\t\t}'''
assert text.count(old_color) == 1
text = text.replace(old_color, new_color)

old_depth = '''\tif(state.depthTestActive || state.depthBoundsTestActive)
\t{
\t\tzBuffer = *Pointer<Pointer<Byte>>(data + OFFSET(DrawData, depthBuffer)) + yMin * *Pointer<Int>(data + OFFSET(DrawData, depthPitchB));
\t}'''
new_depth = '''\tif(state.depthTestActive || state.depthBoundsTestActive)
\t{
\t\tInt pitch = *Pointer<Int>(data + OFFSET(DrawData, depthPitchB));
\t\tzBuffer = *Pointer<Pointer<Byte>>(data + OFFSET(DrawData, depthBuffer)) + yMin * pitch;
\t\tzBufferStride = pitch << clusterPitchShift;
\t}'''
assert text.count(old_depth) == 1
text = text.replace(old_depth, new_depth)

old_stencil = '''\tif(state.stencilActive)
\t{
\t\tsBuffer = *Pointer<Pointer<Byte>>(data + OFFSET(DrawData, stencilBuffer)) + yMin * *Pointer<Int>(data + OFFSET(DrawData, stencilPitchB));
\t}'''
new_stencil = '''\tif(state.stencilActive)
\t{
\t\tInt pitch = *Pointer<Int>(data + OFFSET(DrawData, stencilPitchB));
\t\tsBuffer = *Pointer<Pointer<Byte>>(data + OFFSET(DrawData, stencilBuffer)) + yMin * pitch;
\t\tsBufferStride = pitch << clusterPitchShift;
\t}'''
assert text.count(old_stencil) == 1
text = text.replace(old_stencil, new_stencil)

old_updates = '''\t\tfor(int index = 0; index < MAX_COLOR_BUFFERS; index++)
\t\t{
\t\t\tif(state.colorWriteActive(index))
\t\t\t{
\t\t\t\tcBuffer[index] += *Pointer<Int>(data + OFFSET(DrawData, colorPitchB[index])) << (1 + clusterCountLog2);  // FIXME: Precompute
\t\t\t}
\t\t}

\t\tif(state.depthTestActive || state.depthBoundsTestActive)
\t\t{
\t\t\tzBuffer += *Pointer<Int>(data + OFFSET(DrawData, depthPitchB)) << (1 + clusterCountLog2);  // FIXME: Precompute
\t\t}

\t\tif(state.stencilActive)
\t\t{
\t\t\tsBuffer += *Pointer<Int>(data + OFFSET(DrawData, stencilPitchB)) << (1 + clusterCountLog2);  // FIXME: Precompute
\t\t}'''
new_updates = '''\t\tfor(int index = 0; index < MAX_COLOR_BUFFERS; index++)
\t\t{
\t\t\tif(state.colorWriteActive(index))
\t\t\t{
\t\t\t\tcBuffer[index] += cBufferStride[index];
\t\t\t}
\t\t}

\t\tif(state.depthTestActive || state.depthBoundsTestActive)
\t\t{
\t\t\tzBuffer += zBufferStride;
\t\t}

\t\tif(state.stencilActive)
\t\t{
\t\t\tsBuffer += sBufferStride;
\t\t}'''
assert text.count(old_updates) == 1
text = text.replace(old_updates, new_updates)

path.write_text(text)
PY
    test "$(grep -c 'FIXME: Precompute' external/swiftshader/src/Device/QuadRasterizer.cpp)" -eq 0
    grep -Fq 'cBuffer[index] += cBufferStride[index];' \
      external/swiftshader/src/Device/QuadRasterizer.cpp
    grep -Fq 'zBuffer += zBufferStride;' \
      external/swiftshader/src/Device/QuadRasterizer.cpp
    grep -Fq 'sBuffer += sBufferStride;' \
      external/swiftshader/src/Device/QuadRasterizer.cpp
    VARIANT_DESC='precompute invariant color/depth/stencil cluster row strides in QuadRasterizer'
    git -C external/swiftshader diff -- src/Device/QuadRasterizer.cpp \
      > "$ART/swiftshader-variant.patch"
    ;;
  *)
    echo "Unsupported PASTEL_VARIANT: $PASTEL_VARIANT" >&2
    exit 2
    ;;
esac
printf 'pastel_variant=%s\n' "$PASTEL_VARIANT" | tee "$ART/variant.txt"

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

# vulkan.pastel is a Soong module. Do not invoke legacy Make/Kati module
# traversal for this control build: the broad PDK checkout contains unrelated
# Android.mk tests whose optional source closures are intentionally absent.
#
# Run 15 used --skip-make, but r45 implements that flag by setting skipConfig
# as well as skipKati. That suppresses the product-config pass which writes
# BUILD_ID and the other Make product variables into soong.variables. The
# resulting empty BuildId made unrelated APEX test variants fail global Soong
# analysis before vulkan.pastel could compile.
#
# r45's --soong-only mode is the intended narrow module-build path here: it
# skips Kati generation and Kati Ninja, while preserving product configuration.
# Verify those exact pinned-source semantics before relying on it.
python3 - <<'PY'
from pathlib import Path

text = Path("build/soong/ui/build/config.go").read_text()
needle = '} else if arg == "--soong-only" {'
assert needle in text, "--soong-only is absent from pinned r45"
block = text.split(needle, 1)[1].split("} else if", 1)[0]
assert "c.skipKati = true" in block
assert "c.skipKatiNinja = true" in block
assert "c.skipConfig = true" not in block
PY
grep -Fq 'BUILD_ID=UD2A.240505.001.W1' build/make/core/build_id.mk
grep -Fq '$(call add_json_str,  BuildId,                           $(BUILD_ID))' \
  build/make/core/soong_config.mk

# The selected partial PDK tree can emit unrelated duplicate final-Ninja rules
# for absent Java/product modules such as core-icu4j. r45 hardcodes
# dupbuild=err first, then appends NINJA_ARGS. Verify that pinned-source order
# before using a target-scoped warning override.
python3 - <<'PY'
from pathlib import Path

text = Path("build/soong/ui/build/ninja.go").read_text()
hard = text.index('"-w", "dupbuild=err"')
extra = text.index('cmd.Environment.Get("NINJA_ARGS")')
assert hard < extra
PY
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
export NINJA_ARGS='-w dupbuild=warn'

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
[ "$NINJA_ARGS" = '-w dupbuild=warn' ]
printf 'ALLOW_MISSING_DEPENDENCIES=%s\n' "$ALLOW_MISSING_DEPENDENCIES"
printf 'SOONG_ALLOW_MISSING_DEPENDENCIES=%s\n' "$SOONG_ALLOW_MISSING_DEPENDENCIES"
printf 'BUILD_BROKEN_DISABLE_BAZEL=%s\n' "$BUILD_BROKEN_DISABLE_BAZEL"
printf 'NINJA_ARGS=%s\n' "$NINJA_ARGS"

# The final r45 soong_build Android.bp analysis can consume ~14 GB RSS on the
# standard 15.6 GB GitHub-hosted runner and nearly exhaust its default 3 GB
# swap. Allow selected retries to add temporary swap without changing normal
# builds. Keep enough root-disk headroom for the final target Ninja outputs.
EXTRA_SWAP_GB="${PASTEL_EXTRA_SWAP_GB:-0}"
if ! [[ "$EXTRA_SWAP_GB" =~ ^[0-9]+$ ]] || [ "$EXTRA_SWAP_GB" -gt 12 ]; then
  echo "PASTEL_EXTRA_SWAP_GB must be an integer from 0 through 12" >&2
  exit 2
fi
if [ "$EXTRA_SWAP_GB" -gt 0 ]; then
  SWAPFILE="${RUNNER_TEMP}/alcloud-pastel-${EXTRA_SWAP_GB}g.swap"
  AVAILABLE_KB="$(df -Pk / | awk 'NR == 2 { print $4 }')"
  REQUIRED_KB="$(( (EXTRA_SWAP_GB + 10) * 1024 * 1024 ))"
  if [ "$AVAILABLE_KB" -lt "$REQUIRED_KB" ]; then
    echo "Refusing extra swap: need ${EXTRA_SWAP_GB} GiB plus 10 GiB disk headroom" >&2
    exit 1
  fi
  sudo fallocate -l "${EXTRA_SWAP_GB}G" "$SWAPFILE"
  sudo chmod 600 "$SWAPFILE"
  sudo mkswap "$SWAPFILE"
  sudo swapon "$SWAPFILE"
  printf 'PASTEL_EXTRA_SWAP_GB=%s\n' "$EXTRA_SWAP_GB"
  free -h
  swapon --show
fi

# Optional diagnostics for hosted-runner shutdown investigation. The final
# soong_build Android.bp analysis is one Go process and is not bounded by
# Ninja's -j value. Print low-frequency host/cgroup memory and top-RSS process
# telemetry to both the Actions log and the artifact directory so an exit-143
# runner loss can be distinguished from memory pressure.
DIAG_PID=''
if [ "${PASTEL_DIAGNOSTICS:-0}" = 1 ]; then
  (
    while :; do
      {
        printf '\n== pastel resource telemetry %s ==\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo || true
        CGROUP_REL="$(awk -F: '$1 == "0" { print $3 }' /proc/self/cgroup)"
        CGROUP_BASE="/sys/fs/cgroup${CGROUP_REL}"
        for metric in memory.current memory.peak memory.high memory.max memory.swap.current memory.swap.peak memory.swap.max memory.events memory.pressure cpu.pressure; do
          if [ -r "${CGROUP_BASE}/${metric}" ]; then
            printf '%s: ' "${metric}"
            tr '\n' ' ' < "${CGROUP_BASE}/${metric}" || true
            printf '\n'
          fi
        done
        grep -E '^(oom_kill|allocstall|pgmajfault|pswpin|pswpout) ' /proc/vmstat || true
        printf '%s\n' '-- top RSS processes --'
        ps -eo pid,ppid,rss,%mem,%cpu,stat,comm,args --sort=-rss | head -n 12 || true
      } | tee -a "$ART/resource-monitor.log"
      sleep 20
    done
  ) &
  DIAG_PID=$!
  trap 'if [ -n "$DIAG_PID" ]; then kill "$DIAG_PID" 2>/dev/null || true; wait "$DIAG_PID" 2>/dev/null || true; fi' EXIT
fi

# Keep compile parallelism conservative on the standard 15.6 GB hosted runner.
# --soong-only preserves the product-config pass which seeds soong.variables,
# then skips Kati generation and Kati Ninja so unrelated Android.mk modules are
# not traversed. Normal Soong analysis and Ninja execution still validate this
# Android.bp target. --skip-soong-tests omits only Soong's own bootstrap test
# actions; any missing dependency in vulkan.pastel's reachable graph still
# becomes an error rule and stops the build.
m --soong-only --skip-soong-tests -j2 vulkan.pastel 2>&1 | tee "$ART/build.log"
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
Variant: ${PASTEL_VARIANT} - ${VARIANT_DESC}
Source closure: Android 14 r45 platform manifest groups pdk,path:packages/modules/common,-darwin on Linux
Global partial graph mode: ALLOW_MISSING_DEPENDENCIES=true
Mixed Bazel analysis: disabled with BUILD_BROKEN_DISABLE_BAZEL=true
Additional hosted-runner swap: ${EXTRA_SWAP_GB} GiB
Target validation: vulkan.pastel and its reachable dependency graph must build successfully
Live target path: /vendor/lib64/hw/vulkan.pastel.so
Live SHA-256 reference: 67c210363a565a8a9376c4e6ddaa349f79e2aa08828c9a2151f18aa932398f90
Live build ID reference: a84688481a52cf740d0af7938960f25e
EOF

log_disk
