variable "project_id" {
  description = "Project ID where the cluster will be created."
  type        = string
}

variable "region" {
  description = "Region of the cluster (used for defaults and fleet registration)."
  type        = string
}

variable "zone" {
  description = "Zonal location for the GKE cluster."
  type        = string
}

variable "environment" {
  description = "Environment suffix used for naming and labels (e.g., stg, prod)."
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster following naming conventions."
  type        = string
}

variable "node_pool_name" {
  description = "Name of the managed node pool."
  type        = string
}

variable "network" {
  description = "Self link of the VPC network to attach the cluster to."
  type        = string
}

variable "subnetwork" {
  description = "Self link of the subnet used for cluster nodes."
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Secondary range name reserved for pods."
  type        = string
}

variable "services_secondary_range_name" {
  description = "Secondary range name reserved for services."
  type        = string
}

variable "master_ipv4_cidr" {
  description = "/28 CIDR block for the private control plane endpoints."
  type        = string
  default     = "172.16.0.0/28"
}

variable "release_channel" {
  description = "GKE release channel for the control plane and nodes."
  type        = string
  default     = "REGULAR"
}

variable "node_machine_type" {
  description = "Machine type for the node pool workers."
  type        = string
  default     = "n2-custom-28-83968"
}

variable "node_disk_size_gb" {
  description = "Size of the node boot disks in GB."
  type        = number
  default     = 200
}

variable "node_disk_type" {
  description = "Disk type for the node pool."
  type        = string
  default     = "pd-balanced"
}

variable "node_service_account" {
  description = "Service account email for nodes. Uses the default Compute Engine service account when null."
  type        = string
  default     = null
}

variable "node_network_tags" {
  description = "Network tags applied to node VMs."
  type        = list(string)
  default     = []
}

variable "fleet_membership_id" {
  description = "ID for registering the cluster into the fleet."
  type        = string
}
