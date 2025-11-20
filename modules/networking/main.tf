locals {
  psa_range_parts  = split("/", var.psa_range_cidr)
  psa_range_base   = local.psa_range_parts[0]
  psa_range_prefix = tonumber(local.psa_range_parts[1])
  firewall_names = {
    internal_ingress       = format("livgolf-fw-intingress-01-%s", var.environment)
    internal_egress        = format("livgolf-fw-integress-01-%s", var.environment)
    internal_ingress_ipv6  = format("livgolf-fw-intingress6-01-%s", var.environment)
    internal_egress_ipv6   = format("livgolf-fw-integress6-01-%s", var.environment)
    health_checks          = format("livgolf-fw-healthchecks-01-%s", var.environment)
    health_checks_ipv6     = format("livgolf-fw-healthchecks6-01-%s", var.environment)
    google_apis_egress     = format("livgolf-fw-googleapis-01-%s", var.environment)
    deny_all_ingress       = format("livgolf-fw-denyingress-01-%s", var.environment)
    deny_all_egress        = format("livgolf-fw-denyegress-01-%s", var.environment)
    deny_all_ingress_ipv6  = format("livgolf-fw-denyingress6-01-%s", var.environment)
    deny_all_egress_ipv6   = format("livgolf-fw-denyegress6-01-%s", var.environment)
  }

  health_check_source_ranges      = ["35.191.0.0/16", "130.211.0.0/22"]
  health_check_ipv6_source_ranges = ["2600:2d00:1:b029::/64", "2600:2d00:1:1::/64"]
  google_api_destination_ranges   = ["199.36.153.4/30", "199.36.153.8/30"]
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

resource "google_compute_firewall" "allow_internal_ingress" {
  name      = local.firewall_names.internal_ingress
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 1000
  direction = "INGRESS"

  source_ranges = var.internal_ipv4_ranges

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_internal_egress" {
  name      = local.firewall_names.internal_egress
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 1000
  direction = "EGRESS"

  destination_ranges = var.internal_ipv4_ranges

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_internal_ingress_ipv6" {
  name      = local.firewall_names.internal_ingress_ipv6
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 1000
  direction = "INGRESS"

  source_ranges = [google_compute_subnetwork.workload.ipv6_cidr_range]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_internal_egress_ipv6" {
  name      = local.firewall_names.internal_egress_ipv6
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 1000
  direction = "EGRESS"

  destination_ranges = [google_compute_subnetwork.workload.ipv6_cidr_range]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_health_checks" {
  name      = local.firewall_names.health_checks
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 1000
  direction = "INGRESS"

  source_ranges = local.health_check_source_ranges
  target_tags   = var.health_check_target_tags

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "4221"]
  }
}

resource "google_compute_firewall" "allow_health_checks_ipv6" {
  name      = local.firewall_names.health_checks_ipv6
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 1000
  direction = "INGRESS"

  source_ranges = local.health_check_ipv6_source_ranges
  target_tags   = var.health_check_ipv6_target_tags

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "4221"]
  }
}

resource "google_compute_firewall" "allow_google_apis_egress" {
  name      = local.firewall_names.google_apis_egress
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 1000
  direction = "EGRESS"

  destination_ranges      = local.google_api_destination_ranges
  target_service_accounts = [var.app_service_account_email]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

resource "google_compute_firewall" "deny_all_ingress" {
  name      = local.firewall_names.deny_all_ingress
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 65534
  direction = "INGRESS"

  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "deny_all_egress" {
  name      = local.firewall_names.deny_all_egress
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 65534
  direction = "EGRESS"

  destination_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "deny_all_ingress_ipv6" {
  name      = local.firewall_names.deny_all_ingress_ipv6
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 65534
  direction = "INGRESS"

  source_ranges = ["::/0"]

  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "deny_all_egress_ipv6" {
  name      = local.firewall_names.deny_all_egress_ipv6
  project   = var.project_id
  network   = google_compute_network.network.name
  priority  = 65534
  direction = "EGRESS"

  destination_ranges = ["::/0"]

  deny {
    protocol = "all"
  }
}
