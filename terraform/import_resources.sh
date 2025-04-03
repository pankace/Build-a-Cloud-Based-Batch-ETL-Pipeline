
#!/bin/bash
#!/bin/bash

# Set your project ID
PROJECT_ID=$1

echo "Importing existing resources from project $PROJECT_ID"

# Import the GCS bucket (with error handling)
echo "Attempting to import GCS bucket: ${PROJECT_ID}-data-bucket"
terraform import google_storage_bucket.data_bucket ${PROJECT_ID}-data-bucket || echo "Bucket import failed, might not exist yet"

# Import the BigQuery dataset
echo "Attempting to import BigQuery dataset: ${PROJECT_ID}:etl_dataset"
terraform import google_bigquery_dataset.etl_dataset ${PROJECT_ID}:etl_dataset || echo "Dataset import failed, might not exist yet"

# Import the service account
echo "Attempting to import service account"
terraform import google_service_account.etl_service_account projects/${PROJECT_ID}/serviceAccounts/etl-service-account@${PROJECT_ID}.iam.gserviceaccount.com || echo "Service account import failed, might not exist yet"

# Import the Pub/Sub topic
echo "Attempting to import Pub/Sub topic"
terraform import google_pubsub_topic.gcs_notification_topic projects/${PROJECT_ID}/topics/gcs-notification-topic || echo "Topic import failed, might not exist yet"

# Try to import the Pub/Sub subscription if it exists
echo "Attempting to import Pub/Sub subscription"
terraform import google_pubsub_subscription.subscription projects/${PROJECT_ID}/subscriptions/gcs-notification-subscription || echo "Subscription might not exist yet, continuing..."

echo "Import completed. Now terraform plan will show what changes are needed."