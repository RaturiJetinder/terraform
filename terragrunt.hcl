locals {
  backend_config_path = find_in_parent_folders("config/backend.hcl", "config/backend.hcl.example")
  backend             = read_terragrunt_config(local.backend_config_path)
  project_id          = local.backend.locals.project_id
  default_region      = local.backend.locals.default_region
  state_bucket        = local.backend.locals.state_bucket
  state_prefix        = local.backend.locals.state_prefix
  impersonate_sa      = local.backend.locals.impersonate_sa
}

remote_state {
  backend = "gcs"
  config = {
    bucket = local.state_bucket
    prefix = local.state_prefix
    project = local.project_id
  }
}

terraform {
  before_hook "require_service_account_key" {
    commands = ["init", "plan", "apply", "destroy"]
    execute  = ["bash", "-c", "if [[ -z \"$GOOGLE_APPLICATION_CREDENTIALS\" ]] || [[ ! -f \"$GOOGLE_APPLICATION_CREDENTIALS\" ]]; then echo 'GOOGLE_APPLICATION_CREDENTIALS must point to a service account key file. ADC is not allowed.' >&2; exit 1; fi"]
  }
}

generate "provider" {
  path      = "provider.auto.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF_PROVIDER
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.7"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.7"
    }
  }
}

provider "google" {
  project                     = "${local.project_id}"
  region                      = "${local.default_region}"
  impersonate_service_account = ${local.impersonate_sa != null ? "\"${local.impersonate_sa}\"" : "null"}
}

provider "google-beta" {
  project                     = "${local.project_id}"
  region                      = "${local.default_region}"
  impersonate_service_account = ${local.impersonate_sa != null ? "\"${local.impersonate_sa}\"" : "null"}
}
EOF_PROVIDER
}

inputs = {
  project_id = local.project_id
  region     = local.default_region
}
