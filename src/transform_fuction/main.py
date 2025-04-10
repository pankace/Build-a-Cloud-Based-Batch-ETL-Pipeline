import json
import functions_framework
from google.cloud import bigquery

@functions_framework.http
def gcs_to_bigquery(request):
    try:
        # Get request data - use get_json() instead of .data
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

        # Initialize BigQuery client
        client = bigquery.Client()

        # Set dataset and table info
        dataset_id = "etl_dataset"
        table_id = "test"
        uri = f"gs://{bucket_name}/{file_name}"

        # Load job config
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
            autodetect=True,  # or provide a schema
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
        error_message = f"Error processing request: {str(e)}"
        print(error_message)
        return error_message, 500