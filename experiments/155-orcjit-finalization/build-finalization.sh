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
MESA_BUILD="$ROOT/mesa-build-arm64-orcjit-finalization"
MESA_INSTALL="$ROOT/mesa-install-arm64-orcjit-finalization"
CROSS_FILE="$ROOT/aarch64-linux-android.txt"
AUDIT="$ROOT/exp155-audit"
OUT="$ROOT/exp155-mesa-arm64-deploy"
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

ORC_SRC="$MESA_SRC/src/gallium/auxiliary/gallivm/lp_bld_init_orc.cpp"
python3 - "$ORC_SRC" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()

def replace_once(old, new, label):
    global s
    if old not in s:
        raise SystemExit(f'instrumentation anchor missing: {label}')
    s = s.replace(old, new, 1)

replace_once(
    '#include <cstdlib>\n',
    '#include <cstdlib>\n#include <atomic>\n#include <cstdio>\n#include <unistd.h>\nextern "C" void alcloud_finalize_trace_lpjit_exit(void *caller_pc);\n',
    'diagnostic includes')

replace_once(
    'namespace {\n',
    '''namespace {\n\nstatic std::atomic<unsigned long> alcloud_finalization_seq{0};\n\nstatic void\nalcloud_finalization_log(const char *event, const void *lpjit, const void *lljit,\n                     const void *jd, const void *extra)\n{\n   char buffer[512];\n   unsigned long seq = alcloud_finalization_seq.fetch_add(1, std::memory_order_relaxed) + 1;\n   int len = snprintf(buffer, sizeof(buffer),\n                      "ALCLOUD_ORC_FINALIZATION seq=%lu t_ns=%llu pid=%ld tid=%ld event=%s lpjit=%p lljit=%p jd=%p extra=%p\\n",\n                      seq, (unsigned long long)os_time_get_nano(),\n                      (long)getpid(), (long)gettid(), event, lpjit, lljit, jd, extra);\n   if (len > 0) {\n      size_t size = (size_t)len < sizeof(buffer) ? (size_t)len : sizeof(buffer) - 1;\n      (void)write(STDERR_FILENO, buffer, size);\n   }\n}\n''',
    'diagnostic helper')

replace_once(
    '''   static LLVMOrcJITDylibRef create_jit_dylib(const char * name) {\n      using llvm::orc::JITDylib;\n      LPJit* jit = get_instance();\n      JITDylib& tmp = ExitOnErr(jit->lljit->createJITDylib(name));\n      return wrap(&tmp);\n   }\n''',
    '''   static LLVMOrcJITDylibRef create_jit_dylib(const char * name) {\n      using llvm::orc::JITDylib;\n      LPJit* jit = get_instance();\n      alcloud_finalization_log("CREATE_JD_BEGIN", jit, jit->lljit.get(), NULL, name);\n      JITDylib& tmp = ExitOnErr(jit->lljit->createJITDylib(name));\n      alcloud_finalization_log("CREATE_JD_DONE", jit, jit->lljit.get(), &tmp, name);\n      return wrap(&tmp);\n   }\n''',
    'create_jit_dylib')

replace_once(
    '''      ThreadSafeModule tsm(\n         std::unique_ptr<Module>(llvm::unwrap(mod)), *::unwrap(ts_context));\n      ExitOnErr(get_instance()->lljit->addIRModule(\n         *::unwrap(jd), std::move(tsm)\n      ));\n''',
    '''      ThreadSafeModule tsm(\n         std::unique_ptr<Module>(llvm::unwrap(mod)), *::unwrap(ts_context));\n      LPJit* jit = get_instance();\n      alcloud_finalization_log("ADD_IR_BEGIN", jit, jit->lljit.get(), ::unwrap(jd), mod);\n      ExitOnErr(jit->lljit->addIRModule(\n         *::unwrap(jd), std::move(tsm)\n      ));\n      alcloud_finalization_log("ADD_IR_DONE", jit, jit->lljit.get(), ::unwrap(jd), mod);\n''',
    'add_ir_module_to_jd')

replace_once(
    '''      JITDylib* JD = ::unwrap(jd);\n      auto& es = LPJit::get_instance()->lljit->getExecutionSession();\n      auto name = es.intern(llvm::unwrap(sym)->getName());\n''',
    '''      JITDylib* JD = ::unwrap(jd);\n      LPJit* jit = LPJit::get_instance();\n      alcloud_finalization_log("ADD_MAPPING_BEGIN", jit, jit->lljit.get(), JD, sym);\n      auto& es = jit->lljit->getExecutionSession();\n      auto name = es.intern(llvm::unwrap(sym)->getName());\n''',
    'add_mapping begin')

