terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.40" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  # Naming helpers following: livgolf-{component_type}-{purpose}-{instance}-{env}
  vpc_name        = "${var.org_slug}-vpc-core-${var.instance_number}-${var.env_slug}"
  subnet_name     = "${var.org_slug}-snet-core-${var.instance_number}-${var.env_slug}"
  pods_range_name = "${var.org_slug}-snet-pods-${var.instance_number}-${var.env_slug}"
  svc_range_name  = "${var.org_slug}-snet-svcs-${var.instance_number}-${var.env_slug}"

  svpc_name       = "${var.org_slug}-vpc-svpc-${var.instance_number}-${var.env_slug}"

  psa_range_name  = "${var.org_slug}-vpc-psa-${var.instance_number}-${var.env_slug}"

  apigee_22_name  = "${var.org_slug}-vpc-apigee-a22-${var.instance_number}-${var.env_slug}"
  apigee_28_name  = "${var.org_slug}-vpc-apigee-a28-${var.instance_number}-${var.env_slug}"
}

# -------------------- VPC --------------------
resource "google_compute_network" "vpc" {
  name                    = local.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

# -------------------- Subnet (dual-stack, with secondaries) --------------------
resource "google_compute_subnetwork" "primary" {
  name          = local.subnet_name
  ip_cidr_range = var.subnet_primary_cidr
  region        = var.subnet_region
  network       = google_compute_network.vpc.id
  purpose       = "PRIVATE"
  stack_type    = "IPV4_IPV6"                  # dual-stack
  ipv6_access_type = "INTERNAL"                # internal IPv6
  private_ip_google_access = true              # enable Private Google Access (PGA)
  enable_flow_logs          = var.enable_flow_logs

  secondary_ip_range {
    range_name    = local.pods_range_name
    ip_cidr_range = var.subnet_secondary_pods_cidr
  }

  secondary_ip_range {
    range_name    = local.svc_range_name
    ip_cidr_range = var.subnet_secondary_services_cidr
  }
}

# -------------------- Serverless VPC Access Connector --------------------
resource "google_vpc_access_connector" "svpc" {
  name   = local.svpc_name
  region = var.subnet_region
  network = google_compute_network.vpc.name

  ip_cidr_range = var.svpc_cidr

  # Best practice values; tweak if needed
  min_throughput = 200  # Mbps
  max_throughput = 300  # Mbps
}

# -------------------- Private Service Access (PSA) --------------------
# Reserve an INTERNAL range for service networking peering (Cloud SQL, AlloyDB, etc.)
resource "google_compute_global_address" "psa" {
  name          = local.psa_range_name
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  address       = var.psa_address
  prefix_length = var.psa_prefix_length
  network       = google_compute_network.vpc.id
}

# Create the service networking connection that consumes the PSA range.
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "services/servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa.name]
}

# -------------------- Apigee reserved peering ranges --------------------
# These are RESERVED ONLY now; Apigee X creation will consume them later.
resource "google_compute_global_address" "apigee_a_22" {
  name          = local.apigee_22_name
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  address       = var.apigee_a_22_address
  prefix_length = var.apigee_a_22_prefix_length
  network       = google_compute_network.vpc.id
}

resource "google_compute_global_address" "apigee_a_28" {
  name          = local.apigee_28_name
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  address       = var.apigee_a_28_address
  prefix_length = var.apigee_a_28_prefix_length
  network       = google_compute_network.vpc.id
}
