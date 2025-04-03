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
  
  # Better lifecycle configuration to handle existing resource
  lifecycle {
    ignore_changes = [
      name,           # Ignore name changes to handle existing job
      http_target,    # Ignore ALL http_target changes (more comprehensive)
      description,    # In case description was changed manually
      schedule        # In case schedule was changed manually
    ]
    create_before_destroy = false
  }
  
  depends_on = [google_project_service.services["cloudscheduler.googleapis.com"]]
}