#!/usr/bin/env bash
set -euo pipefail

readonly MESA_COMMIT='60a06a90cb77414b3276edddbd5f8bb5fafd684c'
readonly LLVM_VERSION='19.1.7'
readonly LIBDRM_VERSION='2.4.122'
readonly ANDROID_API='34'
readonly NDK_RELEASE='r27d'
readonly TMP="${RUNNER_TEMP}/exp154"
readonly NDK="${TMP}/android-ndk-${NDK_RELEASE}"
readonly LLVM_INSTALL="${TMP}/llvm-install-arm64"
readonly DRM_INSTALL="${TMP}/libdrm-install-arm64"
readonly MESA_INSTALL="${TMP}/mesa-install-arm64"
readonly OUT="${GITHUB_WORKSPACE}/exp154-mesa-fixprobe"

rm -rf "$TMP" "$OUT" "${OUT}.tar.xz"
mkdir -p "$TMP" "$OUT/payload/lib" "$OUT/audit"

sudo apt-get update -qq
sudo apt-get install -y -qq ninja-build cmake curl xz-utils unzip pkg-config python3-venv bison flex > /dev/null
python3 -m venv "$TMP/venv"
"$TMP/venv/bin/pip" -q install 'meson==1.7.0' mako pyyaml packaging
export PATH="$TMP/venv/bin:$PATH"

echo '== Android NDK r27d =='
curl -LfsS "https://dl.google.com/android/repository/android-ndk-${NDK_RELEASE}-linux.zip" -o "$TMP/ndk.zip"
unzip -q "$TMP/ndk.zip" -d "$TMP"

echo '== LLVM 19.1.7 source =='
curl -LfsS "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz" -o "$TMP/llvm.tar.xz"
tar -xJf "$TMP/llvm.tar.xz" -C "$TMP"
readonly LLVM_SRC="$TMP/llvm-project-${LLVM_VERSION}.src"

echo '== native llvm-tblgen =='
cmake -G Ninja -S "$LLVM_SRC/llvm" -B "$TMP/llvm-host" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_TARGETS_TO_BUILD=AArch64 \
  -DLLVM_ENABLE_PROJECTS='' \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_DOCS=OFF \
  -DLLVM_ENABLE_RTTI=ON \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_CURL=OFF \
  -DLLVM_ENABLE_LIBPFM=OFF
ninja -C "$TMP/llvm-host" llvm-tblgen

echo '== target LLVM 19.1.7 for Android arm64 =='
cmake -G Ninja -S "$LLVM_SRC/llvm" -B "$TMP/llvm-target" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM="android-${ANDROID_API}" \
  -DANDROID_NDK="$NDK" \
  -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
  -DCMAKE_ANDROID_NDK="$NDK" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=Android \
  -DCMAKE_SYSTEM_VERSION="$ANDROID_API" \
  -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL" \
  -DLLVM_TABLEGEN="$TMP/llvm-host/bin/llvm-tblgen" \
  -DLLVM_TARGET_ARCH=AArch64 \
  -DLLVM_HOST_TRIPLE="aarch64-linux-android${ANDROID_API}" \
  -DLLVM_DEFAULT_TARGET_TRIPLE="aarch64-linux-android${ANDROID_API}" \
  -DLLVM_TARGETS_TO_BUILD=AArch64 \
  -DLLVM_BUILD_LLVM_DYLIB=OFF \
  -DLLVM_LINK_LLVM_DYLIB=OFF \
  -DLLVM_BUILD_TESTS=OFF \
  -DLLVM_BUILD_EXAMPLES=OFF \
  -DLLVM_BUILD_DOCS=OFF \
  -DLLVM_BUILD_TOOLS=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_ENABLE_RTTI=ON \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_ZSTD=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_CURL=OFF \
  -DLLVM_ENABLE_LIBPFM=OFF \
  -DLLVM_USE_INTEL_JITEVENTS=OFF \
  -DLLVM_USE_OPROFILE=OFF \
  -DLLVM_USE_PERF=OFF \
  -DLLVM_ENABLE_PIC=ON