replace_once(
    '''      auto munit = llvm::orc::absoluteSymbols(map);\n      llvm::cantFail(JD->define(std::move(munit)));\n   }\n''',
    '''      auto munit = llvm::orc::absoluteSymbols(map);\n      llvm::cantFail(JD->define(std::move(munit)));\n      alcloud_finalization_log("ADD_MAPPING_DONE", jit, jit->lljit.get(), JD, sym);\n   }\n''',
    'add_mapping done')

replace_once(
    '''      JITDylib* JD = ::unwrap(jd);\n      LPJit* jit = get_instance();\n      auto &ircl = jit->lljit->getIRCompileLayer();\n''',
    '''      JITDylib* JD = ::unwrap(jd);\n      LPJit* jit = get_instance();\n      alcloud_finalization_log("LOOKUP_BEGIN", jit, jit->lljit.get(), JD, func_name);\n      auto &ircl = jit->lljit->getIRCompileLayer();\n''',
    'lookup begin')

replace_once(
    '''      auto func = ExitOnErr(jit->lljit->lookup(*JD, func_name));\n      jit->lookup_mutex.unlock();\n''',
    '''      auto func = ExitOnErr(jit->lljit->lookup(*JD, func_name));\n      jit->lookup_mutex.unlock();\n      alcloud_finalization_log("LOOKUP_DONE", jit, jit->lljit.get(), JD, func_name);\n''',
    'lookup done')

replace_once(
    '''   static void remove_jd(LLVMOrcJITDylibRef jd) {\n      using llvm::orc::ExecutionSession;\n      using llvm::orc::JITDylib;\n      auto& es = LPJit::get_instance()->lljit->getExecutionSession();\n      ExitOnErr(es.removeJITDylib(* ::unwrap(jd)));\n   }\n''',
    '''   static void remove_jd(LLVMOrcJITDylibRef jd) {\n      using llvm::orc::ExecutionSession;\n      using llvm::orc::JITDylib;\n      LPJit* jit = LPJit::get_instance();\n      alcloud_finalization_log("REMOVE_JD_BEGIN", jit, jit->lljit.get(), ::unwrap(jd), NULL);\n      auto& es = jit->lljit->getExecutionSession();\n      ExitOnErr(es.removeJITDylib(* ::unwrap(jd)));\n      alcloud_finalization_log("REMOVE_JD_DONE", jit, jit->lljit.get(), ::unwrap(jd), NULL);\n   }\n''',
    'remove_jd')

replace_once(
    '   ~LPJit() = default;\n',
    '   ~LPJit();\n',
    'LPJit destructor declaration')

replace_once(
    '''   static void init_lpjit() {\n      jit = new LPJit;\n      std::atexit(lpjit_exit);\n   }\n''',
    '''   static void init_lpjit() {\n      alcloud_finalization_log("LPJIT_INIT_BEGIN", NULL, NULL, NULL, NULL);\n      jit = new LPJit;\n      alcloud_finalization_log("LPJIT_INIT_READY", jit, jit->lljit.get(), NULL, NULL);\n      std::atexit(lpjit_exit);\n      alcloud_finalization_log("LPJIT_ATEXIT_REGISTERED", jit, jit->lljit.get(), NULL, NULL);\n   }\n''',
    'init_lpjit')

replace_once(
    '''LPJit* LPJit::jit = NULL;\n\nvoid lpjit_exit()\n{\n   delete LPJit::jit;\n}\n''',
    '''LPJit* LPJit::jit = NULL;\n\nLPJit::~LPJit()\n{\n   alcloud_finalization_log("LPJIT_DTOR_BODY", this, lljit.get(), NULL, NULL);\n}\n\nvoid lpjit_exit()\n{\n   LPJit *jit = LPJit::jit;\n   void *lljit = jit->lljit.get();\n   alcloud_finalize_trace_lpjit_exit(__builtin_return_address(0));\n   alcloud_finalization_log("LPJIT_EXIT_BEGIN", jit, lljit, NULL, NULL);\n   delete jit;\n   alcloud_finalization_log("LPJIT_EXIT_AFTER_DELETE", jit, lljit, NULL, NULL);\n}\n''',
    'lpjit_exit and destructor')

replace_once(
    '''LPJit::LPJit() :jit_dylib_count(0) {\n   using namespace llvm::orc;\n\n   lp_init_env_options();\n''',
    '''LPJit::LPJit() :jit_dylib_count(0) {\n   using namespace llvm::orc;\n\n   alcloud_finalization_log("LPJIT_CTOR_BEGIN", this, lljit.get(), NULL, NULL);\n   lp_init_env_options();\n''',
    'LPJit constructor begin')

