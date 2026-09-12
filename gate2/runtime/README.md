# Gate 2 runtime contract

This directory contains runtime-side tooling for the bounded Mesa LLVMpipe GLES validation on `azl-android-arm64-01`.

## Safety boundary

- Preserve the production ReDroid Android data at `/var/lib/azl-android/data`.
- Do not launch Azur Lane until Gate 2 passes.
- Use disposable Android data/configuration for every Mesa candidate boot.
- Do not overwrite the immutable ReDroid image or persistent vendor files.
- Prefer read-only bind mounts for candidate libraries and explicit rollback to `azl-redroid.service`.
- Maximum three Mesa candidate boots under the current bounded experiment.

## Gate 2 sequence

1. Run `preflight-readonly.sh` against the healthy reference runtime.
2. Verify the exact Mesa deployment bundle and GLES probe APK checksums on-host.
3. Inspect live `/vendor/lib64/egl`, linker namespaces, and SELinux labels before choosing mount points.
4. Stop only the reference ReDroid service needed for the disposable candidate boot; leave persistent `/data` untouched.
5. Start the candidate with a new disposable data directory, Mesa EGL/GLES split-driver names, and Mesa Android no-KMS/software properties while retaining ReDroid gralloc/composer.
6. Confirm Android boots, then verify loaded Mesa libraries and renderer identity from both process maps and GL queries.
7. Install only the Gate 2 probe APK and run it for approximately five minutes.
8. Validate shader compilation, texture sampling, alpha blending, repeated swaps, screenshots, frame continuity, and at least one forced display resize followed by reset.
9. Require correct visible output plus native-buffer presentation evidence. Renderer strings alone are insufficient.
10. Restore the normal `azl-redroid.service` baseline after the candidate test, pass or fail.

## Expected build artifacts

- Mesa bundle: `mesa-25.0.0-android-arm64-llvmpipe`, inner tar SHA-256 `3fb6f16388b25393d75b5107d9bad5ac14697c13dd52ff3407930eb641609eac`.
- GLES probe APK: SHA-256 `bb0464c60e0e9055d70406c60c44b35cf848f99e4f03f8ffcc72308e79950ea9`.

Any integration failure must be diagnosed from concrete loader/linker/SELinux/buffer evidence before changing the candidate configuration.
