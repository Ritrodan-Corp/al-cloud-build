#!/usr/bin/env bash
set -euxo pipefail

: "${VARIANT:?VARIANT must be set}"
case "$VARIANT" in
  ndebug|n1|llvm-release|thinlto|jito3) ;;
  *) echo "Unknown VARIANT=$VARIANT" >&2; exit 2 ;;
esac

ANDROID_API=34
NDK_DIR=android-ndk-r27d
LIBDRM_VERSION=libdrm-2.4.122
LIBDRM_INSTALL_DIR=libdrm-install-arm64
LLVM_SRC_DIR=llvm-project-19.1.7.src
LLVM_BUILD_DIR=llvm-build-arm64
LLVM_INSTALL_DIR=llvm-install-arm64
MESA_SRC_DIR=mesa-25.0.0
ROOT="$RUNNER_TEMP"
NDK="$ROOT/$NDK_DIR"
LIBDRM_INSTALL="$ROOT/$LIBDRM_INSTALL_DIR"
LLVM_INSTALL="$ROOT/$LLVM_INSTALL_DIR"
CROSS_FILE="$ROOT/aarch64-linux-android.txt"

echo "variant=$VARIANT"
uname -a
nproc
free -h
df -h /

cd "$ROOT"
curl -fL --retry 3 --retry-delay 2 -o android-ndk-r27d-linux.zip https://dl.google.com/android/repository/android-ndk-r27d-linux.zip
echo '22105e410cf29afcf163760cc95522b9fb981121  android-ndk-r27d-linux.zip' | sha1sum -c -
unzip -q android-ndk-r27d-linux.zip

curl -fL --retry 3 --retry-delay 2 -o libdrm-2.4.122.tar.xz https://dri.freedesktop.org/libdrm/libdrm-2.4.122.tar.xz
echo 'd9f5079b777dffca9300ccc56b10a93588cdfbc9dde2fae111940dfb6292f251  libdrm-2.4.122.tar.xz' | sha256sum -c -
tar -xf libdrm-2.4.122.tar.xz

curl -fL --retry 3 --retry-delay 2 -o llvm-project-19.1.7.src.tar.xz https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/llvm-project-19.1.7.src.tar.xz
echo '82401fea7b79d0078043f7598b835284d6650a75b93e64b6f761ea7b63097501  llvm-project-19.1.7.src.tar.xz' | sha256sum -c -
tar -xf llvm-project-19.1.7.src.tar.xz

curl -fL --retry 3 --retry-delay 2 -o mesa-25.0.0.tar.xz https://archive.mesa3d.org/mesa-25.0.0.tar.xz
echo '96a53501fd59679654273258c6c6a1055a20e352ee1429f0b123516c7190e5b0  mesa-25.0.0.tar.xz' | sha256sum -c -
tar -xf mesa-25.0.0.tar.xz

test -x "$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang"

C_EXTRA=()
CXX_EXTRA=()
LLVM_CMAKE_C_FLAGS=""
LLVM_CMAKE_CXX_FLAGS="-march=armv8-a --target=aarch64-linux-android${ANDROID_API} -fno-rtti"
LLVM_BUILD_TYPE=MinSizeRel
MESA_EXTRA=()

case "$VARIANT" in
  ndebug)
    MESA_EXTRA+=("-Db_ndebug=true")
    ;;
  n1)
    C_EXTRA+=("-mcpu=neoverse-n1")
    CXX_EXTRA+=("-mcpu=neoverse-n1")
    LLVM_CMAKE_C_FLAGS="-mcpu=neoverse-n1 --target=aarch64-linux-android${ANDROID_API}"
    LLVM_CMAKE_CXX_FLAGS="-mcpu=neoverse-n1 --target=aarch64-linux-android${ANDROID_API} -fno-rtti"
    ;;
  llvm-release)
    LLVM_BUILD_TYPE=Release
    ;;
  thinlto)
    MESA_EXTRA+=("-Db_lto=true" "-Db_lto_mode=thin")
    ;;
esac

cat > "$CROSS_FILE" <<EOF
[binaries]
ar = '$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar'
c = ['ccache', '$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables'$(for a in "${C_EXTRA[@]}"; do printf ", '%s'" "$a"; done)]
cpp = ['ccache', '$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang++', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '--start-no-unused-arguments', '-static-libstdc++', '--end-no-unused-arguments'$(for a in "${CXX_EXTRA[@]}"; do printf ", '%s'" "$a"; done)]
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
cat "$CROSS_FILE"

