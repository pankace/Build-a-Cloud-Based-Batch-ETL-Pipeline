resource "google_cloud_run_service" "extract" {
  name     = "extract-function"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/extract:latest"

        env {
          name  = "GCS_BUCKET"
          value = var.gcs_bucket
        }
      }
    }
  }
}

resource "google_cloud_run_service" "load" {
  name     = "load-function"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/load:latest"

        env {
          name  = "BQ_DATASET"
          value = var.bq_dataset
        }
        env {
          name  = "BQ_TABLE"
          value = var.bq_table
        }
      }
    }
  }
}

resource "google_storage_bucket" "data_bucket" {
  name     = var.gcs_bucket
  location = var.region
}

resource "google_cloud_scheduler_job" "extract_job" {
  name     = "extract-job"
  schedule = var.schedule
  time_zone = var.time_zone

  http_target {
    http_method = "POST"
    uri         = google_cloud_run_service.extract.status[0].url
    oidc_token {
      service_account_email = google_service_account.cloud_run_sa.email
    }
  }
}

resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

resource "google_project_iam_member" "cloud_run_invoker" {
  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

output "extract_function_url" {
  value = google_cloud_run_service.extract.status[0].url
}

output "load_function_url" {
  value = google_cloud_run_service.load.status[0].url
}

output "data_bucket_name" {
  value = google_storage_bucket.data_bucket.name
}