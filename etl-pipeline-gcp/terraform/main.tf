terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create GCS bucket for data storage
resource "google_storage_bucket" "data_bucket" {
  name     = "${var.project_id}-data-bucket"
  location = var.region
  force_destroy = true
}

# Create BigQuery dataset
resource "google_bigquery_dataset" "etl_dataset" {
  dataset_id  = var.bigquery_dataset_id
  description = "Dataset for ETL pipeline data"
  location    = var.region
}

# Create BigQuery table
resource "google_bigquery_table" "etl_table" {
  dataset_id = google_bigquery_dataset.etl_dataset.dataset_id
  table_id   = var.bigquery_table_id

  schema = <<EOF
[
  {
    "name": "userId",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "title",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "body",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}

# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "artifactregistry.googleapis.com"
  ])
  project = var.project_id
  service = each.value
}

# Service account for the Cloud Run services
resource "google_service_account" "etl_service_account" {
  account_id   = "etl-service-account"
  display_name = "ETL Pipeline Service Account"
}

# Grant permissions to service account
resource "google_project_iam_binding" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.etl_service_account.email}"
  ]
}

resource "google_project_iam_binding" "bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  members = [
    "serviceAccount:${google_service_account.etl_service_account.email}"
  ]
}

# Deploy Extract function to Cloud Run
resource "google_cloud_run_v2_service" "extract_service" {
  name     = "extract-service"
  location = var.region
  
  template {
    containers {
      image = var.extract_image
      
      env {
        name  = "GCS_BUCKET_NAME"
        value = google_storage_bucket.data_bucket.name
      }
      
      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }
      
      env {
        name  = "DATA_SOURCE_URL"
        value = var.data_source_url
      }
    }
    
    service_account = google_service_account.etl_service_account.email
  }
  
  depends_on = [google_project_service.services["run.googleapis.com"]]
}

# Deploy Load function to Cloud Run
resource "google_cloud_run_v2_service" "load_service" {
  name     = "load-service"
  location = var.region
  
  template {
    containers {
      image = var.load_image
      
      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }
      
      env {
        name  = "BIGQUERY_DATASET_ID"
        value = google_bigquery_dataset.etl_dataset.dataset_id
      }
      
      env {
        name  = "BIGQUERY_TABLE_ID"
        value = google_bigquery_table.etl_table.table_id
      }
    }
    
    service_account = google_service_account.etl_service_account.email
  }
  
  depends_on = [google_project_service.services["run.googleapis.com"]]
}

# Set up the GCS trigger for the Load function
resource "google_cloud_run_v2_job" "load_job" {
  name     = "load-job"
  location = var.region
  
  template {
    template {
      containers {
        image = var.load_image
        
        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        
        env {
          name  = "BIGQUERY_DATASET_ID"
          value = google_bigquery_dataset.etl_dataset.dataset_id
        }
        
        env {
          name  = "BIGQUERY_TABLE_ID"
          value = google_bigquery_table.etl_table.table_id
        }
      }
      
      service_account = google_service_account.etl_service_account.email
    }
  }
  
  depends_on = [google_project_service.services["run.googleapis.com"]]
}

# Create notification for new files in the bucket
resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.data_bucket.name
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE"]
  topic          = google_pubsub_topic.gcs_notification_topic.id
  
  depends_on = [google_pubsub_topic_iam_binding.binding]
}

# Create a Pub/Sub topic for GCS notifications
resource "google_pubsub_topic" "gcs_notification_topic" {
  name = "gcs-notification-topic"
}

# Grant permission to GCS to publish to this topic
resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = google_pubsub_topic.gcs_notification_topic.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"]
}

# Create a Pub/Sub subscription to trigger the Cloud Run load function
resource "google_pubsub_subscription" "subscription" {
  name  = "gcs-notification-subscription"
  topic = google_pubsub_topic.gcs_notification_topic.id
  
  push_config {
    push_endpoint = google_cloud_run_v2_service.load_service.uri
    
    oidc_token {
      service_account_email = google_service_account.etl_service_account.email
    }
  }
  
  depends_on = [google_cloud_run_v2_service.load_service]
}

# Allow public access to the extract function
resource "google_cloud_run_service_iam_binding" "extract_public" {
  location = var.region
  service  = google_cloud_run_v2_service.extract_service.name
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}