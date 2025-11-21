include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  environment = "stg"
  region      = include.root.locals.default_region
  project_id  = include.root.locals.project_id
  zone        = "${local.region}-a"
}

dependency "networking" {
  config_path = ".."

  mock_outputs = {
    network_id                   = "mock-network"
    workload_subnet_self_link    = "mock-subnet"
    pods_secondary_range_name    = "mock-pods-range"
    services_secondary_range_name = "mock-services-range"
  }
}

terraform {
  source = "../../../modules/gke"
}

inputs = {
  project_id                  = local.project_id
  region                      = local.region
  zone                        = local.zone
  environment                 = local.environment
  cluster_name                = "livgolf-k8s-core-01-${local.environment}"
  node_pool_name              = "livgolf-k8s-pool-01-${local.environment}"
  network                     = dependency.networking.outputs.network_id
  subnetwork                  = dependency.networking.outputs.workload_subnet_self_link
  pods_secondary_range_name   = dependency.networking.outputs.pods_secondary_range_name
  services_secondary_range_name = dependency.networking.outputs.services_secondary_range_name
  master_ipv4_cidr            = "172.16.0.0/28"
  release_channel             = "REGULAR"
  node_machine_type           = "n2-custom-28-83968"
  node_disk_size_gb           = 200
  node_disk_type              = "pd-balanced"
  node_network_tags           = ["allow-health-checks"]
  fleet_membership_id         = "livgolf-k8s-core-01-${local.environment}"
}
