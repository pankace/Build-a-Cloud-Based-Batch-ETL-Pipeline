# ETL Pipeline on Google Cloud Platform

This project implements a simple ETL (Extract, Transform, Load) pipeline using Google Cloud services. The pipeline extracts data from a source, uploads it to Google Cloud Storage (GCS), and then loads it into BigQuery. The process is automated using Cloud Run and Cloud Scheduler.

## Project Structure

```
etl-pipeline-gcp
├── src
│   ├── extract
│   │   ├── __init__.py
│   │   ├── main.py
│   │   └── requirements.txt
│   └── load
│       ├── __init__.py
│       ├── main.py
│       └── requirements.txt
├── terraform
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── cloud_scheduler.tf
├── docker
│   ├── extract
│   │   └── Dockerfile
│   └── load
│       └── Dockerfile
├── .github
│   └── workflows
│       └── deploy.yaml
├── .gitignore
└── README.md
```

## Prerequisites

- Google Cloud account
- Google Cloud SDK installed
- Docker installed
- Terraform installed
- Python 3.x

## Setup Instructions

1. **Clone the Repository**

   Clone this repository to your local machine:

   ```
   git clone <repository-url>
   cd etl-pipeline-gcp
   ```

2. **Configure Google Cloud**

   Set up your Google Cloud project and enable the necessary APIs (Cloud Run, Cloud Storage, BigQuery).

3. **Terraform Configuration**

   Navigate to the `terraform` directory and update the `variables.tf` file with your project-specific values. Then, run the following commands to deploy the infrastructure:

   ```
   cd terraform
   terraform init
   terraform apply
   ```

4. **Build and Deploy Docker Images**

   Navigate to the `docker` directory and build the Docker images for the extract and load functions:

   ```
   cd docker/extract
   docker build -t gcr.io/<your-project-id>/extract .
   docker push gcr.io/<your-project-id>/extract

   cd ../load
   docker build -t gcr.io/<your-project-id>/load .
   docker push gcr.io/<your-project-id>/load
   ```

5. **Deploy Cloud Run Functions**

   Use the Terraform configuration to deploy the Cloud Run functions, which will automatically set up the necessary triggers for GCS and BigQuery.

6. **Set Up Cloud Scheduler**

   The Cloud Scheduler job is configured in `cloud_scheduler.tf` to trigger the extract function on a regular schedule.

## Usage

Once deployed, the ETL pipeline will automatically extract data at the scheduled intervals, upload it to GCS, and load it into BigQuery.

## Deployment

The deployment process is automated using GitHub Actions. The workflow file is located in `.github/workflows/deploy.yaml`. Push changes to the main branch to trigger the deployment.

