output "bucket_name" {
  description = "Name of the created or managed GCS bucket"
  value       = google_storage_bucket.state.name
}

output "bucket_self_link" {
  description = "Self link of the backend bucket"
  value       = google_storage_bucket.state.self_link
}
