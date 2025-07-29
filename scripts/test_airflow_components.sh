#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-airflow}

required=(kubectl)
for c in "${required[@]}"; do
    if ! command -v "$c" >/dev/null 2>&1; then
        echo "$c command not found" >&2
        exit 1
    fi
done

components=(webserver scheduler triggerer worker redis postgres)
MAX_WAIT=${MAX_WAIT:-600}

for comp in "${components[@]}"; do
    echo "Waiting for $comp pod to be created"
    start=$(date +%s)
    until kubectl get pods -n "$NAMESPACE" -l component="$comp" -o name 2>/dev/null | grep -q .; do
        sleep 5
        if (( $(date +%s) - start > MAX_WAIT )); then
            echo "Timed out waiting for $comp pod creation" >&2
            kubectl get pods -n "$NAMESPACE" -l component="$comp" || true
            exit 1
        fi
    done
    kubectl wait --namespace "$NAMESPACE" --for=condition=Ready pod -l component="$comp" --timeout=${MAX_WAIT}s
done

SCHED=$(kubectl get pods -n "$NAMESPACE" -l component=scheduler -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n "$NAMESPACE" "$SCHED" -- airflow db check
kubectl exec -n "$NAMESPACE" "$SCHED" -- airflow dags list | head

WEB=$(kubectl get pods -n "$NAMESPACE" -l component=webserver -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n "$NAMESPACE" "$WEB" -- curl -f http://localhost:8080/health
