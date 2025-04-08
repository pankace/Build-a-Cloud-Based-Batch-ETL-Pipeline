def read_json_file(file_path):
    import json
    with open(file_path, 'r') as file:
        return json.load(file)

def write_json_file(file_path, data):
    import json
    with open(file_path, 'w') as file:
        json.dump(data, file, indent=4)

def upload_to_gcs(bucket_name, source_file, destination_blob_name):
    from google.cloud import storage
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_filename(source_file)

def trigger_bigquery_load(event, context):
    from google.cloud import bigquery
    client = bigquery.Client()
    dataset_id = 'your_dataset_id'
    table_id = 'your_table_id'
    uri = f"gs://{event['bucket']}/{event['name']}"
    
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
    )
    
    load_job = client.load_table_from_uri(
        uri,
        f"{dataset_id}.{table_id}",
        job_config=job_config,
    )
    
    load_job.result()  # Waits for the job to complete.