# infra/live/terragrunt.hcl
locals {
  # Import .env at run time via env vars; we’ll export in deploy script
  state_bucket = get_env("STATE_BUCKET")
}

remote_state {
  backend = "gcs"
  config = {
    bucket = local.state_bucket
    prefix = "terraform/${path_relative_to_include()}"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.7.0"
      required_providers {
        google = { source = "hashicorp/google", version = "~> 5.40" }
      }
    }

    variable "project_id" {}
    variable "region" {}
    variable "impersonate_sa" { default = null }

    provider "google" {
      project = var.project_id
      region  = var.region
      impersonate_service_account = var.impersonate_sa
    }
  EOF
}
