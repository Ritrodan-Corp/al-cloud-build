# GCP lifecycle control plane

This control plane is intentionally narrow. It can only describe, start, or stop the Compute Engine VM `azl-android-arm64-01` in `us-central1-a` in project `project-97e3d26a-3ba2-4579-b03`.

## Security model

GitHub Actions authenticates with GitHub OIDC and Google Cloud Workload Identity Federation. No service-account key is created or stored.

The runtime service account is `alcloud-vm-lifecycle@project-97e3d26a-3ba2-4579-b03.iam.gserviceaccount.com`. Its custom role contains exactly these Compute Engine permissions:

- `compute.instances.get`
- `compute.instances.start`
- `compute.instances.stop`

That custom role is bound on the individual VM, not at project scope.

Two WIF providers isolate the human/manual and ChatGPT command paths:

- `alcloud-lifecycle` trusts only repository ID `1366956589`, organization ID `316736398`, branch `refs/heads/main`, event `workflow_dispatch`, and workflow `Ritrodan-Corp/al-cloud-build/.github/workflows/gcp-vm-lifecycle.yml@refs/heads/main`.
- `alcloud-chat-control` trusts only the same repository and organization IDs, branch `refs/heads/vm-control`, event `push`, and workflow `Ritrodan-Corp/al-cloud-build/.github/workflows/gcp-vm-chat-control.yml@refs/heads/vm-control`.

The workflows use fixed GCP project, zone, and instance identifiers. The ChatGPT workflow is additionally path-limited to pushes that modify `control/command.json` on `vm-control` and validates that file before requesting a cloud token.

## Bootstrap

Run the bootstrap from an authenticated Google Cloud Shell or another trusted `gcloud` session with permission to manage IAM, service accounts, WIF, service enablement, and the target VM's IAM policy:

```bash
git clone https://github.com/Ritrodan-Corp/al-cloud-build.git
cd al-cloud-build
git pull --ff-only origin main
bash infra/gcp-lifecycle/bootstrap.sh
```

If you already cloned the repository, use the existing checkout and run `git pull --ff-only origin main` before the script.

The script is idempotent. It snapshots the VM scheduling block before IAM/WIF changes and compares it afterward. It never calls `set-scheduling` and never touches the guest OS. It creates or updates both WIF providers and reuses the same instance-scoped lifecycle service account. No GitHub secret, repository variable, or service-account key is required.

## Manual operation

Run the GitHub Actions workflow **GCP VM lifecycle** manually and choose one action:

- `describe` reads status and lifecycle scheduling fields.
- `start` sends a start request only when the VM is `TERMINATED`.
- `stop` sends a normal stop request only when the VM is `RUNNING`.

## ChatGPT operation

Normal ChatGPT cannot originate `workflow_dispatch` with the current GitHub connector, but it can write repository files. The dedicated `vm-control` branch converts that available primitive into an auditable lifecycle command channel.

`control/command.json` must contain exactly:

```json
{
  "action": "describe",
  "nonce": "00000000-0000-4000-8000-000000000000"
}
```

`action` must be `describe`, `start`, or `stop`. `nonce` must be a fresh UUID for each command. Updating this file on `vm-control` triggers **GCP VM Chat control**, which validates the command, obtains a short-lived Google access token through the dedicated WIF provider, and executes the constrained lifecycle operation.

The initial seed command was committed before the workflow existed, so bootstrap does not itself trigger any VM action. After bootstrap, the first validation should be a fresh `describe` command written by ChatGPT. Test `stop` only after that read-only path succeeds and reports the expected VM/scheduling state; then test `start` from `TERMINATED`.

Both start and stop use the UUID as the Compute Engine request ID for retry safety. Stop deliberately omits `noGracefulShutdown`, so Compute Engine honors the VM's configured graceful-shutdown policy. Neither workflow changes max run duration, termination action, scheduling, metadata, disks, networking, service accounts, ReDroid, Mesa, or Android data.

## Safety boundary

The runtime identity cannot delete, reset, suspend, update, SSH into, modify metadata on, change scheduling for, or otherwise administer the VM because those permissions are absent from its custom role. It has no project-wide Compute role.
