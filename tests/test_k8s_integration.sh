#!/bin/bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-airflow-test}

# Ensure required tools exist
for cmd in kind kubectl helm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd command not found" >&2
        exit 1
    fi
done

kind create cluster --name "$CLUSTER_NAME"

helm dependency update helm
helm install airflow helm -n airflow --create-namespace -f helm/values-alpine.yaml

# Wait for core components
declare -a components=(webserver scheduler worker)
for c in "${components[@]}"; do
    kubectl wait --namespace airflow --for=condition=Ready pod -l component=$c --timeout=300s
done

# Validate Airflow is responding
POD=$(kubectl get pods -n airflow -l component=scheduler -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n airflow "$POD" -- airflow db check
kubectl exec -n airflow "$POD" -- airflow info
kubectl exec -n airflow "$POD" -- airflow dags list

# Verify Celery broker
POD_WORKER=$(kubectl get pods -n airflow -l component=worker -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n airflow "$POD_WORKER" -- celery -A airflow.executors.celery_executor.app inspect ping

# Show recent logs
kubectl logs "$POD" -n airflow | tail -n 20

# Cleanup
kind delete cluster --name "$CLUSTER_NAME"
