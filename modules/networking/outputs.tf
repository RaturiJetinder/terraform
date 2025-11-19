output "network_id" {
  description = "ID of the created VPC network."
  value       = google_compute_network.network.id
}

output "workload_subnet_self_link" {
  description = "Self link of the primary workload subnet."
  value       = google_compute_subnetwork.workload.self_link
}

output "pods_secondary_range_name" {
  description = "Name of the pods secondary range for referencing in GKE clusters."
  value       = google_compute_subnetwork.workload.secondary_ip_range[0].range_name
}

output "services_secondary_range_name" {
  description = "Name of the services secondary range for referencing in GKE clusters."
  value       = google_compute_subnetwork.workload.secondary_ip_range[1].range_name
}

output "svpc_connector_id" {
  description = "ID of the Serverless VPC Access connector."
  value       = google_vpc_access_connector.svpc.id
}

output "psa_connection_id" {
  description = "ID of the private service access connection."
  value       = google_service_networking_connection.private_service_access.id
}
