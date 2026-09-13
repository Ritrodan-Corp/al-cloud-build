# Experiment 154: ORCJIT lifetime-order diagnostic

## Purpose

Experiment 153 proved that switching Gallivm from MCJIT to Mesa 25.0.0's ORCJIT/LLJIT path removes the prior `GDBJITRegistrationListener -> MCJIT` crash signature, but Azur Lane still enters a startup restart loop. The first complete Experiment 153 failure is a `UnityGfxDeviceW` SIGSEGV/null-pointer crash at `gallivm_add_global_mapping+72` in the audited ORCJIT `libgallium_dri.so`.

Experiment 154 tests one narrow hypothesis: Mesa's process-lifetime `LPJit`/`LLJIT` teardown overlaps a graphics-worker JIT mapping operation, leaving `add_mapping_to_jd()` with invalid or unavailable ORCJIT singleton state.

## Fixed variables

- Mesa 25.0.0
- LLVM 19.1.7
- LLVM RTTI enabled
- Intel JIT events disabled
- `-Dllvm-orcjit=true`
- Android API 34 / NDK r27d / arm64-v8a
- direct ReDroid Mesa EGL/GLES integration proven by Gate 2
- llvmpipe, `MESA_ANDROID_NO_KMS_SWRAST=1`
- official unmodified Azur Lane client

## Only experimental change

Add low-volume diagnostic markers in `lp_bld_init_orc.cpp` around:

- LPJit singleton creation and atexit registration
- LLJIT construction completion
- JITDylib creation
- `add_ir_module_to_jd()`
- `add_mapping_to_jd()`
- JIT lookup
- `remove_jd()`
- `lpjit_exit()` / LPJit destructor entry / completion of `delete`

Markers include monotonic time, PID, TID, event name, and relevant LPJit/LLJIT/JITDylib pointers. The instrumentation must not add null guards, suppress teardown, clear the singleton, change ownership, serialize execution, or alter game/Unity binaries.

## Runtime gate

Before Azur Lane is launched, the instrumented candidate must pass the existing GLES presentation probe, the `1280x720 -> 1024x576 -> 1280x720` resize/reset cycle, and about a 10-minute clean soak with no graphics failure. Use disposable Android state throughout.

After that regression passes, make one fresh non-hardlinked clone of the persistent Android data and perform one deliberate Azur Lane cold launch. Preserve the first process's lifetime-marker chronology, PID/TID data, logcat/crash evidence, screenshot, and any native crash record before stopping the restart loop.

## Decision gate

- If `lpjit_exit`, LPJit destructor entry, or completed singleton deletion precedes or overlaps a failing mapping/lookup operation, the lifetime-race hypothesis passes and justifies one separate causal correction experiment.
- If the mapping crash occurs while the singleton/LLJIT state is demonstrably live and no teardown has begun, reject this teardown hypothesis and investigate pointer ownership/corruption or an earlier hidden failure.
- If another native/Unity failure clearly starts shutdown first, classify the ORCJIT failure as secondary.
- If instrumentation produces no discriminating evidence, close this lifetime branch rather than tune indefinitely.
