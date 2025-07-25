# ArgoCD Deployment Guide

This project ships with example manifests for deploying the Helm chart via [ArgoCD](https://argo-cd.readthedocs.io/).
The manifests are located in `k8s/argocd` and are organised using Kustomize.

## Directory structure

- `k8s/argocd/base` – base `Application` resource and notification configuration
- `k8s/argocd/overlays/dev` – development environment overlay
- `k8s/argocd/overlays/staging` – staging environment overlay
- `k8s/argocd/overlays/prod` – production environment overlay

Each overlay patches the base `Application` to target a different Git branch and Kubernetes namespace.

## Installing ArgoCD

1. Install ArgoCD on your cluster:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. Log in to the ArgoCD API server and change the admin password if desired.

## Deploying the Application

Apply the overlay for your environment using Kustomize:

```bash
# Deploy to the dev environment
kubectl apply -k k8s/argocd/overlays/dev
```

The application uses an automated sync policy with pruning and self-healing enabled.
Any changes pushed to the specified Git branch are automatically applied.

## Testing Sync and Rollback

1. Commit a change to the Helm chart or manifests and push to the tracked branch.
2. ArgoCD will automatically sync the application and deploy the change.
3. To rollback, revert the commit in Git – ArgoCD detects the change and rolls back the cluster state.

## Notifications

The base configuration contains an example ConfigMap for the ArgoCD [notifications controller](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/).
Populate the `SLACK_TOKEN` secret referenced in `notifications-cm.yaml` to receive Slack alerts when sync operations succeed or fail.
