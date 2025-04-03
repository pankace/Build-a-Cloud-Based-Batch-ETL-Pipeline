resource "google_cloud_scheduler_job" "etl_scheduler_job" {
  name             = "etl-trigger"
  description      = "Triggers the ETL extract service on a schedule"
  schedule         = "0 */6 * * *"  # Every 6 hours
  time_zone        = "UTC"
  region           = var.region
  attempt_deadline = "320s"

  http_target {
    http_method = "GET"
    uri         = google_cloud_run_v2_service.extract_service.uri
    
    oidc_token {
      service_account_email = google_service_account.etl_service_account.email
    }
  }
  
  # Add lifecycle block to handle existing job
  lifecycle {
    ignore_changes = [
      http_target[0].uri,
      http_target[0].oidc_token
    ]
  }
  
  depends_on = [google_project_service.services["cloudscheduler.googleapis.com"]]
}