#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
BOOTSTRAP_DIR="${ROOT_DIR}/bootstrap"
CONFIG_FILE="${ROOT_DIR}/config/backend.hcl"
CONFIG_SAMPLE="${ROOT_DIR}/config/backend.hcl.example"

PROJECT_ID=""
BUCKET_NAME=""
BUCKET_LOCATION="us"
DEFAULT_REGION="us-central1"
STATE_PREFIX="terraform/state"
FORCE_DESTROY="false"
IMPERSONATE_SA=""
COMPONENT_TYPE="gcs"
PURPOSE=""
INSTANCE_NUMBER="1"
ENVIRONMENT=""

ALLOWED_COMPONENT_TYPES=(
  vm cont k8s sl dataproc run df
  gcs disk filestore dl
  sql bq nosql cache
  vpc snet fw lb rt vpn
  pubsub etl wf
  log dash alert
  iam kms secret
  api dns cdn bck
)

usage() {
  cat <<USAGE
Usage: $(basename "$0") --project-id=<id> [--bucket-name=<name> | --purpose=<purpose> --environment=<env> [options]]

Options:
  --bucket-name        Explicit bucket name (must follow livgolf naming standards)
  --component-type     Component type code (default: gcs)
  --purpose            Purpose/segment for the bucket name (required if --bucket-name not supplied)
  --instance-number    Numeric instance identifier (default: 1)
  --environment        Environment tag such as dev, test, prod (required if --bucket-name not supplied)
  --bucket-location    Multi-region or region for the bucket (default: us)
  --default-region     Default Google Cloud region for providers (default: us-central1)
  --state-prefix       Prefix inside the bucket for Terraform state (default: terraform/state)
  --force-destroy      Set to true to allow bucket deletion even if it contains objects (default: false)
  --impersonate-sa     Optional service account email for provider impersonation
  -h, --help           Show this help message

Environment:
  GOOGLE_APPLICATION_CREDENTIALS must point to a service account key JSON file, or you
  need to be authenticated with gcloud and have application default credentials available.
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] Required command '$cmd' is not available in PATH" >&2
    exit 1
  fi
}

bucket_exists() {
  local bucket="$1"
  if command -v gcloud >/dev/null 2>&1; then
    if gcloud storage buckets describe "gs://${bucket}" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-id=*) PROJECT_ID="${1#*=}" ; shift ;;
      --project-id) PROJECT_ID="$2" ; shift 2 ;;
      --bucket-name=*) BUCKET_NAME="${1#*=}" ; shift ;;
      --bucket-name) BUCKET_NAME="$2" ; shift 2 ;;
      --component-type=*) COMPONENT_TYPE="${1#*=}" ; shift ;;
      --component-type) COMPONENT_TYPE="$2" ; shift 2 ;;
      --purpose=*) PURPOSE="${1#*=}" ; shift ;;
      --purpose) PURPOSE="$2" ; shift 2 ;;
      --instance-number=*) INSTANCE_NUMBER="${1#*=}" ; shift ;;
      --instance-number) INSTANCE_NUMBER="$2" ; shift 2 ;;
      --environment=*) ENVIRONMENT="${1#*=}" ; shift ;;
      --environment) ENVIRONMENT="$2" ; shift 2 ;;
      --bucket-location=*) BUCKET_LOCATION="${1#*=}" ; shift ;;
      --bucket-location) BUCKET_LOCATION="$2" ; shift 2 ;;
      --default-region=*) DEFAULT_REGION="${1#*=}" ; shift ;;
      --default-region) DEFAULT_REGION="$2" ; shift 2 ;;
      --state-prefix=*) STATE_PREFIX="${1#*=}" ; shift ;;
      --state-prefix) STATE_PREFIX="$2" ; shift 2 ;;
      --force-destroy=*) FORCE_DESTROY="${1#*=}" ; shift ;;
      --force-destroy) FORCE_DESTROY="$2" ; shift 2 ;;
      --impersonate-sa=*) IMPERSONATE_SA="${1#*=}" ; shift ;;
      --impersonate-sa) IMPERSONATE_SA="$2" ; shift 2 ;;
      -h|--help) usage ; exit 0 ;;
      *) echo "Unknown option: $1" >&2 ; usage >&2 ; exit 1 ;;
    esac
  done

  if [[ -z "$PROJECT_ID" ]]; then
    echo "[ERROR] --project-id is required." >&2
    usage >&2
    exit 1
  fi

  if [[ -z "$BUCKET_NAME" ]]; then
    if [[ -z "$PURPOSE" || -z "$ENVIRONMENT" ]]; then
      echo "[ERROR] Provide --bucket-name or both --purpose and --environment to generate one." >&2
      usage >&2
      exit 1
    fi
  fi
}

