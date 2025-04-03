output "extract_service_url" {
  value = google_cloud_run_v2_service.extract_service.uri
}

output "load_service_url" {
  value = google_cloud_run_v2_service.load_service.uri
}

output "gcs_bucket_name" {
  value = google_storage_bucket.data_bucket.name
}

output "bigquery_dataset_table" {
  value = "${var.project_id}:${google_bigquery_dataset.etl_dataset.dataset_id}.${google_bigquery_table.etl_table.table_id}"
}