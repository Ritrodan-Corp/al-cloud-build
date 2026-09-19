#!/usr/bin/env bash
set -euo pipefail

: "${ALCLOUD_GCP_PROJECT_ID:?set ALCLOUD_GCP_PROJECT_ID from private configuration}"
: "${ALCLOUD_GCP_ZONE:?set ALCLOUD_GCP_ZONE from private configuration}"
: "${ALCLOUD_GCP_INSTANCE:?set ALCLOUD_GCP_INSTANCE from private configuration}"
: "${ALCLOUD_GCP_REPO_ID:?set ALCLOUD_GCP_REPO_ID from private configuration}"
: "${ALCLOUD_GCP_REPO_OWNER_ID:?set ALCLOUD_GCP_REPO_OWNER_ID from private configuration}"
: "${ALCLOUD_GCP_REPO:?set ALCLOUD_GCP_REPO as owner/repo}"
: "${ALCLOUD_GCP_MANUAL_WORKFLOW_REF:?set exact manual workflow_ref}"
: "${ALCLOUD_GCP_CHAT_WORKFLOW_REF:?set exact chat workflow_ref}"

readonly PROJECT_ID="$ALCLOUD_GCP_PROJECT_ID"
readonly ZONE="$ALCLOUD_GCP_ZONE"
readonly INSTANCE="$ALCLOUD_GCP_INSTANCE"
readonly REPO="$ALCLOUD_GCP_REPO"
readonly REPO_ID="$ALCLOUD_GCP_REPO_ID"
readonly REPO_OWNER_ID="$ALCLOUD_GCP_REPO_OWNER_ID"
readonly MANUAL_WORKFLOW_REF="$ALCLOUD_GCP_MANUAL_WORKFLOW_REF"
readonly CHAT_WORKFLOW_REF="$ALCLOUD_GCP_CHAT_WORKFLOW_REF"

readonly SERVICE_ACCOUNT_ID="${ALCLOUD_GCP_SERVICE_ACCOUNT_ID:-alcloud-vm-lifecycle}"
readonly ROLE_ID="${ALCLOUD_GCP_ROLE_ID:-alCloudVmLifecycle}"
readonly POOL_ID="${ALCLOUD_GCP_POOL_ID:-alcloud-github}"
readonly MANUAL_PROVIDER_ID="${ALCLOUD_GCP_MANUAL_PROVIDER_ID:-alcloud-lifecycle}"
readonly CHAT_PROVIDER_ID="${ALCLOUD_GCP_CHAT_PROVIDER_ID:-alcloud-chat-control}"

readonly SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
readonly ROLE_RESOURCE="projects/${PROJECT_ID}/roles/${ROLE_ID}"

command -v gcloud >/dev/null || { echo 'gcloud is required' >&2; exit 1; }
command -v jq >/dev/null || { echo 'jq is required' >&2; exit 1; }

active_account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n1)"
[[ -n "$active_account" ]] || { echo 'No active gcloud account' >&2; exit 1; }

project_number="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
[[ "$project_number" =~ ^[0-9]+$ ]] || { echo 'Could not determine project number' >&2; exit 1; }
readonly project_number

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
before="$tmpdir/scheduling-before.json"
after="$tmpdir/scheduling-after.json"

gcloud compute instances describe "$INSTANCE" --project="$PROJECT_ID" --zone="$ZONE" --format='json(scheduling)' > "$before"

gcloud services enable iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com cloudresourcemanager.googleapis.com --project="$PROJECT_ID" --quiet

if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SERVICE_ACCOUNT_ID" --project="$PROJECT_ID" --display-name='AL Cloud VM lifecycle control plane'
fi

