include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  environment = "stg"
}

terraform {
  source = "../../modules/networking"
}

inputs = {
  environment                   = local.environment
  network_name                  = "livgolf-vpc-shared-01-${local.environment}"
  network_description           = "Primary staging VPC for europe-west2 workloads"
  workload_subnet_name          = "livgolf-snet-workloads-01-${local.environment}"
  workload_subnet_cidr          = "10.64.0.0/23"
  pods_secondary_range_name     = "livgolf-snet-gke-pods-01-${local.environment}"
  pods_secondary_range_cidr     = "10.66.0.0/21"
  services_secondary_range_name = "livgolf-snet-gke-svcs-01-${local.environment}"
  services_secondary_range_cidr = "10.66.8.0/25"
  svpc_subnet_name              = "livgolf-snet-svpc-01-${local.environment}"
  svpc_subnet_cidr              = "10.70.0.0/27"
  svpc_connector_name           = "livgolf-sl-svpc-01-${local.environment}"
  svpc_connector_min_throughput = 200
  svpc_connector_max_throughput = 300
  psa_range_name                = "livgolf-snet-psa-01-${local.environment}"
  psa_range_cidr                = "10.71.0.0/17"
}
