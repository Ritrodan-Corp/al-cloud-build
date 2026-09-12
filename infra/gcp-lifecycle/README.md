# GCP lifecycle control plane

This control plane is intentionally narrow. It can only describe, start, or stop the Compute Engine VM `azl-android-arm64-01` in `us-central1-a` in project `project-97e3d26a-3ba2-4579-b03`.

## Security model

GitHub Actions authenticates with GitHub OIDC and Google Cloud Workload Identity Federation. No service-account key is created or stored.

The runtime service account is `alcloud-vm-lifecycle@project-97e3d26a-3ba2-4579-b03.iam.gserviceaccount.com`. Its custom role contains exactly these Compute Engine permissions:

- `compute.instances.get`
- `compute.instances.start`
- `compute.instances.stop`

That custom role is bound on the individual VM, not at project scope.

The WIF provider accepts only OIDC tokens that match all of the following:

- GitHub repository ID `1366956589`
- GitHub organization ID `316736398`
- branch `refs/heads/main`
- event `workflow_dispatch`
- workflow `Ritrodan-Corp/al-cloud-build/.github/workflows/gcp-vm-lifecycle.yml@refs/heads/main`

The workflow itself has only `contents: read` and `id-token: write` GitHub permissions and uses fixed GCP project, zone, and instance identifiers.

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

Run the GitHub Actions workflow **GCP VM lifecycle** manually and choose one action:

- `describe` reads status and the lifecycle scheduling fields.
- `start` sends a start request only when the VM is `TERMINATED`.
- `stop` sends a normal stop request only when the VM is `RUNNING`.

The stop request deliberately omits `noGracefulShutdown`, so Compute Engine honors the VM's existing graceful-shutdown policy. The workflow does not change max run duration, termination action, scheduling, metadata, disks, network configuration, service accounts, ReDroid, Mesa, Android data, or Gate 2 configuration.

Start and stop requests use a UUID request ID for retry safety. The workflow reports the VM state shortly after request submission rather than waiting for graceful shutdown to finish. Use `describe` for subsequent status checks.

## Safety boundary

The runtime identity cannot delete, reset, suspend, update, SSH into, modify metadata on, change scheduling for, or otherwise administer the VM because those permissions are absent from its custom role. It has no project-wide Compute role.
