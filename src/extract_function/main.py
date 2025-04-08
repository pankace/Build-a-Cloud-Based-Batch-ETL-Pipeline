import os
from google.cloud import storage

def extract_data():
    # Simulate data extraction
    data = "Sample data extracted from source."
    return data

def save_to_gcs(bucket_name, destination_blob_name, data):
    """Uploads data to Google Cloud Storage."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    
    blob.upload_from_string(data)
    print(f"Data uploaded to GCS bucket {bucket_name} as {destination_blob_name}.")

def main(request):
    bucket_name = os.environ.get('GCS_BUCKET_NAME')
    destination_blob_name = os.environ.get('DESTINATION_BLOB_NAME')

    if not bucket_name or not destination_blob_name:
        return "GCS_BUCKET_NAME and DESTINATION_BLOB_NAME must be set.", 400

    data = extract_data()
    save_to_gcs(bucket_name, destination_blob_name, data)

    return "Data extraction and upload to GCS completed.", 200
