import json
import functions_framework
from google.cloud import bigquery

@functions_framework.cloud_event
def gcs_to_bigquery(cloud_event):
    data = cloud_event.data
    bucket_name = data["bucket"]
    file_name = data["name"]

    if not file_name.endswith(".json"):
        print("Not a JSON file, skipping...")
        return

    # Initialize BigQuery client
    client = bigquery.Client()

    # Set dataset and table info
    dataset_id = "university_taiwan"
    table_id = "harbour_space_schedule"
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

    print(f"Loaded {uri} to {dataset_id}.{table_id}")