ninja -C "$TMP/llvm-target" install

cat > "$TMP/android-aarch64.ini" <<EOF
[constants]
ndk_path = '${NDK}'
[binaries]
ar = ndk_path / 'toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar'
c = [ndk_path / 'toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang']
cpp = [ndk_path / 'toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang++', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '--start-no-unused-arguments', '-static-libstdc++', '--end-no-unused-arguments']
c_ld = 'lld'
cpp_ld = 'lld'
strip = ndk_path / 'toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip'
pkgconfig = 'pkg-config'
[properties]
needs_exe_wrapper = true
[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF

echo '== libdrm 2.4.122 =='
curl -LfsS "https://dri.freedesktop.org/libdrm/libdrm-${LIBDRM_VERSION}.tar.xz" -o "$TMP/libdrm.tar.xz"
tar -xJf "$TMP/libdrm.tar.xz" -C "$TMP"
meson setup "$TMP/libdrm-build" "$TMP/libdrm-${LIBDRM_VERSION}" \
  --cross-file "$TMP/android-aarch64.ini" \
  --prefix "$DRM_INSTALL" --buildtype release \
  -Dtests=false -Dinstall-test-programs=false \
  -Dintel=disabled -Dradeon=disabled -Damdgpu=disabled -Dnouveau=disabled \
  -Dvmwgfx=disabled -Domap=disabled -Dexynos=disabled -Dfreedreno=disabled \
  -Dtegra=disabled -Dvc4=disabled -Detnaviv=disabled \
  -Dcairo-tests=disabled -Dman-pages=disabled -Dvalgrind=disabled
ninja -C "$TMP/libdrm-build"
meson install -C "$TMP/libdrm-build"

echo '== Mesa fix-present source =='
mkdir "$TMP/mesa"
git -C "$TMP/mesa" init -q
git -C "$TMP/mesa" remote add origin https://gitlab.freedesktop.org/mesa/mesa.git
git -C "$TMP/mesa" fetch -q --depth 1 origin "$MESA_COMMIT"
git -C "$TMP/mesa" checkout -q FETCH_HEAD
test "$(git -C "$TMP/mesa" rev-parse HEAD)" = "$MESA_COMMIT"

# Mesa's documented Android llvmpipe path uses a Meson LLVM fallback wrapper.
# Generate it from exactly the target static LLVM archive inventory we built.
mkdir -p "$TMP/mesa/subprojects/llvm"
python3 - "$LLVM_INSTALL" "$TMP/mesa/subprojects/llvm/meson.build" <<'PY'
from pathlib import Path
import sys
prefix = Path(sys.argv[1])
out = Path(sys.argv[2])
libs = sorted(p.stem for p in (prefix / 'lib').glob('libLLVM*.a'))
if not libs:
    raise SystemExit('no target LLVM static archives found')
lines = [
    "project('llvm', ['cpp'])",
    "cpp = meson.get_compiler('cpp')",
    "_deps = []",
    f"_search = '{prefix / 'lib'}'",
]
for lib in libs:
    lines.append(f"_deps += cpp.find_library('{lib}', dirs : _search)")
lines += [
    "dep_llvm = declare_dependency(",
    f"  include_directories : include_directories('{prefix / 'include'}'),",
    "  dependencies : _deps,",
    "  version : '19.1.7',",
    ")",
    "has_rtti = true",
    f"irbuilder_h = files('{prefix / 'include' / 'llvm/IR/IRBuilder.h'}')",
]
out.write_text('\n'.join(lines) + '\n')
print(f'wrapped {len(libs)} LLVM static archives')
PY

export PKG_CONFIG_LIBDIR="$DRM_INSTALL/lib/pkgconfig:$DRM_INSTALL/lib64/pkgconfig"
export PKG_CONFIG_PATH=''
meson setup "$TMP/mesa-build" "$TMP/mesa" \
  --cross-file "$TMP/android-aarch64.ini" \
  --prefix "$MESA_INSTALL" --buildtype release \
  --force-fallback-for=llvm \
  -Dplatforms=android -Dplatform-sdk-version="$ANDROID_API" \
  -Dandroid-stub=true -Dandroid-libbacktrace=disabled \
  -Degl=enabled -Dgbm=disabled -Dglx=disabled -Dglvnd=disabled \
  -Dgallium-drivers=llvmpipe -Dvulkan-drivers= \
  -Dllvm=enabled -Dllvm-orcjit=true -Dshared-llvm=disabled -Ddraw-use-llvm=true \
  -Dlibunwind=disabled -Dvideo-codecs= -Dosmesa=false
ninja -C "$TMP/mesa-build"
meson install -C "$TMP/mesa-build"

copy_one() {
  local name="$1" root="$2" found
  found="$(find "$root" -type f -name "$name" -print -quit)"
  test -n "$found" || { echo "missing $name under $root" >&2; exit 1; }
  cp -a "$found" "$OUT/payload/lib/$name"
}
copy_one libEGL.so "$MESA_INSTALL"
copy_one libGLESv1_CM.so "$MESA_INSTALL"
copy_one libGLESv2.so "$MESA_INSTALL"
copy_one libgallium_dri.so "$MESA_INSTALL"
copy_one libdrm.so "$DRM_INSTALL"

cat > "$OUT/audit/manifest.txt" <<EOF
AL Cloud Experiment 154A fix-present qualification bundle
Purpose: determine whether upstream llvmpipe concurrency/lifetime fix moves the Experiment 153 crash boundary
Mesa source commit: ${MESA_COMMIT}
Mesa baseline comparison: 25.0.0 / 4fa244fddfebb21378042556862e197284ef65ac
LLVM: ${LLVM_VERSION}
LLVM RTTI: enabled
LLVM Intel JIT events: disabled
JIT backend: ORCJIT / LLJIT
libdrm: ${LIBDRM_VERSION}
NDK: ${NDK_RELEASE} 27.3.13750724
Android API: ${ANDROID_API}
ABI: arm64-v8a
Gallium driver: llvmpipe
Platform: android
EGL: enabled
Runtime no-KMS mode expected: MESA_ANDROID_NO_KMS_SWRAST=1
This is a fix-present probe, not the final Mesa-25.0.0 backport.
EOF
meson configure "$TMP/mesa-build" > "$OUT/audit/mesa-configure.txt"
find "$LLVM_INSTALL/lib" -maxdepth 1 -name 'libLLVM*.a' -printf '%f\n' | sort > "$OUT/audit/llvm-static-archives.txt"
readelf -h "$OUT/payload/lib/libgallium_dri.so" > "$OUT/audit/libgallium-elf-header.txt"
readelf -n "$OUT/payload/lib/libgallium_dri.so" > "$OUT/audit/libgallium-notes.txt" || true
nm -C "$OUT/payload/lib/libgallium_dri.so" | grep -E 'gallivm_add_global_mapping|gallivm_destroy|LLJIT|GDBJITRegistrationListener' > "$OUT/audit/jit-symbol-summary.txt" || true
(cd "$OUT" && find payload -type f -print0 | sort -z | xargs -0 sha256sum) > "$OUT/audit/payload.sha256"
sha256sum "$OUT/audit/manifest.txt" > "$OUT/audit/manifest.sha256"

echo '== built payload =='
ls -lh "$OUT/payload/lib"
cat "$OUT/audit/manifest.txt"
XZ_OPT='-T0 -6' tar -cJf "${OUT}.tar.xz" -C "$GITHUB_WORKSPACE" "$(basename "$OUT")"
sha256sum "${OUT}.tar.xz" | tee "${OUT}.tar.xz.sha256"
ls -lh "${OUT}.tar.xz"
