#!/bin/bash

# Set variables
PROJECT_ID="your-gcp-project-id"
REGION="your-region"
SERVICE_NAME="extract-function"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

# Build the Docker image
docker build -t $IMAGE_NAME ./src/extract_function

# Push the Docker image to Google Container Registry
docker push $IMAGE_NAME

# Deploy the Cloud Run service
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --project $PROJECT_ID

# Output the service URL
echo "Deployed $SERVICE_NAME to Cloud Run. Access it at:"
gcloud run services describe $SERVICE_NAME --region $REGION --format "value(status.url)"