SRC="$ROOT/$LIBDRM_VERSION"
BUILD="$ROOT/libdrm-build-arm64"
meson setup "$BUILD" "$SRC"   --cross-file "$CROSS_FILE"   --prefix="$LIBDRM_INSTALL"   --libdir=lib   -Dnouveau=disabled   -Dintel=disabled   -Dvc4=disabled   -Dfreedreno=disabled   -Detnaviv=disabled
ninja -j4 -C "$BUILD"
ninja -C "$BUILD" install
test -f "$LIBDRM_INSTALL/lib/pkgconfig/libdrm.pc"
rm -rf "$SRC" "$BUILD" "$ROOT/libdrm-2.4.122.tar.xz"

LLVM_SRC="$ROOT/$LLVM_SRC_DIR"
LLVM_BUILD="$ROOT/$LLVM_BUILD_DIR"
LLVM_ARGS=(
  -GNinja -S "$LLVM_SRC/llvm" -B "$LLVM_BUILD"
  "-DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake"
  -DANDROID_ABI=arm64-v8a
  "-DANDROID_PLATFORM=android-${ANDROID_API}"
  "-DANDROID_NDK=$NDK"
  -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a
  "-DCMAKE_ANDROID_NDK=$NDK"
  "-DCMAKE_BUILD_TYPE=$LLVM_BUILD_TYPE"
  -DCMAKE_SYSTEM_NAME=Android
  "-DCMAKE_SYSTEM_VERSION=$ANDROID_API"
  "-DCMAKE_INSTALL_PREFIX=$LLVM_INSTALL"
  "-DCMAKE_CXX_FLAGS=$LLVM_CMAKE_CXX_FLAGS"
  "-DLLVM_HOST_TRIPLE=aarch64-linux-android${ANDROID_API}"
  -DLLVM_TARGETS_TO_BUILD=AArch64
  -DLLVM_BUILD_LLVM_DYLIB=OFF
  -DLLVM_BUILD_TESTS=OFF
  -DLLVM_BUILD_EXAMPLES=OFF
  -DLLVM_BUILD_DOCS=OFF
  -DLLVM_BUILD_TOOLS=OFF
  -DLLVM_ENABLE_RTTI=OFF
  -DLLVM_BUILD_INSTRUMENTED_COVERAGE=OFF
  "-DLLVM_NATIVE_TOOL_DIR=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
  -DLLVM_ENABLE_PIC=False
  -DLLVM_OPTIMIZED_TABLEGEN=ON
)
if [ -n "$LLVM_CMAKE_C_FLAGS" ]; then
  LLVM_ARGS+=("-DCMAKE_C_FLAGS=$LLVM_CMAKE_C_FLAGS")
fi
cmake "${LLVM_ARGS[@]}"
ninja -j4 -C "$LLVM_BUILD" install
test -f "$LLVM_INSTALL/include/llvm/IR/IRBuilder.h"
archive_count=$(find "$LLVM_INSTALL/lib" -maxdepth 1 -type f -name 'libLLVM*.a' | wc -l)
test "$archive_count" -gt 20
rm -rf "$ROOT/$LLVM_SRC_DIR" "$ROOT/$LLVM_BUILD_DIR" "$ROOT/llvm-project-19.1.7.src.tar.xz"

MESA="$ROOT/$MESA_SRC_DIR"

if [ "$VARIANT" = jito3 ]; then
  JIT_SRC="$MESA/src/gallium/auxiliary/gallivm/lp_bld_init.c"
  test -f "$JIT_SRC"
  before_count=$(grep -c 'optlevel = Default;' "$JIT_SRC")
  test "$before_count" -eq 1
  python3 - "$JIT_SRC" <<'PY'
import sys
p=sys.argv[1]
s=open(p).read()
old='         optlevel = Default;'
new='         optlevel = Aggressive;'
assert s.count(old) == 1, s.count(old)
open(p,'w').write(s.replace(old,new,1))
PY
  test "$(grep -c 'optlevel = Aggressive;' "$JIT_SRC")" -eq 1
  test "$(grep -c 'optlevel = Default;' "$JIT_SRC")" -eq 0
  echo 'jito3_patch=lp_bld_init.c normal MCJIT codegen Default(O2)->Aggressive(O3)'
  grep -n -A8 -B5 'optlevel = Aggressive' "$JIT_SRC"
fi

