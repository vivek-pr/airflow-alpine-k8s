# ArgoCD Deployment Guide

This guide explains how to deploy the Helm chart using [ArgoCD](https://argo-cd.readthedocs.io/). Example manifests are provided under `k8s/argocd` and organised with Kustomize.

## Directory Structure
- `k8s/argocd/base` – base `Application` and notification ConfigMap
- `k8s/argocd/overlays/dev` – development environment settings
- `k8s/argocd/overlays/staging` – staging environment settings
- `k8s/argocd/overlays/prod` – production environment settings

Each overlay deploys to a separate Kubernetes namespace. By default the
manifests track the `main` branch of this repository, but you can change the
`targetRevision` field in each overlay if you maintain dedicated environment
branches.

## Installing ArgoCD
1. Create the namespace and install the manifests:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. Forward the API server port and log in:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   argocd login localhost:8080
   ```
3. Change the admin password if required.

## Deploying the Application
Apply the overlay that matches your environment:
```bash
kubectl apply -k k8s/argocd/overlays/dev
```
ArgoCD will create an `Application` resource that syncs the Helm chart.

## Database Migrations
The chart configures a job that runs Airflow database migrations as an
ArgoCD sync hook. When deploying with ArgoCD the following values are
set in `helm/values-alpine.yaml` to ensure migrations run automatically:

```yaml
migrateDatabaseJob:
  useHelmHooks: false
  applyCustomEnv: false
  jobAnnotations:
    "argocd.argoproj.io/hook": Sync
createUserJob:
  useHelmHooks: false
  applyCustomEnv: false
```
This job must complete before the Airflow pods start successfully.

## Testing Sync and Rollback
Push a change to the tracked Git branch and watch ArgoCD sync it automatically. To rollback, revert the commit – the cluster state will follow.

## Notifications
The base configuration includes an example for the ArgoCD [notifications controller](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/). Populate the `SLACK_TOKEN` secret referenced in `notifications-cm.yaml` to receive Slack alerts on sync events.
