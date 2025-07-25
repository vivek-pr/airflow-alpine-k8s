#!/bin/bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-airflow-e2e}

for cmd in kind kubectl helm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd command not found" >&2
        exit 1
    fi
done

kind create cluster --name "$CLUSTER_NAME"

helm dependency update helm
helm install airflow helm -n airflow --create-namespace -f helm/values-alpine.yaml

# Wait for scheduler pod
kubectl wait --namespace airflow --for=condition=Ready pod -l component=scheduler --timeout=300s
POD=$(kubectl get pods -n airflow -l component=scheduler -o jsonpath='{.items[0].metadata.name}')

# Trigger a built-in example DAG and wait for completion
kubectl exec -n airflow "$POD" -- airflow dags trigger example_bash_operator
sleep 10
kubectl exec -n airflow "$POD" -- airflow tasks run example_bash_operator runme_0 2021-01-01

# Cleanup
kind delete cluster --name "$CLUSTER_NAME"