mkdir -p "$MESA/subprojects/llvm"
mapfile -t LLVM_LIBS < <(find "$LLVM_INSTALL/lib" -maxdepth 1 -type f -name 'libLLVM*.a' -printf '%f\n' | sed 's/\.a$//' | sort)
test "${#LLVM_LIBS[@]}" -gt 20
{
  echo "project('llvm', ['cpp'])"
  echo
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
  echo
  echo "dep_llvm = declare_dependency("
  echo "  include_directories : include_directories('$LLVM_INSTALL/include'),"
  echo "  dependencies : _deps,"
  echo "  version : '19.1.7',"
  echo ")"
  echo "has_rtti = false"
  echo "irbuilder_h = files('$LLVM_INSTALL/include/llvm/IR/IRBuilder.h')"
} > "$MESA/subprojects/llvm/meson.build"

MESA_BUILD="$ROOT/mesa-build-arm64"
MESA_INSTALL="$ROOT/mesa-install-arm64"
cd "$MESA"
meson setup "$MESA_BUILD"   --cross-file "$CROSS_FILE"   --wrap-mode=nofallback   --force-fallback-for=llvm   -Dllvm:werror=false   -Dprefix="$MESA_INSTALL"   -Dlibdir=lib   -Dbuildtype=release   -Dplatforms=android   -Degl-native-platform=android   -Degl=enabled   -Dgbm=disabled   -Dglx=disabled   -Dglvnd=disabled   -Dandroid-stub=true   -Dplatform-sdk-version="$ANDROID_API"   -Dandroid-libbacktrace=disabled   -Dcpp_rtti=false   -Dvalgrind=disabled   -Dlibunwind=disabled   -Dbuild-tests=false   -Denable-glcpp-tests=false   -Dgallium-opencl=disabled   -Dgallium-rusticl=false   -Dgallium-vdpau=disabled   -Dgallium-va=disabled   -Dgallium-xa=disabled   -Dgallium-nine=false   -Dgallium-drivers=llvmpipe   -Dvulkan-drivers=[]   -Dvulkan-layers=[]   -Dvideo-codecs=[]   -Dllvm=enabled   -Dshared-llvm=disabled   "${MESA_EXTRA[@]}"
meson configure "$MESA_BUILD"
ninja -j4 -C "$MESA_BUILD"
ninja -C "$MESA_BUILD" install

OUT="$ROOT/mesa-arm64-deploy-$VARIANT"
READELF="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf"
mkdir -p "$OUT/payload" "$OUT/audit"
cp -a "$MESA_INSTALL"/. "$OUT/payload/"
mkdir -p "$OUT/payload/lib"
cp -a "$LIBDRM_INSTALL/lib"/libdrm.so* "$OUT/payload/lib/"

find "$OUT/payload" -type f \( -name '*.so' -o -name '*.so.*' \) -print0   | while IFS= read -r -d '' f; do
      echo "=== ${f#$OUT/} ==="
      "$READELF" -h "$f" | grep -E 'Class:|Machine:|Type:'
      "$READELF" -d "$f" | grep -E 'NEEDED|SONAME' || true
    done | tee "$OUT/audit/elf-audit.txt"
grep -q 'Machine:.*AArch64' "$OUT/audit/elf-audit.txt"
find "$OUT/payload" -type f -print0 | sort -z | xargs -0 sha256sum > "$OUT/audit/payload.sha256"
{
  echo 'AL Cloud Mesa optimization candidate'
  echo "Variant: $VARIANT"
  echo 'Base: Gate 1 Mesa 25.0.0 / LLVM 19.1.7'
  echo "LLVM build type: $LLVM_BUILD_TYPE"
  printf 'LLVM C flags: %s\n' "$LLVM_CMAKE_C_FLAGS"
  printf 'LLVM CXX flags: %s\n' "$LLVM_CMAKE_CXX_FLAGS"
  printf 'Mesa extra options:'; printf ' %q' "${MESA_EXTRA[@]}"; echo
  printf 'Cross C extras:'; printf ' %q' "${C_EXTRA[@]}"; echo
  printf 'Cross CXX extras:'; printf ' %q' "${CXX_EXTRA[@]}"; echo
  echo 'Runtime control required: init-level LP_NUM_THREADS=4'
  if [ "$VARIANT" = jito3 ]; then
    echo 'JIT source delta: lp_bld_init.c normal MCJIT codegen Default(O2)->Aggressive(O3)'
    printf 'Patched JIT source SHA-256: '
    sha256sum "$MESA/src/gallium/auxiliary/gallivm/lp_bld_init.c" | awk '{print $1}'
  fi
  du -sh "$OUT/payload"
} | tee "$OUT/audit/manifest.txt"

TAR="$ROOT/mesa-25.0.0-android-arm64-llvmpipe-$VARIANT.tar.xz"
tar -C "$ROOT" -cJf "$TAR" "$(basename "$OUT")"
sha256sum "$TAR" | tee "$ROOT/mesa-bundle-$VARIANT.sha256"
ls -lh "$TAR"
