#!/bin/bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-airflow-load}

for cmd in kind kubectl helm ab; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd command not found" >&2
        exit 1
    fi
done

kind create cluster --name "$CLUSTER_NAME"
helm dependency update helm
helm install airflow helm -n airflow --create-namespace -f helm/values-alpine.yaml

kubectl wait --namespace airflow --for=condition=Ready pod -l component=webserver --timeout=300s
WEB_POD=$(kubectl get pods -n airflow -l component=webserver -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n airflow "$WEB_POD" 8080:8080 &
PORT_FWD_PID=$!

sleep 10
ab -n 100 -c 10 http://127.0.0.1:8080/ > /tmp/ab_result.txt
kill $PORT_FWD_PID

kind delete cluster --name "$CLUSTER_NAME"
cat /tmp/ab_result.txt
