#!/usr/bin/env bash
set -euxo pipefail

ROOT="${RUNNER_TEMP:?RUNNER_TEMP must be set}"
ANDROID_API=34
NDK_DIR=android-ndk-r27d
LIBDRM_VERSION=libdrm-2.4.122
LIBDRM_INSTALL="$ROOT/libdrm-install-arm64"
LLVM_SRC="$ROOT/llvm-project-19.1.7.src"
LLVM_BUILD="$ROOT/llvm-build-arm64"
LLVM_INSTALL="$ROOT/llvm-install-arm64"
MESA_SRC="$ROOT/mesa-25.0.0"
MESA_BUILD="$ROOT/mesa-build-arm64-orcjit"
MESA_INSTALL="$ROOT/mesa-install-arm64-orcjit"
CROSS_FILE="$ROOT/aarch64-linux-android.txt"
AUDIT="$ROOT/exp153-audit"
OUT="$ROOT/exp153-mesa-arm64-deploy"
mkdir -p "$AUDIT"

cd "$ROOT"
curl -fL --retry 3 --retry-delay 2 -o android-ndk-r27d-linux.zip \
  https://dl.google.com/android/repository/android-ndk-r27d-linux.zip
echo '22105e410cf29afcf163760cc95522b9fb981121  android-ndk-r27d-linux.zip' | sha1sum -c -
unzip -q android-ndk-r27d-linux.zip

curl -fL --retry 3 --retry-delay 2 -o libdrm-2.4.122.tar.xz \
  https://dri.freedesktop.org/libdrm/libdrm-2.4.122.tar.xz
echo 'd9f5079b777dffca9300ccc56b10a93588cdfbc9dde2fae111940dfb6292f251  libdrm-2.4.122.tar.xz' | sha256sum -c -
tar -xf libdrm-2.4.122.tar.xz

curl -fL --retry 3 --retry-delay 2 -o llvm-project-19.1.7.src.tar.xz \
  https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/llvm-project-19.1.7.src.tar.xz
echo '82401fea7b79d0078043f7598b835284d6650a75b93e64b6f761ea7b63097501  llvm-project-19.1.7.src.tar.xz' | sha256sum -c -
tar -xf llvm-project-19.1.7.src.tar.xz

curl -fL --retry 3 --retry-delay 2 -o mesa-25.0.0.tar.xz \
  https://archive.mesa3d.org/mesa-25.0.0.tar.xz
echo '96a53501fd59679654273258c6c6a1055a20e352ee1429f0b123516c7190e5b0  mesa-25.0.0.tar.xz' | sha256sum -c -
tar -xf mesa-25.0.0.tar.xz

NDK="$ROOT/$NDK_DIR"
test -x "$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang"

cat > "$CROSS_FILE" <<EOF
[binaries]
ar = '$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar'
c = ['ccache', '$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables']
cpp = ['ccache', '$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang++', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '--start-no-unused-arguments', '-static-libstdc++', '--end-no-unused-arguments']
c_ld = 'lld'
cpp_ld = 'lld'
strip = '$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip'
pkg-config = ['/usr/bin/pkgconf']

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'

[properties]
needs_exe_wrapper = true
pkg_config_libdir = '$LIBDRM_INSTALL/lib/pkgconfig'
EOF

meson setup "$ROOT/libdrm-build-arm64" "$ROOT/$LIBDRM_VERSION" \
  --cross-file "$CROSS_FILE" \
  --prefix="$LIBDRM_INSTALL" \
  --libdir=lib \
  -Dnouveau=disabled \
  -Dintel=disabled \
  -Dvc4=disabled \
  -Dfreedreno=disabled \
  -Detnaviv=disabled
ninja -j4 -C "$ROOT/libdrm-build-arm64"
ninja -C "$ROOT/libdrm-build-arm64" install
test -f "$LIBDRM_INSTALL/lib/pkgconfig/libdrm.pc"
rm -rf "$ROOT/$LIBDRM_VERSION" "$ROOT/libdrm-build-arm64" "$ROOT/libdrm-2.4.122.tar.xz"