normalize_segment() {
  local value="$1"
  value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
  value=$(echo "$value" | sed -E 's/[^a-z0-9]+/-/g')
  value=$(echo "$value" | sed -E 's/^-+//; s/-+$//; s/-{2,}/-/g')
  echo "$value"
}

validate_component_type() {
  local input="$1"
  for code in "${ALLOWED_COMPONENT_TYPES[@]}"; do
    if [[ "$input" == "$code" ]]; then
      return 0
    fi
  done
  echo "[ERROR] Component type '$input' is not allowed. Valid options: ${ALLOWED_COMPONENT_TYPES[*]}" >&2
  exit 1
}

format_instance_number() {
  local raw="$1"
  if [[ ! "$raw" =~ ^[0-9]+$ ]]; then
    echo "[ERROR] Instance number must be numeric." >&2
    exit 1
  fi
  local decimal=$((10#$raw))
  printf "%02d" "$decimal"
}

validate_bucket_name() {
  local name="$1"
  if [[ ! "$name" =~ ^livgolf-[a-z0-9]+-[a-z0-9]+-[0-9]{2}-[a-z0-9]+$ ]]; then
    echo "[ERROR] Bucket name '$name' does not follow livgolf-{component_type}-{purpose}-{instance_number}-{environment}." >&2
    exit 1
  fi
  local component
  component=$(echo "$name" | cut -d'-' -f2)
  validate_component_type "$component"
}

generate_bucket_name() {
  COMPONENT_TYPE=$(normalize_segment "$COMPONENT_TYPE")
  PURPOSE=$(normalize_segment "$PURPOSE")
  ENVIRONMENT=$(normalize_segment "$ENVIRONMENT")
  INSTANCE_NUMBER=$(format_instance_number "$INSTANCE_NUMBER")

  if [[ -z "$PURPOSE" || -z "$ENVIRONMENT" ]]; then
    echo "[ERROR] Purpose and environment must contain alphanumeric characters." >&2
    exit 1
  fi

  validate_component_type "$COMPONENT_TYPE"
  BUCKET_NAME="livgolf-${COMPONENT_TYPE}-${PURPOSE}-${INSTANCE_NUMBER}-${ENVIRONMENT}"
}

write_backend_config() {
  cat <<EOF_CONF > "$CONFIG_FILE"
locals {
  project_id        = "${PROJECT_ID}"
  default_region    = "${DEFAULT_REGION}"
  state_bucket      = "${BUCKET_NAME}"
  state_prefix      = "${STATE_PREFIX}"
  impersonate_sa    = ${IMPERSONATE_SA:+"${IMPERSONATE_SA}"}
}
EOF_CONF
  # handle null impersonation when empty
  if [[ -z "$IMPERSONATE_SA" ]]; then
    # replace empty quotes with null for Terragrunt consumption
    sed -i 's/""/null/' "$CONFIG_FILE"
  fi
}

run_bootstrap() {
  echo "[INFO] Running Terraform bootstrap in ${BOOTSTRAP_DIR}"
  terraform -chdir="$BOOTSTRAP_DIR" init >/dev/null
  terraform -chdir="$BOOTSTRAP_DIR" apply -auto-approve \
    -var "project_id=${PROJECT_ID}" \
    -var "bucket_name=${BUCKET_NAME}" \
    -var "bucket_location=${BUCKET_LOCATION}" \
    -var "default_region=${DEFAULT_REGION}" \
    -var "force_destroy=${FORCE_DESTROY}" \
    -var "state_prefix=${STATE_PREFIX}"
}

main() {
  parse_args "$@"
  require_cmd terraform

  if [[ -z "$BUCKET_NAME" ]]; then
    generate_bucket_name
    echo "[INFO] Generated bucket name: ${BUCKET_NAME}"
  else
    validate_bucket_name "$BUCKET_NAME"
  fi

  if bucket_exists "$BUCKET_NAME"; then
    echo "[INFO] Bucket gs://${BUCKET_NAME} already exists. Terraform will ensure it matches desired config."
  else
    echo "[INFO] Bucket gs://${BUCKET_NAME} does not exist or cannot be verified. Terraform will attempt to create it."
  fi

  mkdir -p "$(dirname "$CONFIG_FILE")"
  if [[ ! -f "$CONFIG_FILE" && -f "$CONFIG_SAMPLE" ]]; then
    cp "$CONFIG_SAMPLE" "$CONFIG_FILE"
  fi

  run_bootstrap
  write_backend_config

  echo "[INFO] Backend configuration written to ${CONFIG_FILE}"
  echo "[INFO] Bootstrap completed. Terragrunt can now be executed from environment directories."
}

main "$@"
