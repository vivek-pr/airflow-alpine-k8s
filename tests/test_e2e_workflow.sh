#!/bin/bash
set -euo pipefail

# End-to-end test deploying Airflow and running an example DAG
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

# Wait for the scheduler pod
kubectl wait --namespace airflow --for=condition=Ready pod -l component=scheduler --timeout=300s
SCHEDULER=$(kubectl get pods -n airflow -l component=scheduler -o jsonpath='{.items[0].metadata.name}')

# Trigger example DAG
kubectl exec -n airflow "$SCHEDULER" -- airflow dags trigger example_bash_operator
kubectl exec -n airflow "$SCHEDULER" -- airflow tasks run example_bash_operator runme_0 2016-07-01T00:00:00+00:00 --local

kind delete cluster --name "$CLUSTER_NAME"

echo "E2E workflow succeeded"
