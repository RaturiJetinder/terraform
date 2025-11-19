locals {
  psa_range_parts  = split("/", var.psa_range_cidr)
  psa_range_base   = local.psa_range_parts[0]
  psa_range_prefix = tonumber(local.psa_range_parts[1])
}

resource "google_compute_network" "network" {
  name                            = var.network_name
  project                         = var.project_id
  auto_create_subnetworks         = false
  routing_mode                    = "GLOBAL"
  description                     = var.network_description
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "workload" {
  name                     = var.workload_subnet_name
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.network.id
  ip_cidr_range            = var.workload_subnet_cidr
  stack_type               = "IPV4_IPV6"
  ipv6_access_type         = "INTERNAL"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pods_secondary_range_name
    ip_cidr_range = var.pods_secondary_range_cidr
  }

  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_range_cidr
  }
}

resource "google_compute_subnetwork" "svpc" {
  name          = var.svpc_subnet_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.network.id
  ip_cidr_range = var.svpc_subnet_cidr
}

resource "google_vpc_access_connector" "svpc" {
  name           = var.svpc_connector_name
  project        = var.project_id
  region         = var.region
  network        = google_compute_network.network.name
  min_throughput = var.svpc_connector_min_throughput
  max_throughput = var.svpc_connector_max_throughput

  subnet {
    name = google_compute_subnetwork.svpc.name
  }
}

resource "google_compute_global_address" "psa_range" {
  name          = var.psa_range_name
  project       = var.project_id
  address       = local.psa_range_base
  prefix_length = local.psa_range_prefix
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  network       = google_compute_network.network.id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_range.name]
}
