# GCP lifecycle control plane

This control plane is intentionally narrow. It can only describe, start, or stop the Compute Engine VM `azl-android-arm64-01` in `us-central1-a` in project `project-97e3d26a-3ba2-4579-b03`.

## Security model

GitHub Actions authenticates with GitHub OIDC and Google Cloud Workload Identity Federation. No service-account key is created or stored.

The runtime service account is `alcloud-vm-lifecycle@project-97e3d26a-3ba2-4579-b03.iam.gserviceaccount.com`. Its custom role contains exactly these Compute Engine permissions:

- `compute.instances.get`
- `compute.instances.start`
- `compute.instances.stop`

That custom role is bound on the individual VM, not at project scope.

The active chat-control path is branch `vm-control`, workflow `.github/workflows/gcp-vm-chat-control.yml`, triggered only by changes to the constrained lifecycle command file or immutable log-inbox submissions. The workflow has only `contents: read` and `id-token: write` GitHub permissions and uses fixed GCP project, zone, instance, WIF-provider, and service-account identifiers. Log-only commits skip the lifecycle job.

## Bootstrap

Run the bootstrap once from an authenticated Google Cloud Shell or another trusted `gcloud` session with permission to manage IAM, service accounts, WIF, service enablement, and the target VM's IAM policy:

```bash
git clone https://github.com/Ritrodan-Corp/al-cloud-build.git
cd al-cloud-build
bash infra/gcp-lifecycle/bootstrap.sh
```

The script is idempotent. It snapshots the VM scheduling block before IAM/WIF changes and compares it afterward. It never calls `set-scheduling` and never touches the guest OS.

The script prints the numeric GCP project number. Add that value as the GitHub repository Actions variable `GCP_PROJECT_NUMBER`. The value is not a secret.

## Operation

The chat-control workflow accepts these lifecycle actions:

- `describe` reads status and the lifecycle scheduling fields.
- `start` starts only from `TERMINATED`, or waits out an already-running stop/start transition instead of sending a duplicate request.
- `stop` is the normal project closeout action. Its use asserts that guest cleanup and baseline verification are complete. It calls the fixed Compute stop endpoint with `noGracefulShutdown=true`, bypassing the configured pre-ACPI application grace interval while still allowing the guest to receive the ordinary ACPI soft-off signal and shut down through systemd.
- `stop_graceful` is the conservative fallback when guest cleanup status is unknown. It omits `noGracefulShutdown`, so Compute Engine preserves the VM's configured application grace interval before ACPI shutdown.
- `stop_after_cleanup` remains accepted as a backward-compatible alias for routine `stop`; new callers should use `stop`.

The normal project lifecycle is therefore START -> guest work -> cleanup and baseline verification -> STOP. The former 600-second application-grace delay is not part of routine closeout anymore. The VM's configured graceful-shutdown setting is intentionally left intact so `stop_graceful` remains available for exceptional or uncertain cleanup cases.

Routine `stop` succeeds only after Compute is observed in `STOPPING` or `TERMINATED`, which proves the request has moved beyond the pre-ACPI `PENDING_STOP` grace phase. If a prior conservative stop has already left the VM in `PENDING_STOP`, routine `stop` may still be used after cleanup is confirmed to end the remaining application-grace interval. `stop_graceful` may return after `PENDING_STOP`, `STOPPING`, or `TERMINATED` is observed. START waits for `TERMINATED` before restarting if any stop is still in progress.

Start and stop requests use a UUID request ID for retry safety. None of these actions changes max run duration, termination action, scheduling, metadata, disks, network configuration, service accounts, ReDroid, Android data, or renderer configuration.

## Safety boundary

The runtime identity cannot delete, reset, suspend, update, SSH into, modify metadata on, change scheduling for, or otherwise administer the VM because those permissions are absent from its custom role. It has no project-wide Compute role.
