#!/usr/bin/env bash
set -euo pipefail

# Delete services
kubectl delete services --all --namespace=monitoring

# Delete deployments
kubectl delete deployments --all --namespace=monitoring

# Delete resources deployed with Kustomize
cd ../kustomize
kubectl delete -k .

# Delete GKE cluster
gcloud container clusters delete online-boutique
