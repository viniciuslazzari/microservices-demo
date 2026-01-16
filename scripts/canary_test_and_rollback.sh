#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./scripts/canary_test_and_rollback.sh [FRONTEND_URL] [BASELINE_REQUESTS] [TEST_REQUESTS] [ABS_THRESHOLD_MS] [REL_THRESHOLD]
# Example:
# ./scripts/canary_test_and_rollback.sh http://localhost:8080 20 20 1000 0.5

FRONTEND_URL="${1:-http://localhost:8080}"
BASELINE_REQS="${2:-20}"
TEST_REQS="${3:-20}"
ABS_THRESHOLD_MS="${4:-1000}"    # absolute increase in ms
REL_THRESHOLD="${5:-0.5}"        # relative increase (50% = 0.5)

COMPONENT_DIR="${6:-./kustomize/components/with-canary-rollback}"
DEPLOY_MANIFEST="$COMPONENT_DIR/productcatalogservice-v3.yaml"
CANARY_MANIFEST="$COMPONENT_DIR/productcatalogservice-canary.yaml"
# original/origin canary (to restore previous routing) — keep existing with-canary as restore target
ORIG_CANARY_MANIFEST="../kustomize/components/with-canary/productcatalogservice-canary.yaml"
echo "[canary] frontend: $FRONTEND_URL"
echo "[canary] baseline reqs: $BASELINE_REQS, test reqs: $TEST_REQS"
echo "[canary] thresholds: abs=${ABS_THRESHOLD_MS}ms rel=${REL_THRESHOLD}"
# Optional header used to route requests to v3 via VirtualService.
# Default is a header that VirtualService can match; used only for TEST requests.
TEST_HEADER="${7:-x-canary-test: v3}"

function avg_latency_ms() {
  # usage: avg_latency_ms <url> <n> [header]
  local url="$1"
  local n="$2"
  local header="${3:-}"
  local sum=0
  local i
  for i in $(seq 1 $n); do
    if [ -n "${header}" ]; then
      t=$(curl -s -o /dev/null -w '%{time_total}\n' -H "${header}" "$url") || t=0
    else
      t=$(curl -s -o /dev/null -w '%{time_total}\n' "$url") || t=0
    fi
    # convert to ms (float)
    tms=$(awk "BEGIN{printf \"%f\", $t*1000}")
    sum=$(awk "BEGIN{printf \"%f\", $sum+$tms}")
    # small sleep to avoid hammering
    sleep 0.05
  done
  avg=$(awk "BEGIN{printf \"%f\", $sum/$n}")
  echo "$avg"
}

echo "[canary] measuring baseline latency against $FRONTEND_URL/"
  # Usage:
  # ./scripts/canary_test_and_rollback.sh [FRONTEND_URL] [BASELINE_REQUESTS] [TEST_REQUESTS] [ABS_THRESHOLD_MS] [REL_THRESHOLD] [COMPONENT_DIR] [TEST_HEADER]
  # Example (sem header):
  # ./scripts/canary_test_and_rollback.sh http://localhost:8080 20 20 1000 0.5
  # Example (envia header para rotear via VirtualService):
  # ./scripts/canary_test_and_rollback.sh http://localhost:8080 20 20 1000 0.5 ./kustomize/components/with-canary-rollback "x-canary-test: v3"
BASELINE_AVG_MS=$(avg_latency_ms "$FRONTEND_URL/" "$BASELINE_REQS")
echo "[canary] baseline avg: ${BASELINE_AVG_MS} ms"

echo "[canary] deploying v3 manifest: $DEPLOY_MANIFEST"
kubectl apply -f "$DEPLOY_MANIFEST"
  # keep TEST_HEADER as configured above (used only for test measurements)

echo "[canary] applying canary virtualservice with v3: $CANARY_MANIFEST"
kubectl apply -f "$CANARY_MANIFEST"

echo "[canary] waiting rollout for productcatalogservice-v3"
kubectl rollout status deployment/productcatalogservice-v3 --timeout=120s

sleep 5

echo "[canary] measuring test latency against $FRONTEND_URL/"
TEST_AVG_MS=$(avg_latency_ms "$FRONTEND_URL/" "$TEST_REQS" "${TEST_HEADER}")
echo "[canary] test avg: ${TEST_AVG_MS} ms"

# compute diffs
DELTA_MS=$(awk "BEGIN{printf \"%f\", $TEST_AVG_MS - $BASELINE_AVG_MS}")
DELTA_REL=$(awk "BEGIN{printf \"%f\", ($TEST_AVG_MS - $BASELINE_AVG_MS)/($BASELINE_AVG_MS+1e-9)}")

echo "[canary] delta abs: ${DELTA_MS} ms, delta rel: ${DELTA_REL}"
  if [ -n "${TEST_HEADER}" ]; then
    echo "[canary] using test header: ${TEST_HEADER}"
  fi

NEED_ROLLBACK=0
# check thresholds (abs or rel)
if awk "BEGIN{exit !($DELTA_MS > $ABS_THRESHOLD_MS)}"; then
  echo "[canary] absolute threshold exceeded -> rollback"
  NEED_ROLLBACK=1
fi
if awk "BEGIN{exit !($DELTA_REL > $REL_THRESHOLD)}"; then
  echo "[canary] relative threshold exceeded -> rollback"
  NEED_ROLLBACK=1
fi

if [ "$NEED_ROLLBACK" -eq 1 ]; then
  echo "[canary] threshold exceeded -> performing rollback actions"
  echo "[canary] patching VirtualService to route 100% to v1 (0% to v3)"
  kubectl patch virtualservice productcatalogservice-vs -n default \
    --type merge -p '{"spec": {"http": [{"route": [{"destination":{"host":"productcatalogservice","subset":"v1"},"weight":100},{"destination":{"host":"productcatalogservice","subset":"v3"},"weight":0}]}]}}' || true

  echo "[canary] deleting v3 deployment and pods"
  kubectl delete deployment productcatalogservice-v3 -n default --ignore-not-found || true
  kubectl delete pod -l app=productcatalogservice,version=v3 -n default --ignore-not-found || true

  echo "[canary] removing v3-specific services and test VirtualService/DestinationRule"
  kubectl delete svc productcatalogservice-v3 -n default --ignore-not-found || true
  kubectl delete virtualservice productcatalogservice-vs -n default --ignore-not-found || true
  kubectl delete destinationrule productcatalogservice-destination -n default --ignore-not-found || true

  echo "[canary] rollback complete"
  exit 1
else
  echo "[canary] canary passed thresholds. Leaving v3 in cluster." 
  exit 0
fi
