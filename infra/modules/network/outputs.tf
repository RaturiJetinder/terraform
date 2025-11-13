output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "vpc_self_link" {
  value = google_compute_network.vpc.self_link
}

output "subnet_name" {
  value = google_compute_subnetwork.primary.name
}

output "subnet_self_link" {
  value = google_compute_subnetwork.primary.self_link
}

output "pods_range_name" {
  value = google_compute_subnetwork.primary.secondary_ip_range[0].range_name
}

output "services_range_name" {
  value = google_compute_subnetwork.primary.secondary_ip_range[1].range_name
}

output "svpc_connector_name" {
  value = google_vpc_access_connector.svpc.name
}

output "psa_reserved_range_name" {
  value = google_compute_global_address.psa.name
}

output "apigee_reserved_ranges" {
  value = {
    a22 = google_compute_global_address.apigee_a_22.name
    a28 = google_compute_global_address.apigee_a_28.name
  }
}
