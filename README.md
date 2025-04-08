# ETL Cloud Pipeline

This project implements a simple cloud-based ETL (Extract, Transform, Load) pipeline using Google Cloud services. The pipeline consists of two main functions: an extraction function that saves data to Google Cloud Storage (GCS) and a loading function that uploads data from GCS to BigQuery.

## Project Structure

```
etl-cloud-pipeline
├── src
│   ├── extract_function
│   │   ├── main.py          # Logic for extracting data and saving to GCS
│   │   ├── requirements.txt  # Dependencies for the extraction function
│   │   └── Dockerfile        # Dockerfile for the extraction function
│   ├── load_function
│   │   ├── main.py          # Logic for loading data from GCS to BigQuery
│   │   ├── requirements.txt  # Dependencies for the loading function
│   │   └── Dockerfile        # Dockerfile for the loading function
│   └── utils
│       └── common.py        # Utility functions for reuse
├── scripts
│   ├── deploy_extract.sh     # Script to deploy the extraction function
│   ├── deploy_load.sh        # Script to deploy the loading function
│   └── setup_scheduler.sh     # Script to set up Cloud Scheduler
├── .github
│   └── workflows
│       └── deploy.yml        # GitHub Actions workflow for deployment
├── .gitignore                 # Files and directories to ignore
├── README.md                  # Project documentation
└── requirements-dev.txt       # Development dependencies
```

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd etl-cloud-pipeline
   ```

2. **Install Development Dependencies**
   ```bash
   pip install -r requirements-dev.txt
   ```

3. **Build and Deploy Functions**
   - To deploy the extraction function:
     ```bash
     ./scripts/deploy_extract.sh
     ```
   - To deploy the loading function:
     ```bash
     ./scripts/deploy_load.sh
     ```

4. **Set Up Cloud Scheduler**
   ```bash
   ./scripts/setup_scheduler.sh
   ```

## Usage

- The extraction function will run on a schedule defined in Cloud Scheduler, extracting data and saving it to GCS.
- When a file is uploaded to the specified GCS bucket, the loading function will be triggered to load the data into BigQuery.

## Deployment

This project uses GitHub Actions for CI/CD. The deployment workflow is defined in `.github/workflows/deploy.yml`. Ensure that your repository is connected to Google Cloud and has the necessary permissions to deploy Cloud Run services.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.