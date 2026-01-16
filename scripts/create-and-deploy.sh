#!/usr/bin/env bash
set -euo pipefail

# Parameters with defaults
CLUSTER_NAME="${1:-online-boutique}"
ZONE="${2:-europe-west6-a}"

# Create GKE cluster and deploy the application using Kustomize (to include without-loadgenerator component which has already been added)
# Assumes gcloud and kubectl are already installed and configured
# Assumes Project ID and region are already set in gcloud config

# Check if the cluster already exists
if gcloud container clusters describe "$CLUSTER_NAME" --zone "$ZONE" >/dev/null 2>&1; then
  echo "GKE cluster '$CLUSTER_NAME' already exists. Skipping creation."
else
  echo "Creating GKE cluster '$CLUSTER_NAME' in zone '$ZONE'..."
  gcloud container clusters create "$CLUSTER_NAME" --zone "$ZONE"
fi
# Get cluster credentials to update kubeconfig
echo "Configuring kubectl to access the cluster..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"
# Deploy the application using Kustomize
cd ../kustomize
kubectl apply -k .