cmake -GNinja -S "$LLVM_SRC/llvm" -B "$LLVM_BUILD" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM="android-${ANDROID_API}" \
  -DANDROID_NDK="$NDK" \
  -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
  -DCMAKE_ANDROID_NDK="$NDK" \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DCMAKE_SYSTEM_NAME=Android \
  -DCMAKE_SYSTEM_VERSION="$ANDROID_API" \
  -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL" \
  -DCMAKE_CXX_FLAGS="-march=armv8-a --target=aarch64-linux-android${ANDROID_API}" \
  -DLLVM_HOST_TRIPLE="aarch64-linux-android${ANDROID_API}" \
  -DLLVM_TARGETS_TO_BUILD=AArch64 \
  -DLLVM_BUILD_LLVM_DYLIB=OFF \
  -DLLVM_BUILD_TESTS=OFF \
  -DLLVM_BUILD_EXAMPLES=OFF \
  -DLLVM_BUILD_DOCS=OFF \
  -DLLVM_BUILD_TOOLS=OFF \
  -DLLVM_ENABLE_RTTI=ON \
  -DLLVM_USE_INTEL_JITEVENTS=OFF \
  -DLLVM_BUILD_INSTRUMENTED_COVERAGE=OFF \
  -DLLVM_NATIVE_TOOL_DIR="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin" \
  -DLLVM_ENABLE_PIC=False \
  -DLLVM_OPTIMIZED_TABLEGEN=ON

ninja -j4 -C "$LLVM_BUILD" install

test -f "$LLVM_INSTALL/include/llvm/IR/IRBuilder.h"
required_orc_archives=(
  libLLVMOrcJIT.a
  libLLVMOrcShared.a
  libLLVMOrcTargetProcess.a
  libLLVMExecutionEngine.a
  libLLVMRuntimeDyld.a
  libLLVMJITLink.a
)
for archive in "${required_orc_archives[@]}"; do
  test -f "$LLVM_INSTALL/lib/$archive"
done
find "$LLVM_INSTALL/lib" -maxdepth 1 -type f -name 'libLLVM*.a' -printf '%f\n' | sort | tee "$AUDIT/llvm-static-archives.txt"
printf 'LLVM RTTI: enabled\nLLVM Intel JIT events: disabled\n' | tee "$AUDIT/llvm-build-mode.txt"

rm -rf "$LLVM_SRC" "$LLVM_BUILD" "$ROOT/llvm-project-19.1.7.src.tar.xz"

mkdir -p "$MESA_SRC/subprojects/llvm"
mapfile -t LLVM_LIBS < <(find "$LLVM_INSTALL/lib" -maxdepth 1 -type f -name 'libLLVM*.a' -printf '%f\n' | sed 's/\.a$//' | sort)
test "${#LLVM_LIBS[@]}" -gt 20
{
  echo "project('llvm', ['cpp'])"
  echo "cpp = meson.get_compiler('cpp')"
  echo "_deps = []"
  echo "_search = join_paths('$LLVM_INSTALL', 'lib')"
  printf "foreach d: ["
  first=1
  for lib in "${LLVM_LIBS[@]}"; do
    if [ "$first" -eq 0 ]; then printf ", "; fi
    printf "'%s'" "$lib"
    first=0
  done
  echo "]"
  echo "  _deps += cpp.find_library(d, dirs : _search)"
  echo "endforeach"
  echo "dep_llvm = declare_dependency("
  echo "  include_directories : include_directories('$LLVM_INSTALL/include'),"
  echo "  dependencies : _deps,"
  echo "  version : '19.1.7',"
  echo ")"
  echo "has_rtti = true"
  echo "irbuilder_h = files('$LLVM_INSTALL/include/llvm/IR/IRBuilder.h')"
} > "$MESA_SRC/subprojects/llvm/meson.build"

cd "$MESA_SRC"
meson setup "$MESA_BUILD" \
  --cross-file "$CROSS_FILE" \
  --wrap-mode=nofallback \
  --force-fallback-for=llvm \
  -Dllvm:werror=false \
  -Dprefix="$MESA_INSTALL" \
  -Dlibdir=lib \
  -Dbuildtype=release \
  -Dplatforms=android \
  -Degl-native-platform=android \
  -Degl=enabled \
  -Dgbm=disabled \
  -Dglx=disabled \
  -Dglvnd=disabled \
  -Dandroid-stub=true \
  -Dplatform-sdk-version="$ANDROID_API" \
  -Dandroid-libbacktrace=disabled \
  -Dcpp_rtti=true \
  -Dvalgrind=disabled \
  -Dlibunwind=disabled \
  -Dbuild-tests=false \
  -Denable-glcpp-tests=false \
  -Dgallium-opencl=disabled \
  -Dgallium-rusticl=false \
  -Dgallium-vdpau=disabled \
  -Dgallium-va=disabled \
  -Dgallium-xa=disabled \
  -Dgallium-nine=false \
  -Dgallium-drivers=llvmpipe \
  -Dvulkan-drivers=[] \
  -Dvulkan-layers=[] \
  -Dvideo-codecs=[] \
  -Dllvm=enabled \
  -Dllvm-orcjit=true \
  -Dshared-llvm=disabled

