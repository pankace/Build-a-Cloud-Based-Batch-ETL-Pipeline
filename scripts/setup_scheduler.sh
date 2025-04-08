#!/bin/bash

# This script sets up a Cloud Scheduler job to trigger the extraction function on a regular schedule.

# Variables
PROJECT_ID="your-gcp-project-id"
LOCATION="us-central1"  # Change to your preferred location
FUNCTION_NAME="extract-function"  # Name of the Cloud Run function
SCHEDULE="every 24 hours"  # Change to your desired schedule
TIMEZONE="America/Los_Angeles"  # Change to your desired timezone

# Create the Cloud Scheduler job
gcloud scheduler jobs create http $FUNCTION_NAME-job \
    --schedule="$SCHEDULE" \
    --time-zone="$TIMEZONE" \
    --uri="https://$LOCATION-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/$PROJECT_ID/services/$FUNCTION_NAME:invoke" \
    --http-method=POST \
    --headers="Authorization=Bearer $(gcloud auth print-access-token)" \
    --message-body='{}' \
    --description="Trigger extraction function on a regular schedule" \
    --project="$PROJECT_ID"

echo "Cloud Scheduler job created successfully."