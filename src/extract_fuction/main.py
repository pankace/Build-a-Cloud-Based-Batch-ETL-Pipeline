from flask import Flask, request, jsonify
from google.cloud import storage
import os
import logging
import tempfile
import datetime
import uuid
import traceback

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route("/", methods=["POST"])
def extract():
    try:
        # Get parameters from request or use defaults
        request_json = request.get_json(silent=True) or {}
        project_id = request_json.get("project_id", os.environ.get("PROJECT_ID"))
        bucket_name = request_json.get("bucket_name", os.environ.get("BUCKET_NAME"))
        destination_folder = request_json.get("destination_folder", "data")
        
        logger.info(f"Starting extract process with: project={project_id}, bucket={bucket_name}")
        
        if not project_id or not bucket_name:
            return jsonify({
                "success": False,
                "error": "Missing required parameters: project_id or bucket_name"
            }), 400
        
        # Create unique filename with timestamp
        current_time = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        file_id = str(uuid.uuid4())[:8]
        filename = f"data_{current_time}_{file_id}.json"
        temp_file_path = os.path.join(tempfile.gettempdir(), filename)
        
        # Your data extraction logic here
        # For testing, create a simple JSON file
        import json
        test_data = {
            "timestamp": current_time,
            "sample_data": "This is test data",
            "run_id": file_id
        }
        
        with open(temp_file_path, 'w') as f:
            json.dump(test_data, f)
        
        
        logger.info(f"Created temporary file at {temp_file_path}")
        
        # Initialize GCS client and upload
        storage_client = storage.Client(project=project_id)
        bucket = storage_client.bucket(bucket_name)
        destination_blob_name = f"{destination_folder}/{filename}"
        blob = bucket.blob(destination_blob_name)
        
        logger.info(f"Uploading to gs://{bucket_name}/{destination_blob_name}")
        blob.upload_from_filename(temp_file_path)
        
        # Verify upload was successful
        if blob.exists():
            logger.info("Upload successful, file exists in bucket")
        else:
            logger.error("Upload appeared to succeed but file not found in bucket")
        
        # Clean up temp file
        os.remove(temp_file_path)
        
        return jsonify({
            "success": True,
            "message": f"Data uploaded to gs://{bucket_name}/{destination_blob_name}",
            "destination": f"gs://{bucket_name}/{destination_blob_name}"
        })
        
    except Exception as e:
        logger.error(f"Error in extract function: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            "success": False,
            "error": str(e),
            "stack_trace": traceback.format_exc()
        }), 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)