# Experiment 155: finalization-path diagnostic

## Purpose

Experiment 154 closed the immediate failure mechanism to LPJit/LLJIT state being finalized while UnityGfxDeviceW still had live renderer work. Android Bionic and exact-binary review showed that the DSO-local atexit registration can run during either whole-process finalization or DSO-specific unload. Experiment 155 distinguishes those paths before any ownership or lifetime fix.

## Fixed variables

- Mesa 25.0.0 and LLVM 19.1.7
- ORCJIT/LLJIT and llvmpipe
- Android API 34, NDK r27d, arm64-v8a
- ReDroid Android 14 and the existing direct-Mesa integration
- Official unmodified Azur Lane client and the established disposable-state launch procedure
- Experiment 154 commit 80b6e935704bd471a73a1b58a903c46ab288a782 as the implementation baseline

## Only experimental change

Retain all Experiment 154 lifetime markers and add a libgallium-only link wrapper for `__cxa_finalize`. The wrapper logs its argument, the library DSO-handle address, an exact-match bit, nesting depth, raw caller PC, and raw unwind PCs before forwarding exactly once to the real function. `lpjit_exit` records whether it runs inside that target-local wrapper and captures raw PCs. Symbols are resolved offline against the exact candidate ELF and maps.

The tracer must not suppress or defer finalization, change LPJit ownership, add null guards, serialize renderer work, modify generated code, or alter Azur Lane/Unity binaries.

## Decision rule

- `FINALIZE_WRAP_BEGIN` with `arg == &__dso_handle`, followed on the same PID/TID by `LPJIT_EXIT_CONTEXT_DSO`, is decisive evidence for DSO-specific unload/finalization.
- `LPJIT_EXIT_CONTEXT_PROCESS_OR_OTHER` is not alone sufficient for process-wide classification; use the captured raw stack, lifecycle evidence, and exact maps to establish the caller.
- A wrapper argument that is non-null but does not match the expected DSO handle fails the instrumentation gate.
- Missing or ambiguous evidence closes the run as inconclusive and permits only a tracing refinement.

## Runtime gate

Audit the exact build, target-local wrapper linkage, marker strings, AArch64 ELF, Build ID, symbols, and payload hashes. Then pass the existing renderer identity, cold-start, resize/reset, screenshot, PID-stability, and full presentation soak gate. Only afterward perform one bounded Azur Lane launch on a fresh non-hardlinked disposable clone. Stop immediately after the first finalization-path marker, preserve evidence, restore the reference service, and stop the VM promptly.