role_permissions='compute.instances.get,compute.instances.start,compute.instances.stop'
if gcloud iam roles describe "$ROLE_ID" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam roles update "$ROLE_ID" --project="$PROJECT_ID" --title='AL Cloud VM Lifecycle Operator' --description='Start, stop, and describe only the configured AL Cloud VM when bound at instance scope.' --permissions="$role_permissions" --stage=GA --quiet
else
  gcloud iam roles create "$ROLE_ID" --project="$PROJECT_ID" --title='AL Cloud VM Lifecycle Operator' --description='Start, stop, and describe only the configured AL Cloud VM when bound at instance scope.' --permissions="$role_permissions" --stage=GA --quiet
fi

gcloud compute instances add-iam-policy-binding "$INSTANCE" --project="$PROJECT_ID" --zone="$ZONE" --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" --role="$ROLE_RESOURCE" --quiet

if ! gcloud iam workload-identity-pools describe "$POOL_ID" --project="$PROJECT_ID" --location=global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL_ID" --project="$PROJECT_ID" --location=global --display-name='AL Cloud GitHub Actions' --description='Short-lived GitHub Actions identities for AL Cloud.'
fi

attribute_mapping='google.subject=assertion.sub,attribute.repository_id=assertion.repository_id,attribute.repository_owner_id=assertion.repository_owner_id,attribute.ref=assertion.ref,attribute.workflow_ref=assertion.workflow_ref,attribute.event_name=assertion.event_name'

ensure_provider() {
  local provider_id="$1" display_name="$2" description="$3" condition="$4"
  if gcloud iam workload-identity-pools providers describe "$provider_id" --project="$PROJECT_ID" --location=global --workload-identity-pool="$POOL_ID" >/dev/null 2>&1; then
    gcloud iam workload-identity-pools providers update-oidc "$provider_id" --project="$PROJECT_ID" --location=global --workload-identity-pool="$POOL_ID" --display-name="$display_name" --description="$description" --issuer-uri='https://token.actions.githubusercontent.com' --attribute-mapping="$attribute_mapping" --attribute-condition="$condition" --quiet
  else
    gcloud iam workload-identity-pools providers create-oidc "$provider_id" --project="$PROJECT_ID" --location=global --workload-identity-pool="$POOL_ID" --display-name="$display_name" --description="$description" --issuer-uri='https://token.actions.githubusercontent.com' --attribute-mapping="$attribute_mapping" --attribute-condition="$condition"
  fi
}

manual_condition="assertion.repository_id=='${REPO_ID}' && assertion.repository_owner_id=='${REPO_OWNER_ID}' && assertion.ref=='refs/heads/main' && assertion.event_name=='workflow_dispatch' && assertion.workflow_ref=='${MANUAL_WORKFLOW_REF}'"
chat_condition="assertion.repository_id=='${REPO_ID}' && assertion.repository_owner_id=='${REPO_OWNER_ID}' && assertion.ref=='refs/heads/vm-control' && assertion.event_name=='push' && assertion.workflow_ref=='${CHAT_WORKFLOW_REF}'"

ensure_provider "$MANUAL_PROVIDER_ID" 'AL Cloud lifecycle workflow' 'Trust only the configured manual lifecycle workflow.' "$manual_condition"
ensure_provider "$CHAT_PROVIDER_ID" 'AL Cloud chat lifecycle' 'Trust only the configured push-triggered lifecycle workflow.' "$chat_condition"

pool_resource="projects/${project_number}/locations/global/workloadIdentityPools/${POOL_ID}"
wif_member="principalSet://iam.googleapis.com/${pool_resource}/attribute.repository_id/${REPO_ID}"
gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT_EMAIL" --project="$PROJECT_ID" --role='roles/iam.workloadIdentityUser' --member="$wif_member" --quiet

gcloud compute instances describe "$INSTANCE" --project="$PROJECT_ID" --zone="$ZONE" --format='json(scheduling)' > "$after"
diff -u <(jq -S . "$before") <(jq -S . "$after") || { echo 'ERROR: scheduling changed during bootstrap' >&2; exit 1; }

echo 'Lifecycle control-plane bootstrap complete; scheduling unchanged.'
