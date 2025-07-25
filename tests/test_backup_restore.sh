#!/bin/bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-airflow-backup}

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
POD=$(kubectl get pods -n airflow -l component=scheduler -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n airflow "$POD" -- pg_dump -U airflow -d airflow > /tmp/backup.sql
kubectl exec -n airflow "$POD" -- psql -U airflow -d airflow -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
kubectl exec -i -n airflow "$POD" -- psql -U airflow -d airflow < /tmp/backup.sql

kind delete cluster --name "$CLUSTER_NAME"
