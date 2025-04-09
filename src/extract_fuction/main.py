import os
import json
import requests
import functions_framework
from google.cloud import storage
import logging

logging.basicConfig(level=logging.INFO)

@functions_framework.http
def main(request):
    # Accept only POST
    if request.method != 'POST':
        return (json.dumps({
            "message": "Use POST with optional project_id, bucket_name, and destination_folder to upload to GCS."
        }), 200, {'Content-Type': 'application/json'})

    data = request.get_json(silent=True) or {}

    logging.info(f"Request received: {data}")

    project_id = data.get("project_id")
    bucket_name = data.get("bucket_name")
    destination_folder = data.get("destination_folder", "harbour_space_data")

    logging.info(f"Uploading to bucket: {bucket_name} under project: {project_id}")

    # Request the Harbour.Space schedule data
    url = "https://harbour.space/api/v1/schedule?include=course&first_year=2024&campus=barcelona"
    response = requests.get(url)

    if response.status_code != 200:
        return (json.dumps({"error": f"Failed to fetch schedule: {response.status_code}"}), 500, {'Content-Type': 'application/json'})

    # Save data to /tmp
    file_name = "harbour_space_schedule.json"
    file_path = f"/tmp/{file_name}"

    json_data = response.json()

    # If it's wrapped in a dict with a "data" key, unwrap it
    if isinstance(json_data, dict) and "data" in json_data:
        json_data = json_data["data"]

    # Write as NDJSON
    with open(file_path, "w", encoding="utf-8") as f:
        for item in json_data:
            f.write(json.dumps(item) + "\n")


    uploaded_path = None
    if project_id and bucket_name:
        try:
            storage_client = storage.Client(project=project_id)
            bucket = storage_client.bucket(bucket_name)
            blob_path = os.path.join(destination_folder, file_name)
            blob = bucket.blob(blob_path)
            blob.upload_from_filename(file_path)
            uploaded_path = f"gs://{bucket_name}/{blob_path}"
        except Exception as e:
            return (json.dumps({"error": f"Upload failed: {str(e)}"}), 500, {'Content-Type': 'application/json'})

    return (json.dumps({
        "message": "Schedule fetched successfully",
        "uploaded_to": uploaded_path or "Not uploaded (GCS info not provided)",
        "local_path": file_path
    }), 200, {'Content-Type': 'application/json'})