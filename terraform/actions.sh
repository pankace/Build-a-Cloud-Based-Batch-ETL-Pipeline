
#!/bin/bash

# Set your project ID
PROJECT_ID=$1

echo "Importing existing resources from project $PROJECT_ID"

# Import the GCS bucket
terraform import google_storage_bucket.data_bucket $PROJECT_ID-data-bucket

# Import the BigQuery dataset
terraform import google_bigquery_dataset.etl_dataset $PROJECT_ID:etl_dataset

# Import the service account
terraform import google_service_account.etl_service_account projects/$PROJECT_ID/serviceAccounts/etl-service-account@$PROJECT_ID.iam.gserviceaccount.com

# Import the Pub/Sub topic
terraform import google_pubsub_topic.gcs_notification_topic projects/$PROJECT_ID/topics/gcs-notification-topic

# Try to import the Pub/Sub subscription if it exists
terraform import google_pubsub_subscription.subscription projects/$PROJECT_ID/subscriptions/gcs-notification-subscription || echo "Subscription might not exist yet, continuing..."

# Try to import the notification if it exists (this might be a bit tricky)
# For the notification, we'd need its ID, which can be complex to get programmatically
echo "Note: Storage notification might need manual import after we know its ID"

echo "Import completed. You may now run terraform plan to see what changes would be applied."