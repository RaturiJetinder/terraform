#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/.env"

export PROJECT_ID REGION STATE_BUCKET DEPLOY_SA_EMAIL

# Prefer impersonation (no key leakage)
if [[ -z "${SA_KEY_PATH}" ]]; then
  echo "Using impersonation: ${DEPLOY_SA_EMAIL}"
  export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="${DEPLOY_SA_EMAIL}"
else
  echo "Using key file: ${SA_KEY_PATH}"
  export GOOGLE_APPLICATION_CREDENTIALS="${SA_KEY_PATH}"
fi

# sanity
gcloud config set project "${PROJECT_ID}" >/dev/null
gcloud auth list

# Plan/apply the whole environment
cd "${ROOT_DIR}/infra/live/staging/asia-south1"
terragrunt run-all init
terragrunt run-all plan

# uncomment to apply non-interactively in CI/VM
# terragrunt run-all apply --terragrunt-non-interactive --terragrunt-include-external-dependencies
