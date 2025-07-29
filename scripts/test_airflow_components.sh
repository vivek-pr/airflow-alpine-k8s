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
for comp in "${components[@]}"; do
    kubectl wait --namespace "$NAMESPACE" --for=condition=Ready pod -l component="$comp" --timeout=600s
done

SCHED=$(kubectl get pods -n "$NAMESPACE" -l component=scheduler -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n "$NAMESPACE" "$SCHED" -- airflow db check
kubectl exec -n "$NAMESPACE" "$SCHED" -- airflow dags list | head

WEB=$(kubectl get pods -n "$NAMESPACE" -l component=webserver -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n "$NAMESPACE" "$WEB" -- curl -f http://localhost:8080/health