replace_once(
    '''      .create());\n\n   LLVMOrcIRTransformLayerRef TL = wrap(&lljit->getIRTransformLayer());\n''',
    '''      .create());\n\n   alcloud_finalization_log("LLJIT_CREATED", this, lljit.get(), NULL, NULL);\n   LLVMOrcIRTransformLayerRef TL = wrap(&lljit->getIRTransformLayer());\n''',
    'LLJIT created')

p.write_text(s)
PY

TRACE_SRC="$MESA_SRC/src/gallium/targets/dri/alcloud_finalize_trace.cpp"
cat > "$TRACE_SRC" <<'CPP'
#include <android/log.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <unwind.h>

extern "C" void *__dso_handle;
extern "C" void __real___cxa_finalize(void *);

namespace {

static thread_local unsigned alcloud_finalize_depth = 0;

struct AlcloudStack {
   uintptr_t pcs[24];
   unsigned count;
};

static _Unwind_Reason_Code
alcloud_unwind_cb(struct _Unwind_Context *ctx, void *opaque)
{
   AlcloudStack *stack = static_cast<AlcloudStack *>(opaque);
   if (stack->count >= 24)
      return _URC_END_OF_STACK;
   uintptr_t pc = static_cast<uintptr_t>(_Unwind_GetIP(ctx));
   if (pc)
      stack->pcs[stack->count++] = pc;
   return _URC_NO_REASON;
}

static unsigned long long
alcloud_now_ns()
{
   struct timespec ts = {};
   clock_gettime(CLOCK_MONOTONIC, &ts);
   return static_cast<unsigned long long>(ts.tv_sec) * 1000000000ULL +
          static_cast<unsigned long long>(ts.tv_nsec);
}

static void
alcloud_log(const char *event, const void *arg, const void *caller)
{
   char buffer[512];
   int len = snprintf(buffer, sizeof(buffer),
      "ALCLOUD_FINALIZE t_ns=%llu pid=%ld tid=%ld event=%s arg=%p dso=%p match=%u depth=%u caller=%p",
      alcloud_now_ns(), (long)getpid(), (long)gettid(), event, arg,
      (void *)&__dso_handle, arg == (void *)&__dso_handle ? 1U : 0U,
      alcloud_finalize_depth, caller);
   if (len > 0)
      (void)__android_log_write(ANDROID_LOG_INFO, "ALCLOUD_FINALIZE", buffer);
}

static void
alcloud_log_stack(const char *event)
{
   AlcloudStack stack = {};
   (void)_Unwind_Backtrace(alcloud_unwind_cb, &stack);
   for (unsigned i = 0; i < stack.count; ++i) {
      char buffer[256];
      int len = snprintf(buffer, sizeof(buffer),
         "ALCLOUD_FINALIZE t_ns=%llu pid=%ld tid=%ld event=%s frame=%u pc=%p depth=%u",
         alcloud_now_ns(), (long)getpid(), (long)gettid(), event, i,
         (void *)stack.pcs[i], alcloud_finalize_depth);
      if (len > 0)
         (void)__android_log_write(ANDROID_LOG_INFO, "ALCLOUD_FINALIZE", buffer);
   }
}

} // namespace

extern "C" __attribute__((visibility("default"), noinline))
void __wrap___cxa_finalize(void *arg)
{
   void *caller = __builtin_return_address(0);
   ++alcloud_finalize_depth;
   alcloud_log("FINALIZE_WRAP_BEGIN", arg, caller);
   alcloud_log_stack("FINALIZE_WRAP_STACK");
   __real___cxa_finalize(arg);
   alcloud_log("FINALIZE_WRAP_AFTER_REAL", arg, caller);
   --alcloud_finalize_depth;
}

extern "C" __attribute__((visibility("hidden"), noinline))
void alcloud_finalize_trace_lpjit_exit(void *caller_pc)
{
   alcloud_log(alcloud_finalize_depth ? "LPJIT_EXIT_CONTEXT_DSO" :
                                      "LPJIT_EXIT_CONTEXT_PROCESS_OR_OTHER",
               nullptr, caller_pc);
   alcloud_log_stack("LPJIT_EXIT_STACK");
}
CPP

DRI_MESON="$MESA_SRC/src/gallium/targets/dri/meson.build"
python3 - "$DRI_MESON" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()

def replace_once(old, new, label):
    global s
    if s.count(old) != 1:
        raise SystemExit(f'{label} anchor count: {s.count(old)}')
    s = s.replace(old, new, 1)

replace_once(
    "gallium_dri_ld_args = [cc.get_supported_link_arguments('-Wl,--default-symver')]\n",
    "gallium_dri_ld_args = [cc.get_supported_link_arguments('-Wl,--default-symver')]\n"
    "gallium_dri_ld_args += ['-Wl,--wrap=__cxa_finalize']\n",
    'target-local finalize wrapper link arg')
