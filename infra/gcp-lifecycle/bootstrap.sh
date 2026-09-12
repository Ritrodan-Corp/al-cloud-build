#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_ID='project-97e3d26a-3ba2-4579-b03'
readonly ZONE='us-central1-a'
readonly INSTANCE='azl-android-arm64-01'
readonly SERVICE_ACCOUNT_ID='alcloud-vm-lifecycle'
readonly SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
readonly ROLE_ID='alCloudVmLifecycle'
readonly ROLE_RESOURCE="projects/${PROJECT_ID}/roles/${ROLE_ID}"
readonly POOL_ID='alcloud-github'
readonly PROVIDER_ID='alcloud-lifecycle'
readonly REPO='Ritrodan-Corp/al-cloud-build'
readonly REPO_ID='1366956589'
readonly REPO_OWNER_ID='316736398'
readonly WORKFLOW_REF='Ritrodan-Corp/al-cloud-build/.github/workflows/gcp-vm-lifecycle.yml@refs/heads/main'

command -v gcloud >/dev/null || {
  echo 'gcloud is required. Run this script in Google Cloud Shell or another authenticated gcloud environment.' >&2
  exit 1
}
command -v jq >/dev/null || {
  echo 'jq is required.' >&2
  exit 1
}

active_account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n1)"
[[ -n "$active_account" ]] || {
  echo 'No active gcloud account. Authenticate before running this bootstrap.' >&2
  exit 1
}

echo "Active gcloud account: ${active_account}"
echo "Target project: ${PROJECT_ID}"
echo "Target VM: ${ZONE}/${INSTANCE}"

project_number="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
[[ "$project_number" =~ ^[0-9]+$ ]] || {
  echo 'Could not determine the numeric GCP project number.' >&2
  exit 1
}
readonly project_number

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
before="$tmpdir/scheduling-before.json"
after="$tmpdir/scheduling-after.json"

# Snapshot the lifecycle policy before any IAM/WIF changes. This script never
# calls set-scheduling or any guest-management operation.
gcloud compute instances describe "$INSTANCE" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --format='json(scheduling)' > "$before"

echo 'Existing VM scheduling policy:'
jq -S . "$before"

# WIF with service-account impersonation requires these APIs. Enabling them
# creates no service-account key and does not change the VM.
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project="$PROJECT_ID" \
  --quiet

if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Service account already exists: ${SERVICE_ACCOUNT_EMAIL}"
else
  gcloud iam service-accounts create "$SERVICE_ACCOUNT_ID" \
    --project="$PROJECT_ID" \
    --display-name='AL Cloud VM lifecycle control plane'
fi

role_permissions='compute.instances.get,compute.instances.start,compute.instances.stop'
if gcloud iam roles describe "$ROLE_ID" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam roles update "$ROLE_ID" \
    --project="$PROJECT_ID" \
    --title='AL Cloud VM Lifecycle Operator' \
    --description='Start, stop, and describe only azl-android-arm64-01 when bound at instance scope.' \
    --permissions="$role_permissions" \
    --stage=GA \
    --quiet
else
  gcloud iam roles create "$ROLE_ID" \
    --project="$PROJECT_ID" \
    --title='AL Cloud VM Lifecycle Operator' \
    --description='Start, stop, and describe only azl-android-arm64-01 when bound at instance scope.' \
    --permissions="$role_permissions" \
    --stage=GA \
    --quiet
fi

# Grant the runtime identity its three Compute permissions only on this VM.
gcloud compute instances add-iam-policy-binding "$INSTANCE" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="$ROLE_RESOURCE" \
  --quiet

if gcloud iam workload-identity-pools describe "$POOL_ID" \
  --project="$PROJECT_ID" \
  --location=global >/dev/null 2>&1; then
  echo "Workload Identity Pool already exists: ${POOL_ID}"
else
  gcloud iam workload-identity-pools create "$POOL_ID" \
    --project="$PROJECT_ID" \
    --location=global \
    --display-name='AL Cloud GitHub Actions' \
    --description='Short-lived GitHub Actions identities for AL Cloud.'
fi

attribute_mapping='google.subject=assertion.sub,attribute.repository_id=assertion.repository_id,attribute.repository_owner_id=assertion.repository_owner_id,attribute.ref=assertion.ref,attribute.workflow_ref=assertion.workflow_ref,attribute.event_name=assertion.event_name'
attribute_condition="assertion.repository_id=='${REPO_ID}' && assertion.repository_owner_id=='${REPO_OWNER_ID}' && assertion.ref=='refs/heads/main' && assertion.event_name=='workflow_dispatch' && assertion.workflow_ref=='${WORKFLOW_REF}'"

if gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location=global \
  --workload-identity-pool="$POOL_ID" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers update-oidc "$PROVIDER_ID" \
    --project="$PROJECT_ID" \
    --location=global \
    --workload-identity-pool="$POOL_ID" \
    --display-name='AL Cloud lifecycle workflow' \
    --description='Trust only the fixed manual lifecycle workflow on main.' \
    --issuer-uri='https://token.actions.githubusercontent.com' \
    --attribute-mapping="$attribute_mapping" \
    --attribute-condition="$attribute_condition" \
    --quiet
else
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
    --project="$PROJECT_ID" \
    --location=global \
    --workload-identity-pool="$POOL_ID" \
    --display-name='AL Cloud lifecycle workflow' \
    --description='Trust only the fixed manual lifecycle workflow on main.' \
    --issuer-uri='https://token.actions.githubusercontent.com' \
    --attribute-mapping="$attribute_mapping" \
    --attribute-condition="$attribute_condition"
fi

pool_resource="projects/${project_number}/locations/global/workloadIdentityPools/${POOL_ID}"
provider_resource="${pool_resource}/providers/${PROVIDER_ID}"
wif_member="principalSet://iam.googleapis.com/${pool_resource}/attribute.repository_id/${REPO_ID}"

gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT_EMAIL" \
  --project="$PROJECT_ID" \
  --role='roles/iam.workloadIdentityUser' \
  --member="$wif_member" \
  --quiet

# Re-read the scheduling policy and fail loudly if anything changed while the
# control plane was being bootstrapped.
gcloud compute instances describe "$INSTANCE" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --format='json(scheduling)' > "$after"

if ! diff -u <(jq -S . "$before") <(jq -S . "$after"); then
  echo 'ERROR: VM scheduling policy changed during bootstrap. Review the diff above.' >&2
  exit 1
fi

echo 'VM scheduling policy is unchanged.'
echo
echo 'GCP lifecycle control plane bootstrap complete.'
echo "GCP project number: ${project_number}"
echo "WIF provider: ${provider_resource}"
echo "Service account: ${SERVICE_ACCOUNT_EMAIL}"
echo "Custom role: ${ROLE_RESOURCE}"
echo "Instance-scoped target: ${ZONE}/${INSTANCE}"
echo
echo 'One GitHub repository variable remains to activate the workflow:'
echo "  GCP_PROJECT_NUMBER=${project_number}"
echo "Repository: ${REPO}"
echo
echo 'After that variable is set, run the GitHub workflow with action=describe first.'
