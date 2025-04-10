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
        
        if not bucket_name:
            return "Missing required field: bucket", 400

        # Initialize clients
        storage_client = storage.Client()
        bigquery_client = bigquery.Client()
        
        try:
            # Get bucket
            bucket = storage_client.get_bucket(bucket_name.split('/')[0])
            
            # Handle path prefix if any
            path_prefix = ""
            if '/' in bucket_name:
                bucket_parts = bucket_name.split('/')
                actual_bucket_name = bucket_parts[0]
                path_prefix = '/'.join(bucket_parts[1:])
                if not path_prefix.endswith('/') and path_prefix:
                    path_prefix += '/'
            else:
                actual_bucket_name = bucket_name
            
            # List all blobs in the bucket with the prefix
            blobs = list(bucket.list_blobs(prefix=path_prefix))
            
            # Filter for JSON files
            json_blobs = [blob for blob in blobs if blob.name.endswith('.json')]
            
            if not json_blobs:
                return f"No JSON files found in gs://{actual_bucket_name}/{path_prefix}", 404
            
            # Set dataset and table info
            dataset_id = "etl_dataset"
            table_id = "test"
            
            # Process each JSON file
            processed_files = []
            failed_files = []
            
            for blob in json_blobs:
                try:
                    # Configure and run the load job
                    uri = f"gs://{actual_bucket_name}/{blob.name}"
                    
                    job_config = bigquery.LoadJobConfig(
                        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
                        autodetect=True,
                        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
                    )
                    
                    load_job = bigquery_client.load_table_from_uri(
                        uri, f"{bigquery_client.project}.{dataset_id}.{table_id}", 
                        job_config=job_config
                    )
                    
                    load_job.result()  # Wait for the job to complete
                    processed_files.append(blob.name)
                    
                except Exception as e:
                    failed_files.append(f"{blob.name}: {str(e)}")
            
            # Generate response
            if failed_files:
                return {
                    "status": "partial_success",
                    "processed_files": processed_files,
                    "failed_files": failed_files
                }, 207  # 207 Multi-Status
            else:
                return {
                    "status": "success",
                    "message": f"Successfully loaded {len(processed_files)} JSON files to {dataset_id}.{table_id}",
                    "processed_files": processed_files
                }, 200
            
        except Exception as e:
            return f"Error accessing bucket: {str(e)}", 400


    except Exception as e:
        error_message = f"Error processing request: {str(e)}"
        print(error_message)
        return error_message, 500