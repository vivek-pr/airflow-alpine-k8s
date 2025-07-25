#!/bin/bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-airflow-dr}

for cmd in kind kubectl helm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd command not found" >&2
        exit 1
    fi
done

kind create cluster --name "$CLUSTER_NAME"
helm dependency update helm
helm install airflow helm -n airflow --create-namespace -f helm/values-alpine.yaml

kubectl wait --namespace airflow --for=condition=Ready pod -l component=scheduler --timeout=300s
SCHED_POD=$(kubectl get pods -n airflow -l component=scheduler -o jsonpath='{.items[0].metadata.name}')

# Simulate failure by deleting pod
kubectl delete pod "$SCHED_POD" -n airflow
kubectl wait --namespace airflow --for=condition=Ready pod -l component=scheduler --timeout=300s

kind delete cluster --name "$CLUSTER_NAME"
