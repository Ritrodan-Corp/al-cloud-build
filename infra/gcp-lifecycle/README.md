# GCP lifecycle control plane

This directory documents the narrow lifecycle-control pattern without publishing deployment-specific identifiers.

## Security model

GitHub Actions authenticates with GitHub OIDC and Google Cloud Workload Identity Federation. No service-account key is created or stored.

The runtime identity should receive only:

- `compute.instances.get`
- `compute.instances.start`
- `compute.instances.stop`

Bind that custom role on the individual VM, not project-wide. WIF providers should constrain repository ID, repository-owner ID, branch/ref, event name, and exact workflow ref before service-account impersonation is allowed.

## Deployment configuration

Exact project, zone, VM, repository numeric IDs, service-account identity, provider IDs, and workflow refs are deployment-specific configuration. Do not commit them to this repository.

Run `bootstrap.sh` only from a trusted authenticated `gcloud` environment after supplying the required environment variables documented by the script. Store exact deployment values in an appropriate secure configuration source.

## Safety boundary

The runtime identity should not be able to delete, reset, suspend, update, SSH into, modify metadata on, change scheduling for, or otherwise administer the VM. The bootstrap script snapshots scheduling before IAM/WIF changes and verifies that it remains unchanged.
