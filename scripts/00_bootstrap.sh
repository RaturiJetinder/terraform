#!/usr/bin/env bash
set -euo pipefail

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/.env"

echo "== Bootstrap for project: ${PROJECT_ID} (${ENV_SLUG}) =="

# Make sure gcloud is pointed at the right project
gcloud config set project "${PROJECT_ID}" >/dev/null

# ---------- 1) Create state bucket if missing ----------
if ! gsutil ls -p "${PROJECT_ID}" "gs://${STATE_BUCKET}" >/dev/null 2>&1; then
  echo "Creating GCS state bucket: gs://${STATE_BUCKET}"
  gsutil mb -p "${PROJECT_ID}" -c "${STATE_BUCKET_STORAGE_CLASS}" -l "${STATE_BUCKET_LOCATION}" "gs://${STATE_BUCKET}"
  # Uniform bucket-level access, no public access
  gsutil uniformbucketlevelaccess set on "gs://${STATE_BUCKET}"
  gsutil iam ch \
    "projectEditor:${PROJECT_ID}:objectViewer" \
    "projectViewer:${PROJECT_ID}:objectViewer" \
    >/dev/null 2>&1 || true  # harmless if not resolvable
else
  echo "State bucket already exists: gs://${STATE_BUCKET}"
fi

# Remove public access if any
gsutil iam ch -d "allUsers:objectViewer" "gs://${STATE_BUCKET}" || true
gsutil iam ch -d "allAuthenticatedUsers:objectViewer" "gs://${STATE_BUCKET}" || true

# ---------- 2) Create deployer service account ----------
if ! gcloud iam service-accounts describe "${DEPLOY_SA_EMAIL}" >/dev/null 2>&1; then
  echo "Creating deployer SA: ${DEPLOY_SA_EMAIL}"
  gcloud iam service-accounts create "${DEPLOY_SA_ID}" \
    --display-name="Terraform/Terragrunt deployer (${ENV_SLUG})"
else
  echo "Deployer SA exists: ${DEPLOY_SA_EMAIL}"
fi

# ---------- 3) Bucket-level least privilege for deployer SA ----------
# Terraform GCS backend needs to read/write/lock state objects.
echo "Granting bucket-scoped roles/storage.objectAdmin on state bucket to deployer SA"
gsutil iam ch "serviceAccount:${DEPLOY_SA_EMAIL}:roles/storage.objectAdmin" "gs://${STATE_BUCKET}"

# ---------- 4) Project roles for deployer SA (curate to what you deploy) ----------
# Keep minimal; add/remove as your stacks require.
echo "Granting project roles to deployer SA (minimal, curated)"

ROLES=(
  # Enable APIs (or do once as human)
  "roles/serviceusage.serviceUsageConsumer"

  # Networking for VPC, subnets, firewall, routes, connectors
  "roles/compute.networkAdmin"
  "roles/compute.securityAdmin"
  "roles/vpcaccess.admin"
  "roles/servicenetworking.admin"

  # Cloud Run (if used)
  "roles/run.admin"

  # Artifact Registry (push images or bind existing)
  "roles/artifactregistry.writer"

  # Service Account User to let Terraform bind runtimes to SAs
  "roles/iam.serviceAccountUser"
)

for r in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${DEPLOY_SA_EMAIL}" \
    --role "${r}" \
    --quiet >/dev/null
done

# ---------- 5) Enable only required APIs ----------
APIS=(
  compute.googleapis.com
  iam.googleapis.com
  servicemanagement.googleapis.com
  serviceusage.googleapis.com
  vpcaccess.googleapis.com
  run.googleapis.com
  artifactregistry.googleapis.com
  cloudresourcemanager.googleapis.com
)
echo "Enabling APIs..."
gcloud services enable "${APIS[@]}"

# ---------- 6) Optional: create a key file (prefer impersonation; skip if empty) ----------
if [[ -n "${SA_KEY_PATH}" ]]; then
  if [[ ! -f "${SA_KEY_PATH}" ]]; then
    echo "Creating key for ${DEPLOY_SA_EMAIL} at ${SA_KEY_PATH}"
    mkdir -p "$(dirname "${SA_KEY_PATH}")"
    gcloud iam service-accounts keys create "${SA_KEY_PATH}" \
      --iam-account "${DEPLOY_SA_EMAIL}"
  else
    echo "Key already exists at ${SA_KEY_PATH}"
  fi
else
  echo "Skipping key creation (impersonation recommended)."
fi

echo "== Bootstrap complete =="
echo "State bucket: gs://${STATE_BUCKET}"
echo "Deployer SA : ${DEPLOY_SA_EMAIL}"
