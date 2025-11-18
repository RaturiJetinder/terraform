module "backend" {
  source = "../modules/gcs_backend"

  project_id     = var.project_id
  bucket_name    = var.bucket_name
  bucket_location= var.bucket_location
  default_region = var.default_region
  force_destroy  = var.force_destroy
  state_prefix   = var.state_prefix
}
