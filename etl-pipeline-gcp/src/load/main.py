import os
import json
import requests
import logging
import functions_framework
from datetime import datetime
from google.cloud import storage
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# GCS bucket configuration
BUCKET_NAME = os.environ.get('GCS_BUCKET_NAME')
PROJECT_ID = os.environ.get('GCP_PROJECT_ID')
DATA_SOURCE_URL = os.environ.get('DATA_SOURCE_URL', 'https://jsonplaceholder.typicode.com/posts')

def download_data():
    """Download sample data from an API"""
    try:
        logger.info(f"Downloading data from {DATA_SOURCE_URL}")
        response = requests.get(DATA_SOURCE_URL)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logger.error(f"Error downloading data: {e}")
        raise

def upload_to_gcs(data):
    """Upload data to Google Cloud Storage"""
    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"data_{timestamp}.json"
        
        logger.info(f"Uploading data to gs://{BUCKET_NAME}/{filename}")
        
        storage_client = storage.Client(project=PROJECT_ID)
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(filename)
        
        # Convert data to JSON string and upload
        blob.upload_from_string(
            json.dumps(data),
            content_type='application/json'
        )
        
        logger.info(f"Data uploaded successfully to gs://{BUCKET_NAME}/{filename}")
        return filename
    except Exception as e:
        logger.error(f"Error uploading to GCS: {e}")
        raise

@functions_framework.http
def extract_and_upload(request):
    """
    Cloud Function entry point: extracts data and uploads to GCS
    """
    try:
        # Extract data
        data = download_data()
        
        # Upload to GCS
        uploaded_file = upload_to_gcs(data)
        
        return {
            "success": True,
            "message": f"Data uploaded to gs://{BUCKET_NAME}/{uploaded_file}",
            "file": uploaded_file
        }
    except Exception as e:
        logger.error(f"Extract and upload failed: {e}")
        return {"success": False, "error": str(e)}, 500