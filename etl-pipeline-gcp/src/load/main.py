import os
import json
import logging
import functions_framework
from google.cloud import storage, bigquery
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
PROJECT_ID = os.environ.get('GCP_PROJECT_ID')
DATASET_ID = os.environ.get('BIGQUERY_DATASET_ID')
TABLE_ID = os.environ.get('BIGQUERY_TABLE_ID')

def load_data_to_bigquery(bucket_name, file_name):
    """Load data from GCS to BigQuery"""
    try:
        logger.info(f"Processing file gs://{bucket_name}/{file_name}")
        
        # Download the file from GCS
        storage_client = storage.Client(project=PROJECT_ID)
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        content = blob.download_as_string()
        
        # Parse the JSON data
        data = json.loads(content)
        
        # Load data into BigQuery
        bigquery_client = bigquery.Client(project=PROJECT_ID)
        table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
        
        # Check if data is a list (multiple rows)
        if isinstance(data, list):
            errors = bigquery_client.insert_rows_json(table_ref, data)
            if errors:
                logger.error(f"Errors inserting rows: {errors}")
                raise Exception(f"Failed to insert rows: {errors}")
            logger.info(f"Successfully loaded {len(data)} rows into {table_ref}")
        else:
            # Single item
            errors = bigquery_client.insert_rows_json(table_ref, [data])
            if errors:
                logger.error(f"Errors inserting row: {errors}")
                raise Exception(f"Failed to insert row: {errors}")
            logger.info(f"Successfully loaded 1 row into {table_ref}")
            
        return True
    except Exception as e:
        logger.error(f"Error loading data to BigQuery: {e}")
        raise

@functions_framework.http
def load_to_bigquery(request):
    """
    Cloud Function entry point: loads data from GCS to BigQuery
    """
    try:
        # For Cloud Storage trigger events
        if request.method == 'POST':
            request_json = request.get_json(silent=True)
            
            if request_json and 'message' in request_json:
                # Cloud Pub/Sub message format
                pubsub_message = request_json['message']
                
                if 'data' in pubsub_message:
                    import base64
                    event_data = json.loads(base64.b64decode(pubsub_message['data']).decode('utf-8'))
                    bucket_name = event_data['bucket']
                    file_name = event_data['name']
                    load_data_to_bigquery(bucket_name, file_name)
                    
                    return {"success": True, "message": "Data loaded to BigQuery successfully"}
        
        return {"success": False, "error": "Invalid request format"}, 400
    except Exception as e:
        logger.error(f"Load to BigQuery failed: {e}")
        return {"success": False, "error": str(e)}, 500