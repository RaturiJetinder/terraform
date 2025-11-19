variable "project_id" {
  description = "Google Cloud project where the backend bucket will live"
  type        = string
}

variable "bucket_name" {
  description = <<DESC
Name of the Terraform state bucket. Must follow the livgolf naming convention:
livgolf-{component_type}-{purpose}-{instance_number}-{environment}
DESC
  type        = string

  validation {
    condition     = can(regex("^livgolf-[a-z0-9]+-[a-z0-9]+-[0-9]{2}-[a-z0-9]+$", var.bucket_name))
    error_message = "Bucket names must match livgolf-{component_type}-{purpose}-{instance_number}-{environment} and stay lowercase alphanumeric with hyphens."
  }

  validation {
    condition = can(element(split("-", var.bucket_name), 1)) && contains([
      "vm", "cont", "k8s", "sl", "dataproc", "run", "df",
      "gcs", "disk", "filestore", "dl",
      "sql", "bq", "nosql", "cache",
      "vpc", "snet", "fw", "lb", "rt", "vpn",
      "pubsub", "etl", "wf",
      "log", "dash", "alert",
      "iam", "kms", "secret",
      "api", "dns", "cdn", "bck"
    ], element(split("-", var.bucket_name), 1))

    error_message = "Component type (second token) must use one of the approved codes such as gcs, vpc, sql, etc."
  }
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
