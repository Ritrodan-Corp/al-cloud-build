# Experiment 153 source research

This note records the source-level basis for the ORCJIT experiment. It is evidence for the experiment design, not evidence that the candidate will run Azur Lane.

## Mesa 25.0.0 backend selection

Mesa 25.0.0 defines the `llvm-orcjit` Meson option as a boolean with default `false`. On architectures where MCJIT is supported, including AArch64, enabling the option sets the Gallivm ORCJIT path explicitly.

In Mesa 25.0.0 `meson.build`, `llvm_with_orcjit` becomes true when `llvm-orcjit` is enabled and `GALLIVM_USE_ORCJIT` is emitted as a compile definition.

In `src/gallium/auxiliary/meson.build`, Gallivm selects exactly one JIT implementation:

- ORCJIT: `gallivm/lp_bld_init_orc.cpp`
- default MCJIT: `gallivm/lp_bld_init.c`

This gives the build an auditable discriminator before runtime.

## Mesa ORCJIT implementation

Mesa 25.0.0 `lp_bld_init_orc.cpp` creates an LLVM `LLJIT` through `LLJITBuilder` and uses per-JITDylib module management. It does not instantiate `llvm::MCJIT`.

Mesa only calls `RegisterJITEventListener(createIntelJITEventListener())` in this path when `LLVM_USE_INTEL_JITEVENTS` is enabled. Experiment 153 sets that LLVM option to OFF.

The ORCJIT source uses a C++ `dynamic_cast` to reach `llvm::orc::SimpleCompiler` when installing the Mesa object cache. Therefore the candidate must use RTTI-capable C++ code.

Mesa's top-level Meson logic independently enforces that Mesa and LLVM use matching RTTI modes because a mismatch changes the C++ ABI. For this candidate LLVM is built with `LLVM_ENABLE_RTTI=ON`, the Meson fallback reports `has_rtti=true`, and Mesa uses `cpp_rtti=true`.

## MCJIT failure-path distinction

LLVM 19.1.7 `lib/ExecutionEngine/MCJIT/MCJIT.cpp` unconditionally calls:

`RegisterJITEventListener(JITEventListener::createGDBRegistrationListener());`

inside the MCJIT constructor.

The same file exposes `UnregisterJITEventListener`, but Experiment 153 does not use it. Listener removal would preserve MCJIT and therefore tests a different hypothesis.

LLVM 19.1.7 `GDBRegistrationListener.cpp` implements the listener as a function-static singleton containing a `sys::Mutex` and a registered-object map. Its destructor locks that mutex while deregistering objects. This is consistent with treating the previous destroyed-mutex abort as a lifetime-sensitive path, while not proving which object or teardown event first invalidated that lifetime.

## AArch64 ORCJIT limitation retained in candidate 1

Mesa 25.0.0 defines `USE_JITLINK` only for RISC-V, LoongArch, and Windows with sufficiently new LLVM. AArch64 therefore takes Mesa's RuntimeDyld-backed LLJIT path.

LLVM 19.1.7 LLJIT defaults to `RTDyldObjectLinkingLayer` with a new `SectionMemoryManager` for each object when the client does not provide a custom object-linking layer.

LLVM issue #174305 documents that pre-LLVM-22 AArch64 users can hit relocation-range failures with the default `SectionMemoryManager` behavior on large-address-space processes. The issue recommends reserved allocation or migration to JITLink as remedies. Mesa 25.0.0's AArch64 ORCJIT path does neither by default.

Experiment 153 intentionally preserves this upstream-clean behavior. If runtime reaches a relocation/SectionMemoryManager failure, that is a new result and the experiment stops. A JITLink or reserved-allocation change would become a separately bounded follow-up.

## Cross-compile target identity

Mesa's ORCJIT source warns that `llvm::sys::getProcessTriple()` reflects the host LLVM was compiled for and can be wrong in a cross build. The AL Cloud LLVM build already sets `LLVM_HOST_TRIPLE=aarch64-linux-android34`, so the runtime LLJIT target builder should receive the Android AArch64 triple rather than the x86 GitHub runner triple.

## Static LLVM dependencies

LLVM 19.1.7 `LLVMOrcJIT` links Core, ExecutionEngine, JITLink, Object, OrcShared, OrcTargetProcess, MC, Passes, RuntimeDyld, Support, Target, TargetParser, TransformUtils and related private libraries.

The existing AL Cloud Mesa build supplies all installed `libLLVM*.a` archives through an internal Meson dependency. Experiment 153 retains that strategy but fails early unless the key ORC archives are present.

## Source pins

- Mesa: `mesa-25.0.0`
- LLVM: `llvmorg-19.1.7`
- Android NDK: r27d / 27.3.13750724
- Android API: 34
- libdrm: 2.4.122

Relevant upstream paths:

- Mesa `meson_options.txt`
- Mesa `meson.build`
- Mesa `src/gallium/auxiliary/meson.build`
- Mesa `src/gallium/auxiliary/gallivm/lp_bld_init_orc.cpp`
- LLVM `llvm/lib/ExecutionEngine/MCJIT/MCJIT.cpp`
- LLVM `llvm/lib/ExecutionEngine/GDBRegistrationListener.cpp`
- LLVM `llvm/lib/ExecutionEngine/Orc/LLJIT.cpp`
- LLVM `llvm/lib/ExecutionEngine/Orc/CMakeLists.txt`
- LLVM issue `llvm/llvm-project#174305`
