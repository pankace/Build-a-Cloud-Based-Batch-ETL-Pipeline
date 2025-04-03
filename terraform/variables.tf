variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_number" {
  description = "GCP Project Number"
  type        = string
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
  type        = string
}

variable "bigquery_dataset_id" {
  description = "BigQuery Dataset ID"
  default     = "etl_dataset"
  type        = string
}

variable "bigquery_table_id" {
  description = "BigQuery Table ID"
  default     = "data_table"
  type        = string
}

variable "extract_image" {
  description = "Docker image for extract function"
  type        = string
}

variable "load_image" {
  description = "Docker image for load function"
  type        = string
}

variable "data_source_url" {
  description = "URL to fetch data from"
  default     = "https://jsonplaceholder.typicode.com/posts"
  type        = string
}