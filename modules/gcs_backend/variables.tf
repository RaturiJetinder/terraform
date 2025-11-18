variable "project_id" {
  description = "Google Cloud project where the backend bucket will live"
  type        = string
}

variable "bucket_name" {
  description = "Name of the state bucket"
  type        = string
}

variable "bucket_location" {
  description = "Location for the bucket"
  type        = string
  default     = "us"
}

variable "default_region" {
  description = "Default region for provider configuration"
  type        = string
  default     = "us-central1"
}

variable "state_prefix" {
  description = "Prefix to reserve for Terraform state"
  type        = string
  default     = "terraform/state"
}

variable "force_destroy" {
  description = "Whether to allow force destroy"
  type        = bool
  default     = false
}
