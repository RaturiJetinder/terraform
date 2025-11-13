include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  project_id    = local.env.project_id
  region        = local.env.region             # provider region (not strictly used by network)
  env_slug      = local.env.env_slug           # "staging"
  instance_number = "01"
  org_slug      = "livgolf"

  # 4.1 Primary subnet + secondaries (us-central1)
  subnet_region                 = "us-central1"
  subnet_primary_cidr           = "10.64.0.0/22"
  subnet_secondary_pods_cidr    = "10.66.0.0/19"
  subnet_secondary_services_cidr= "10.66.32.0/24"

  # 4.2 SVPC connector
  svpc_cidr = "10.70.0.0/24"

  # 4.3 PSA
  psa_address        = "10.71.0.0"
  psa_prefix_length  = 16

  # 4.4 Apigee reserved ranges (Instance A)
  apigee_a_22_address        = "10.70.128.0"
  apigee_a_22_prefix_length  = 22
  apigee_a_28_address        = "10.70.192.0"
  apigee_a_28_prefix_length  = 28

  enable_flow_logs = false

  # Provider impersonation is injected at root via generated provider.tf
  # (env.hcl should export impersonate_sa)
  # See root live/terragrunt.hcl and env.hcl.
}
