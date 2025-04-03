# Create a Cloud Scheduler job to trigger the extract function
resource "google_cloud_scheduler_job" "etl_scheduler_job" {
  name             = "etl-trigger"
  description      = "Trigger ETL pipeline daily"
  schedule         = "0 0 * * *"  # Run daily at midnight
  time_zone        = "UTC"
  attempt_deadline = "320s"

  http_target {
    uri         = google_cloud_run_v2_service.extract_service.uri
    http_method = "GET"
    oidc_token {
      service_account_email = google_service_account.etl_service_account.email
    }
  }
  
  depends_on = [google_project_service.services["cloudscheduler.googleapis.com"]]
}