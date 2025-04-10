import json
import functions_framework
from google.cloud import bigquery
from google.cloud import storage

@functions_framework.http
def gcs_to_bigquery(request):
    try:
        # Get request data
        request_json = request.get_json(silent=True)
        if not request_json:
            return "No JSON data received", 400
            
        bucket_name = request_json.get("bucket")
        file_name = request_json.get("name")
        
        if not bucket_name or not file_name:
            return "Missing required fields: bucket and name", 400

        if not file_name.endswith(".json"):
            print("Not a JSON file, skipping...")
            return "Not a JSON file, skipping...", 200

        # First check if the file exists
        storage_client = storage.Client()
        
        try:
            # Try to get bucket
            bucket = storage_client.get_bucket(bucket_name.split('/')[0])  # Handle bucket names with paths
            
            # Clean up file path if bucket has embedded path
            if '/' in bucket_name:
                bucket_parts = bucket_name.split('/')
                actual_bucket_name = bucket_parts[0]
                path_prefix = '/'.join(bucket_parts[1:])
                if not path_prefix.endswith('/'):
                    path_prefix += '/'
                full_path = f"{path_prefix}{file_name}"
            else:
                full_path = file_name
                actual_bucket_name = bucket_name
            
            # Check if file exists
            blob = bucket.blob(full_path)
            if not blob.exists():
                # List available files to help troubleshooting
                print(f"File not found: {full_path}")
                blobs = list(bucket.list_blobs(prefix=file_name.split('/')[0] if '/' in file_name else ''))
                available_files = [blob.name for blob in blobs][:10]  # List first 10 files
                return f"File not found: gs://{actual_bucket_name}/{full_path}. Available files (up to 10): {available_files}", 404

            # Initialize BigQuery client
            client = bigquery.Client()

            # Set dataset and table info
            dataset_id = "etl_dataset"
            table_id = "test"
            uri = f"gs://{actual_bucket_name}/{full_path}"

            # Load job config
            job_config = bigquery.LoadJobConfig(
                source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
                autodetect=True,
                write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
            )

            # Start load job
            load_job = client.load_table_from_uri(
                uri, f"{client.project}.{dataset_id}.{table_id}", job_config=job_config
            )

            load_job.result()  # Wait for the job to complete

            message = f"Loaded {uri} to {dataset_id}.{table_id}"
            print(message)
            return message, 200
            
        except Exception as e:
            return f"Error checking file existence: {str(e)}", 400

    except Exception as e:
        error_message = f"Error processing request: {str(e)}"
        print(error_message)
        return error_message, 500