meson configure "$MESA_BUILD" | tee "$AUDIT/mesa-configure.txt"
grep -E 'llvm-orcjit[[:space:]]+true' "$AUDIT/mesa-configure.txt"

ninja -C "$MESA_BUILD" -t commands > "$AUDIT/ninja-commands.txt"
grep -F 'gallivm/lp_bld_init_orc.cpp' "$AUDIT/ninja-commands.txt" | tee "$AUDIT/orcjit-compile-proof.txt"
if grep -F 'gallivm/lp_bld_init.c' "$AUDIT/ninja-commands.txt"; then
  echo 'MCJIT Gallivm implementation is unexpectedly present in build commands.' >&2
  exit 1
fi

ninja -j4 -C "$MESA_BUILD"
ninja -C "$MESA_BUILD" install

GALLIUM_SO="$(find "$MESA_INSTALL" -type f -name 'libgallium_dri.so' -print -quit)"
test -n "$GALLIUM_SO"
READELF="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf"
NM="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm"
"$READELF" -h "$GALLIUM_SO" | tee "$AUDIT/libgallium-elf-header.txt"
grep -q 'Machine:.*AArch64' "$AUDIT/libgallium-elf-header.txt"
"$NM" -C "$GALLIUM_SO" > "$AUDIT/libgallium-symbols.txt" || true
grep -E 'LPJit|llvm::orc::LLJIT|llvm::MCJIT|GDBJITRegistrationListener' "$AUDIT/libgallium-symbols.txt" \
  > "$AUDIT/jit-symbol-summary.txt" || true

rm -rf "$OUT"
mkdir -p "$OUT/payload/lib" "$OUT/audit"
cp -a "$MESA_INSTALL"/. "$OUT/payload/"
cp -a "$LIBDRM_INSTALL/lib"/libdrm.so* "$OUT/payload/lib/"
cp -a "$AUDIT"/. "$OUT/audit/"

find "$OUT/payload" -type f \( -name '*.so' -o -name '*.so.*' \) -print0 \
  | while IFS= read -r -d '' f; do
      echo "=== ${f#$OUT/} ==="
      "$READELF" -h "$f" | grep -E 'Class:|Machine:|Type:'
      "$READELF" -d "$f" | grep -E 'NEEDED|SONAME' || true
    done | tee "$OUT/audit/elf-audit.txt"

grep -q 'Machine:.*AArch64' "$OUT/audit/elf-audit.txt"
find "$OUT/payload" -type f -print0 | sort -z | xargs -0 sha256sum > "$OUT/audit/payload.sha256"
{
  echo 'AL Cloud Experiment 153 ORCJIT deployment bundle'
  echo 'Mesa: 25.0.0'
  echo 'LLVM: 19.1.7'
  echo 'LLVM RTTI: enabled'
  echo 'LLVM Intel JIT events: disabled'
  echo 'JIT backend: ORCJIT / LLJIT'
  echo 'libdrm build dependency: 2.4.122'
  echo 'NDK: r27d 27.3.13750724'
  echo 'Android API: 34'
  echo 'ABI: arm64-v8a'
  echo 'Gallium driver: llvmpipe'
  echo 'Vulkan drivers: none'
  echo 'Platform: android'
  echo 'EGL: enabled'
  echo 'Runtime no-KMS mode: MESA_ANDROID_NO_KMS_SWRAST=1'
  echo 'Known risk: LLVM 19 AArch64 ORCJIT defaults to RuntimeDyld/SectionMemoryManager'
  du -sh "$OUT/payload"
} | tee "$OUT/audit/manifest.txt"

BUNDLE="$ROOT/exp153-mesa-25.0.0-android-arm64-llvmpipe-orcjit.tar.xz"
tar -C "$ROOT" -cJf "$BUNDLE" "$(basename "$OUT")"
sha256sum "$BUNDLE" | tee "$ROOT/exp153-mesa-bundle.sha256"
ls -lh "$BUNDLE"
