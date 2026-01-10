#!/usr/bin/env bash
set -euo pipefail


# Create and deploy the whole stack
cd ../monitoring
kubectl apply -f .


