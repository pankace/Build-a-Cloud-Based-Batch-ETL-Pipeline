#!/bin/bash

# Set your project ID and region
PROJECT_ID=$1
REGION=${2:-us-central1}  # Default to us-central1 if not provided

echo "Importing existing resources from project $PROJECT_ID in region $REGION"

# Import the GCS bucket (with error handling)
echo "Attempting to import GCS bucket: ${PROJECT_ID}-data-bucket"
terraform import google_storage_bucket.data_bucket ${PROJECT_ID}-data-bucket || echo "Bucket import failed, might not exist yet"

# Import the BigQuery dataset
echo "Attempting to import BigQuery dataset: ${PROJECT_ID}:etl_dataset"
terraform import google_bigquery_dataset.etl_dataset ${PROJECT_ID}:etl_dataset || echo "Dataset import failed, might not exist yet"

# Import the BigQuery table if it exists
echo "Attempting to import BigQuery table: ${PROJECT_ID}:etl_dataset.posts"
terraform import google_bigquery_table.etl_table ${PROJECT_ID}:etl_dataset.posts || echo "Table import failed, might not exist yet"

# Import the service account
echo "Attempting to import service account"
terraform import google_service_account.etl_service_account projects/${PROJECT_ID}/serviceAccounts/etl-service-account@${PROJECT_ID}.iam.gserviceaccount.com || echo "Service account import failed, might not exist yet"

# Import the Pub/Sub topic
echo "Attempting to import Pub/Sub topic"
terraform import google_pubsub_topic.gcs_notification_topic projects/${PROJECT_ID}/topics/gcs-notification-topic || echo "Topic import failed, might not exist yet"

# Import Cloud Run services - CRITICAL to fix the 409 errors
echo "Attempting to import Cloud Run extract service"
terraform import google_cloud_run_v2_service.extract_service locations/${REGION}/services/extract-service || echo "Extract service import failed, might not exist yet"

echo "Attempting to import Cloud Run load service"
terraform import google_cloud_run_v2_service.load_service locations/${REGION}/services/load-service || echo "Load service import failed, might not exist yet"

# Import the Cloud Run job if it exists
echo "Attempting to import Cloud Run job"
terraform import google_cloud_run_v2_job.load_job locations/${REGION}/jobs/load-job || echo "Load job import failed, might not exist yet"

# Try to import the Pub/Sub subscription if it exists
echo "Attempting to import Pub/Sub subscription"
terraform import google_pubsub_subscription.subscription projects/${PROJECT_ID}/subscriptions/gcs-notification-subscription || echo "Subscription might not exist yet, continuing..."

# Try to import the storage notification if it exists
echo "Attempting to import Storage notification"
terraform import google_storage_notification.notification ${PROJECT_ID}-data-bucket/notificationConfigs/1 || echo "Storage notification import failed, might not exist yet"

terraform state rm google_bigquery_dataset.etl_dataset
terraform state rm google_cloud_run_v2_service.extract_service
terraform state rm google_cloud_run_v2_service.load_service
echo "Import completed. Now terraform plan will show what changes are needed."