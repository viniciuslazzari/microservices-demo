#!/usr/bin/env bash
set -euo pipefail

# Usage information
usage() {
    echo "Usage: $0 <PROJECT_ID> <GSA_NAME>"
    echo ""
    echo "Arguments:"
    echo "  PROJECT_ID  - Your GCP project ID"
    echo "  GSA_NAME    - Your Google Service Account name (without @PROJECT_ID.iam.gserviceaccount.com)"
    echo ""
    echo "Example:"
    echo "  $0 my-gcp-project my-service-account"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Error: Missing required arguments"
    usage
fi

PROJECT_ID=$1
GSA_NAME=$2

# Validate arguments are not empty
if [ -z "$PROJECT_ID" ] || [ -z "$GSA_NAME" ]; then
    echo "Error: PROJECT_ID and GSA_NAME cannot be empty"
    usage
fi

echo "Using PROJECT_ID: ${PROJECT_ID}"
echo "Using GSA_NAME: ${GSA_NAME}"
echo ""

cd ../kustomize

kustomize edit add component components/google-cloud-operations

kubectl kustomize .

kubectl apply -k .

echo "Enabling Google Cloud services..."
gcloud services enable \
    monitoring.googleapis.com \
    cloudtrace.googleapis.com \
    cloudprofiler.googleapis.com \
    --project ${PROJECT_ID}

echo "Adding IAM policy bindings..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member "serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role roles/cloudtrace.agent

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member "serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role roles/monitoring.metricWriter

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member "serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role roles/cloudprofiler.agent

echo ""
echo "Tracing setup completed successfully!"


