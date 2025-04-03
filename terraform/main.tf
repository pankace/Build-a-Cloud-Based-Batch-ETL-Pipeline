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

# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "artifactregistry.googleapis.com",
    "pubsub.googleapis.com"
  ])
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# GCS Bucket for data storage
resource "google_storage_bucket" "data_bucket" {
  name          = "${var.project_id}-data-bucket"
  location      = var.region
  force_destroy = true
  
  lifecycle {
    ignore_changes = [
      name,
      location
    ]
  }
}

# BigQuery Dataset
resource "google_bigquery_dataset" "etl_dataset" {
  dataset_id  = var.bigquery_dataset_id
  friendly_name = "ETL Dataset"
  description = "Dataset for ETL pipeline data"
  location    = var.region
  delete_contents_on_destroy = false
  
  lifecycle {
    ignore_changes = [
      dataset_id,
      location
    ]
  }
}

# BigQuery Table
resource "google_bigquery_table" "etl_table" {
  dataset_id = google_bigquery_dataset.etl_dataset.dataset_id
  table_id   = var.bigquery_table_id
  deletion_protection = false

  schema = jsonencode([
    {
      name = "userId",
      type = "INTEGER",
      mode = "NULLABLE"
    },
    {
      name = "id",
      type = "INTEGER",
      mode = "NULLABLE"
    },
    {
      name = "title",
      type = "STRING",
      mode = "NULLABLE"
    },
    {
      name = "body",
      type = "STRING",
      mode = "NULLABLE"
    },
    {
      name = "processedAt",
      type = "TIMESTAMP",
      mode = "NULLABLE"
    }
  ])

  lifecycle {
    ignore_changes = [
      schema,
      table_id
    ]
  }
}

# Service Account for ETL operations
resource "google_service_account" "etl_service_account" {
  account_id   = "etl-service-account"
  display_name = "ETL Pipeline Service Account"
  
  lifecycle {
    ignore_changes = [
      account_id,
      display_name
    ]
  }
}

# Grant Storage Admin permissions to service account
resource "google_project_iam_binding" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.etl_service_account.email}"
  ]
}

# Grant BigQuery Admin permissions to service account
resource "google_project_iam_binding" "bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  members = [
    "serviceAccount:${google_service_account.etl_service_account.email}"
  ]
}

# Pub/Sub Topic for GCS notifications
resource "google_pubsub_topic" "gcs_notification_topic" {
  name = "gcs-notification-topic"
  
  lifecycle {
    ignore_changes = [
      name
    ]
  }
  
  depends_on = [google_project_service.services["pubsub.googleapis.com"]]
}

# Grant permissions for GCS to publish to Pub/Sub
resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = google_pubsub_topic.gcs_notification_topic.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"]
}

# Extract Service (Cloud Run)
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
      
      env {
        name  = "PUBSUB_TOPIC"
        value = google_pubsub_topic.gcs_notification_topic.id
      }
    }
    
    service_account = google_service_account.etl_service_account.email
  }
  
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].service_account,
      client,
      client_version
    ]
  }
  
  depends_on = [google_project_service.services["run.googleapis.com"]]
}

# Load Service (Cloud Run)
# Load Service (Cloud Run)
resource "google_cloud_run_v2_service" "load_service" {
  name     = "load-service"
  location = var.region
  
  template {
    containers {
      image = var.load_image
      
      # Explicitly set the PORT environment variable
      env {
        name  = "PORT"
        value = "8080"
      }
      
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
      
      env {
        name  = "GCS_BUCKET"
        value = google_storage_bucket.data_bucket.name
      }
      
      # Add startup probe to give the container more time to initialize
      startup_probe {
        initial_delay_seconds = 10
        timeout_seconds = 3
        period_seconds = 5
        failure_threshold = 10
        
        http_get {
          path = "/"
          port = 8080
        }
      }
    }
    
    service_account = google_service_account.etl_service_account.email
    
    # Increase timeout for container startup
    max_instance_request_concurrency = 1
    timeout = "300s"
  }
  
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].service_account,
      client,
      client_version
    ]
  }
  
  depends_on = [google_project_service.services["run.googleapis.com"]]
}

# GCS Notification Configuration
resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.data_bucket.name
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE"]
  topic          = google_pubsub_topic.gcs_notification_topic.id
  
  depends_on = [google_pubsub_topic_iam_binding.binding]
  
  lifecycle {
    ignore_changes = [
      bucket,
      topic
    ]
  }
}

# Pub/Sub Subscription for Load Service
resource "google_pubsub_subscription" "subscription" {
  name  = "gcs-notification-subscription"
  topic = google_pubsub_topic.gcs_notification_topic.id
  
  push_config {
    push_endpoint = google_cloud_run_v2_service.load_service.uri
    
    oidc_token {
      service_account_email = google_service_account.etl_service_account.email
    }
  }
  
  lifecycle {
    ignore_changes = [
      name,
      topic,
      push_config
    ]
  }
  
  depends_on = [google_cloud_run_v2_service.load_service]
}

# Optional: Cloud Run Job for scheduled or manual load operations
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
  
  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image
    ]
  }
  
  depends_on = [google_project_service.services["run.googleapis.com"]]
}

# Allow public access to the extract function
resource "google_cloud_run_service_iam_binding" "extract_public" {
  location = var.region
  service  = google_cloud_run_v2_service.extract_service.name
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}