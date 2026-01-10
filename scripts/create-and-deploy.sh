#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="online-boutique"

# Create GKE cluster and deploy the application using Kustomize (to include without-loadgenerator component which has already been added)
# Assumes gcloud and kubectl are already installed and configured
# Assumes Project ID and region are already set in gcloud config

# Check if the cluster already exists
if gcloud container clusters describe "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "GKE cluster '$CLUSTER_NAME' already exists. Skipping creation."
else
  echo "Creating GKE cluster '$CLUSTER_NAME'..."
  gcloud container clusters create "$CLUSTER_NAME"
fi

# Deploy the application using Kustomize
cd ../kustomize
kubectl apply -k .