replace_once(
    "  files('dri_target.c'),\n",
    "  files('dri_target.c', 'alcloud_finalize_trace.cpp'),\n",
    'target-local tracer source')
replace_once(
    "  link_args : [ld_args_build_id, ld_args_gc_sections, gallium_dri_ld_args],\n",
    "  cpp_args : ['-funwind-tables', '-fasynchronous-unwind-tables', '-fno-omit-frame-pointer'],\n"
    "  link_args : [ld_args_build_id, ld_args_gc_sections, gallium_dri_ld_args],\n",
    'target-local unwind flags')
p.write_text(s)
PY

grep -n 'alcloud_finalize_trace\|wrap=__cxa_finalize\|funwind-tables' "$DRI_MESON" \
  | tee "$AUDIT/finalization-meson-proof.txt"
cp "$TRACE_SRC" "$AUDIT/alcloud_finalize_trace.cpp"
cp "$DRI_MESON" "$AUDIT/instrumented-dri-meson.build"

grep -n 'ALCLOUD_ORC_FINALIZATION\|LPJIT_EXIT_BEGIN\|ADD_MAPPING_BEGIN' "$ORC_SRC" \
  | tee "$AUDIT/instrumentation-source-proof.txt"
cp "$ORC_SRC" "$AUDIT/instrumented-lp_bld_init_orc.cpp"

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
OBJDUMP="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objdump"
STRINGS="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strings"
"$READELF" -h "$GALLIUM_SO" | tee "$AUDIT/libgallium-elf-header.txt"
grep -q 'Machine:.*AArch64' "$AUDIT/libgallium-elf-header.txt"
"$NM" -C "$GALLIUM_SO" > "$AUDIT/libgallium-symbols.txt" || true
grep -E 'LPJit|llvm::orc::LLJIT|llvm::MCJIT|GDBJITRegistrationListener' "$AUDIT/libgallium-symbols.txt" \
  > "$AUDIT/jit-symbol-summary.txt" || true
"$STRINGS" "$GALLIUM_SO" | grep 'ALCLOUD_ORC_FINALIZATION' | tee "$AUDIT/instrumentation-binary-proof.txt"
"$NM" -C "$GALLIUM_SO" | grep -E '__wrap___cxa_finalize|alcloud_finalize_trace_lpjit_exit' \
  | tee "$AUDIT/finalization-symbol-proof.txt"
grep -q '__wrap___cxa_finalize' "$AUDIT/finalization-symbol-proof.txt"
grep -q 'alcloud_finalize_trace_lpjit_exit' "$AUDIT/finalization-symbol-proof.txt"
"$STRINGS" "$GALLIUM_SO" | grep 'ALCLOUD_FINALIZE' \
  | tee "$AUDIT/finalization-marker-proof.txt"
"$OBJDUMP" -d "$GALLIUM_SO" | grep -A12 -B4 '__wrap___cxa_finalize' \
  > "$AUDIT/finalization-wrapper-disasm.txt" || true


SYM_HEX="$("$NM" "$GALLIUM_SO" | awk '$3=="gallivm_add_global_mapping" && !found {print $1; found=1}')"
test -n "$SYM_HEX"
START=$((16#$SYM_HEX))
STOP=$((START + 128))
"$OBJDUMP" -d --start-address="$START" --stop-address="$STOP" "$GALLIUM_SO" \
  > "$AUDIT/gallivm-add-global-mapping-disasm.txt"

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
  echo 'AL Cloud Experiment 155 ORCJIT finalization diagnostic bundle'
  echo 'Mesa: 25.0.0'
  echo 'LLVM: 19.1.7'
  echo 'LLVM RTTI: enabled'
  echo 'LLVM Intel JIT events: disabled'
  echo 'JIT backend: ORCJIT / LLJIT'
  echo 'Instrumentation: LPJit/LLJIT markers plus target-local __cxa_finalize path tracing; no behavior fix'
  echo 'libdrm build dependency: 2.4.122'
  echo 'NDK: r27d 27.3.13750724'
  echo 'Android API: 34'
  echo 'ABI: arm64-v8a'
  echo 'Gallium driver: llvmpipe'
  echo 'Vulkan drivers: none'
  echo 'Platform: android'
  echo 'EGL: enabled'
  echo 'Runtime no-KMS mode: MESA_ANDROID_NO_KMS_SWRAST=1'
  du -sh "$OUT/payload"
} | tee "$OUT/audit/manifest.txt"

BUNDLE="$ROOT/exp155-mesa-25.0.0-android-arm64-llvmpipe-orcjit-finalization.tar.xz"
tar -C "$ROOT" -cJf "$BUNDLE" "$(basename "$OUT")"
sha256sum "$BUNDLE" | tee "$ROOT/exp155-mesa-bundle.sha256"
ls -lh "$BUNDLE"
