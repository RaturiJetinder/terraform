resource "google_container_cluster" "primary" {
  provider = google-beta

  name     = var.cluster_name
  project  = var.project_id
  location = var.zone

  resource_labels = {
    environment = var.environment
    region      = var.region
  }

  network    = var.network
  subnetwork = var.subnetwork

  remove_default_node_pool = true
  initial_node_count       = 1
  networking_mode          = "VPC_NATIVE"

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr

    master_global_access_config {
      enabled = false
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER",
      "SCHEDULER",
      "CONTROLLER_MANAGER",
      "STORAGE",
    ]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "APISERVER",
      "SCHEDULER",
      "CONTROLLER_MANAGER",
      "STORAGE",
    ]

    managed_prometheus {
      enabled = true
    }
  }

  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  shielded_nodes {
    enabled = true
  }
}

resource "google_container_node_pool" "primary" {
  provider = google-beta

  name       = var.node_pool_name
  project    = var.project_id
  location   = var.zone
  cluster    = google_container_cluster.primary.id
  node_count = 2

  node_config {
    machine_type    = var.node_machine_type
    disk_size_gb    = var.node_disk_size_gb
    disk_type       = var.node_disk_type
    service_account = var.node_service_account

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      environment = var.environment
      region      = var.region
    }

    tags = var.node_network_tags
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_gke_hub_membership" "staging_fleet" {
  provider = google-beta

  membership_id = var.fleet_membership_id
  project       = var.project_id
  location      = "global"

  endpoint {
    gke_cluster {
      resource_link = google_container_cluster.primary.id
    }
  }
}

output "cluster_endpoint" {
  description = "Endpoint of the private GKE control plane."
  value       = google_container_cluster.primary.endpoint
}

output "node_pool_id" {
  description = "Resource ID of the managed node pool."
  value       = google_container_node_pool.primary.id
}

output "fleet_membership_name" {
  description = "Fleet membership resource name."
  value       = google_gke_hub_membership.staging_fleet.name
}
