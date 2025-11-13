variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Primary region (e.g., us-central1)"
  type        = string
}

variable "env_slug" {
  description = "Environment slug (e.g., dev|staging|prod)"
  type        = string
}

variable "instance_number" {
  description = "Two-digit instance code to keep names stable (e.g., 01)"
  type        = string
  default     = "01"
}

variable "org_slug" {
  description = "Org/product prefix for names"
  type        = string
  default     = "livgolf"
}

# ---------- VPC & Subnet CIDRs ----------
variable "vpc_cidr_primary" {
  description = "(Not used directly; custom-mode VPC has no primary CIDR) Kept only for documentation."
  type        = string
  default     = null
}

variable "subnet_primary_cidr" {
  description = "Primary subnet /22 for VMs/Dataflow (e.g., 10.64.0.0/22)"
  type        = string
}

variable "subnet_secondary_pods_cidr" {
  description = "Secondary range for GKE Pods (e.g., 10.66.0.0/19)"
  type        = string
}

variable "subnet_secondary_services_cidr" {
  description = "Secondary range for GKE Services (e.g., 10.66.32.0/24)"
  type        = string
}

variable "subnet_region" {
  description = "Region for the primary subnet (e.g., us-central1)"
  type        = string
}

# ---------- Serverless VPC Connector ----------
variable "svpc_cidr" {
  description = "Connector /24 (e.g., 10.70.0.0/24)"
  type        = string
}

# ---------- Private Service Access ----------
variable "psa_address" {
  description = "Starting address for PSA allocated range (e.g., 10.71.0.0)"
  type        = string
}
variable "psa_prefix_length" {
  description = "Prefix length for PSA allocated range (e.g., 16)"
  type        = number
  default     = 16
}

# ---------- Apigee reserved ranges ----------
variable "apigee_a_22_address" {
  description = "Apigee instance A reserved /22 (e.g., 10.70.128.0)"
  type        = string
}
variable "apigee_a_22_prefix_length" {
  description = "Apigee /22 prefix length"
  type        = number
  default     = 22
}

variable "apigee_a_28_address" {
  description = "Apigee instance A reserved /28 (e.g., 10.70.192.0)"
  type        = string
}
variable "apigee_a_28_prefix_length" {
  description = "Apigee /28 prefix length"
  type        = number
  default     = 28
}

# ---------- Optional toggles ----------
variable "enable_flow_logs" {
  description = "Enable VPC flow logs on the subnet"
  type        = bool
  default     = false
}
