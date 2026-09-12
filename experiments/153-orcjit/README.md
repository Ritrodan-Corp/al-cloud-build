# Experiment 153: Mesa ORCJIT backend isolation

## Status

Experiment 152 remains closed. This is a separate, bounded experiment derived from its Gate 2 and Gate 3 evidence.

## Question

Can Mesa 25.0.0 llvmpipe retain the Android presentation path that passed Gate 2 while replacing the MCJIT path that failed during the first Azur Lane cold launch?

## Hypothesis

The previous failure is tied to LLVM MCJIT's automatically registered GDB JIT listener or its lifetime, rather than to ReDroid buffer presentation or llvmpipe rasterization itself. Mesa 25.0.0 supports an upstream ORCJIT implementation through `-Dllvm-orcjit=true`. On AArch64 that option changes Gallivm from `lp_bld_init.c` to `lp_bld_init_orc.cpp` and uses LLVM LLJIT rather than MCJIT.

This experiment tests that distinction only. It does not claim that all LLVM JIT lifetime issues disappear under ORCJIT.

## Required build delta

The candidate retains Mesa 25.0.0, LLVM 19.1.7, Android API 34, NDK r27d, libdrm 2.4.122, llvmpipe, Android EGL, ReDroid gralloc/composer, and the no-KMS software path.

The only intentional compiler/backend changes are:

- Mesa: `-Dllvm-orcjit=true`.
- LLVM: RTTI enabled.
- Mesa C++: RTTI enabled to match LLVM and permit the ORCJIT source's `dynamic_cast` use.
- LLVM Intel JIT events explicitly disabled.

RTTI is a required build/ABI compatibility delta for the upstream ORCJIT implementation, not a second runtime hypothesis.

## Known ORCJIT risk

LLVM 19.1.7 LLJIT defaults to `RTDyldObjectLinkingLayer` with `SectionMemoryManager` when Mesa does not supply a custom object layer. LLVM has a documented AArch64 relocation-range problem in that path on some large-address-space processes when allocation reservation is not used. Experiment 153 intentionally does not patch in JITLink or a custom memory manager because doing so would mix another material change into the first ORCJIT test.

If the candidate reaches a relocation-range or SectionMemoryManager failure, stop and record it. A JITLink or reserved-allocation variant would require a separate experiment.

## Build acceptance gates

The build must satisfy all of the following before any runtime test:

1. LLVM 19.1.7 installs the ORC dependency set, including `libLLVMOrcJIT.a`, `libLLVMOrcShared.a`, `libLLVMOrcTargetProcess.a`, `libLLVMExecutionEngine.a`, `libLLVMRuntimeDyld.a`, and `libLLVMJITLink.a`.
2. Mesa configure reports `llvm-orcjit=true` and matching LLVM/Mesa RTTI.
3. Ninja commands compile `gallivm/lp_bld_init_orc.cpp`.
4. Ninja commands do not compile `gallivm/lp_bld_init.c` as the Gallivm JIT implementation.
5. The resulting deployment libraries are AArch64 ELF objects and the bundle includes the same EGL/GLES/llvmpipe payload shape used by the Gate 2 candidate.
6. Build and symbol audit output is packaged with the candidate artifact.

A build failure permits at most one evidence-driven correction if the failure is an upstream ORCJIT build/link requirement. Do not broaden into LLVM source redesign.

## Runtime procedure

Use a new disposable Experiment 153 container/data directory. Do not overwrite the Experiment 152/Gate 2 candidate or persistent Android data.

First regress the proven presentation path: verify candidate process maps, run the existing GLES probe, require shader compilation, texture sampling, blending and repeated swaps, perform the 1280x720 -> 1024x576 -> 1280x720 resize cycle, and run a short soak of approximately 10 minutes with no GL errors.

Only after that regression passes, perform one official Azur Lane cold launch.

## Runtime interpretation

A strong success is a stable title/login screen with real frames.

A useful partial result is a new failure that no longer contains `GDBJITRegistrationListener::notifyObjectLoaded` or `llvm::MCJIT`. That would show the backend change took effect while identifying the next blocker.

The same MCJIT/GDB-listener stack is a validation failure: either the candidate did not actually use ORCJIT or the deployed library was not the audited candidate.

If ORCJIT produces a new lifetime, relocation, or memory-manager crash, stop and analyze before creating another candidate.

## Explicit exclusions

This experiment does not modify Azur Lane, replace ReDroid gralloc/composer, redesign Android allocation, tune performance, change the permanent Gate 2 configuration, test the 2 OCPU / 12 GB deployment envelope, patch LLVM's mutex checks, disable generic safety assertions, or unregister the MCJIT GDB listener.

The MCJIT listener-unregistration idea remains a separate possible follow-up only if Experiment 153 produces evidence that justifies it.
