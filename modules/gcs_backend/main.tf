resource "google_project_service" "storage_api" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "state" {
  name          = var.bucket_name
  location      = var.bucket_location
  project       = var.project_id
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  depends_on = [google_project_service.storage_api]
}

resource "google_storage_bucket_object" "prefix_placeholder" {
  name    = format("%s/.keep", trim(var.state_prefix, "/"))
  content = "managed by terraform"
  bucket  = google_storage_bucket.state.name
}
