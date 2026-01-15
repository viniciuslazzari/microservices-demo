#!/usr/bin/env bash
set -euo pipefail

# Delete  monitoring resources
if kubectl get namespace monitoring 2>/dev/null; then
  echo "Deleting monitoring resources..."
  cd ../monitoring
  kubectl delete -f .
else
  echo "Monitoring namespace doesn't exist. Skipping monitoring resource deletion."
fi

# Delete resources deployed with Kustomize
cd ../kustomize
kubectl delete -k .

# Delete GKE cluster
gcloud container clusters delete online-boutique
