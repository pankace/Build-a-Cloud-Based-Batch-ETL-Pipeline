FROM python:3.9-slim

WORKDIR /app

# Copy function code
COPY src/extract/ .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set the Cloud Function entry point
ENV FUNCTION_TARGET extract_and_upload

# Start the function
CMD functions-framework --target ${FUNCTION_TARGET} --port 8080