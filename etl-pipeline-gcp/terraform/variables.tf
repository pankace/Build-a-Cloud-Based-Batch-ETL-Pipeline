variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
}

variable "region" {
  description = "The region where the Cloud Run services will be deployed"
  type        = string
  default     = "us-central1"
}

variable "gcs_bucket_name" {
  description = "The name of the Google Cloud Storage bucket"
  type        = string
}

variable "bigquery_dataset" {
  description = "The BigQuery dataset where data will be loaded"
  type        = string
}

variable "bigquery_table" {
  description = "The BigQuery table where data will be loaded"
  type        = string
}

variable "cloud_run_image_extract" {
  description = "The Docker image for the extract Cloud Run function"
  type        = string
}

variable "cloud_run_image_load" {
  description = "The Docker image for the load Cloud Run function"
  type        = string
}

variable "scheduler_frequency" {
  description = "The frequency for the Cloud Scheduler job (e.g., 'every 1 hours')"
  type        = string
  default     = "every 1 hours"
}