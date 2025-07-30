# CI Testing with KinD and ArgoCD

This document describes the continuous integration workflow that verifies the Helm chart using a real Kubernetes cluster and ArgoCD. Every pull request spins up an ephemeral cluster, deploys the chart and checks that all Airflow components start correctly.

## Overview

1. A KinD cluster is created inside the CI job.
2. The Airflow image is built from `docker/Dockerfile` and loaded into the cluster.
3. ArgoCD is installed in the cluster.
4. An `Application` resource is applied pointing at the current commit.
5. A migration job runs as an ArgoCD sync hook to upgrade the Airflow database.
6. ArgoCD syncs the chart and the script waits for all pods to become ready.
7. Basic health checks run inside the scheduler pod.
8. The cluster is deleted when the job finishes.

## Running Locally

You need `kind`, `kubectl`, `helm` and `argocd` installed. Execute the workflow script:

```bash
./scripts/test_airflow_components.sh
```

Logs show the progress of ArgoCD and the status of each component.

To test a specific environment locally you can apply one of the Kustomize overlays:
```bash
kubectl apply -k k8s/argocd/overlays/dev
```
This deploys the dev configuration and sets the namespace suffix automatically.

## Troubleshooting

- **Pods not ready** – inspect pod events with `kubectl describe pod <name>`.
- **ArgoCD sync failure** – run `argocd app logs airflow` and check the controller logs.
- **Port conflicts** – KinD may fail if local ports are in use. Delete existing clusters with `kind delete cluster`.
- **Resource limits** – ensure the runner has at least 4 GB of memory available.
- **Ingress access** – if no controller is installed, port-forward the webserver service to reach the UI.

