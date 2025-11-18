variable "project_id" {
  description = "Target Google Cloud project ID"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Terraform state bucket"
  type        = string
}

variable "bucket_location" {
  description = "Location for the state bucket"
  type        = string
  default     = "us"
}

variable "default_region" {
  description = "Default region for the Google provider"
  type        = string
  default     = "us-central1"
}

variable "force_destroy" {
  description = "Whether to force destroy the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "state_prefix" {
  description = "Prefix to reserve in the bucket for Terraform state files"
  type        = string
  default     = "terraform/state"
}
