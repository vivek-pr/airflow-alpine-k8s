#!/bin/bash
set -euo pipefail

trivy config --exit-code 1 --quiet docker/Dockerfile
docker build -t airflow-alpine-k8s:test -f docker/Dockerfile .
trivy image --exit-code 1 --quiet airflow-alpine-k8s:test
