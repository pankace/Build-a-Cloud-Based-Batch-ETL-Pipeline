from google.cloud import bigquery
import json
import os

def load_data_to_bigquery(data, context):
    bucket_name = data['bucket']
    file_name = data['name']
    
    # Construct the BigQuery client
    client = bigquery.Client()

    # Define the dataset and table
    dataset_id = os.environ.get('BQ_DATASET_ID')
    table_id = os.environ.get('BQ_TABLE_ID')

    # Define the URI for the source file in GCS
    source_uri = f'gs://{bucket_name}/{file_name}'

    # Define the job configuration
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        autodetect=True,
    )

    # Load the data from GCS to BigQuery
    load_job = client.load_table_from_uri(
        source_uri,
        f'{dataset_id}.{table_id}',
        job_config=job_config
    )

    load_job.result()  # Wait for the job to complete

    print(f'Loaded {load_job.output_rows} rows into {dataset_id}:{table_id}.')


if __name__ == "__main__":
    # Get port from environment variable or default to 8080
    port = int(os.environ.get("PORT", 8080))
    
    # Run the Flask app
    app.run(host="0.0.0.0", port=port)