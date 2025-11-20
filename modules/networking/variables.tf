variable "project_id" {
  description = "ID of the Google Cloud project where the networking resources are created."
  type        = string
}

variable "region" {
  description = "Region that hosts the regional subnets and Serverless VPC connector."
  type        = string
}

variable "environment" {
  description = "Short environment code (e.g. dev, stg, prod) used for tagging resources and names."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "network_description" {
  description = "Optional description applied to the VPC network."
  type        = string
  default     = ""
}

variable "workload_subnet_name" {
  description = "Name of the primary subnet that hosts compute workloads."
  type        = string
}

variable "workload_subnet_cidr" {
  description = "CIDR for the primary workload subnet."
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary range for GKE pods."
  type        = string
}

variable "pods_secondary_range_cidr" {
  description = "CIDR for the GKE pods secondary range."
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary range for GKE services."
  type        = string
}

variable "services_secondary_range_cidr" {
  description = "CIDR for the GKE services secondary range."
  type        = string
}

variable "svpc_subnet_name" {
  description = "Name of the subnet dedicated to the Serverless VPC Access connector."
  type        = string
}

variable "svpc_subnet_cidr" {
  description = "CIDR for the Serverless VPC Access connector subnet."
  type        = string
}

variable "svpc_connector_name" {
  description = "Name of the Serverless VPC Access connector."
  type        = string
}

variable "svpc_connector_min_throughput" {
  description = "Minimum throughput in Mbps for the Serverless VPC Access connector."
  type        = number
  default     = 200
}

variable "svpc_connector_max_throughput" {
  description = "Maximum throughput in Mbps for the Serverless VPC Access connector."
  type        = number
  default     = 300
}

variable "psa_range_name" {
  description = "Name of the allocated Private Service Access range."
  type        = string
}

variable "psa_range_cidr" {
  description = "CIDR for the Private Service Access range."
  type        = string
}

variable "internal_ipv4_ranges" {
  description = "List of IPv4 CIDR ranges that represent internal network space allowed for bidirectional traffic."
  type        = list(string)
}

variable "app_service_account_email" {
  description = "Service account email used by application workloads that need egress to Google APIs via the restricted VIP."
  type        = string
}

variable "health_check_target_tags" {
  description = "Network tags applied to instances that must be reachable by Google health checks (IPv4)."
  type        = list(string)
  default     = ["allow-health-checks"]
}

variable "health_check_ipv6_target_tags" {
  description = "Network tags applied to instances that must be reachable by Google health checks (IPv6)."
  type        = list(string)
  default     = ["allow-health-checks-ipv6"]
}
