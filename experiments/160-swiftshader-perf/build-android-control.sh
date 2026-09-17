#!/usr/bin/env bash
set -euxo pipefail

ROOT="${RUNNER_TEMP:?}"
SRC="$ROOT/swiftshader-r21"
BUILD="$ROOT/swiftshader-build-control"
NDK="$ROOT/android-ndk-r27d"
COMMIT=32ad39a320606948f09692cb91b71e1cd95d0e51
API=34
OUT="$GITHUB_WORKSPACE/experiments/160-swiftshader-perf/out-control"

rm -rf "$SRC" "$BUILD" "$OUT"
mkdir -p "$OUT"

git clone --filter=blob:none --no-checkout https://android.googlesource.com/platform/external/swiftshader "$SRC"
git -C "$SRC" fetch --depth=1 origin "$COMMIT"
git -C "$SRC" checkout --detach FETCH_HEAD
git -C "$SRC" submodule sync --recursive
git -C "$SRC" submodule update --init --recursive --depth=1

grep -n 'REACTOR_DEFAULT_OPT_LEVEL' "$SRC/CMakeLists.txt" | tee "$OUT/reactor-option.txt"
grep -n 'SWIFTSHADER_LLVM_VERSION' "$SRC/CMakeLists.txt" | head -20 | tee "$OUT/llvm-version-option.txt"

cd "$ROOT"
curl -fL --retry 3 --retry-delay 2 -o android-ndk-r27d-linux.zip https://dl.google.com/android/repository/android-ndk-r27d-linux.zip
echo '22105e410cf29afcf163760cc95522b9fb981121  android-ndk-r27d-linux.zip' | sha1sum -c -
unzip -q android-ndk-r27d-linux.zip

cmake -GNinja -S "$SRC" -B "$BUILD" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM="android-${API}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DREACTOR_BACKEND=LLVM \
  -DSWIFTSHADER_BUILD_TESTS=OFF \
  -DSWIFTSHADER_BUILD_BENCHMARKS=OFF \
  -DSWIFTSHADER_BUILD_PVR=OFF \
  -DSWIFTSHADER_BUILD_CPPDAP=OFF \
  2>&1 | tee "$OUT/cmake-configure.log"

cmake --build "$BUILD" --target vk_swiftshader --parallel 2 2>&1 | tee "$OUT/build.log"

LIB=$(find "$BUILD" -type f -name 'libvk_swiftshader.so' -print -quit)
[ -n "$LIB" ] && [ -f "$LIB" ]
cp "$LIB" "$OUT/libvk_swiftshader-control.so"
sha256sum "$OUT/libvk_swiftshader-control.so" | tee "$OUT/sha256.txt"
file "$OUT/libvk_swiftshader-control.so" | tee "$OUT/file.txt"
"$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf" -h -d "$OUT/libvk_swiftshader-control.so" > "$OUT/readelf.txt"
"$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm" -D --defined-only "$OUT/libvk_swiftshader-control.so" > "$OUT/dynsym.txt"
git -C "$SRC" rev-parse HEAD > "$OUT/source-commit.txt"
