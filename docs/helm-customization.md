# Helm Chart Customization

The Helm chart in this repository is a thin wrapper around the official Apache Airflow chart. It overrides the container image and resource limits so that Airflow runs on the Alpine-based image.

## Updating Values
Copy `helm/values-alpine.yaml` and modify it to suit your cluster:
```bash
cp helm/values-alpine.yaml my-values.yaml
```
Common settings you may want to change:
- `images.airflow.repository` – image repository
- `images.airflow.tag` – image tag
- `executor` – Celery, KubernetesExecutor etc.
- `airflow.config.AIRFLOW__CORE__FERNET_KEY` – set a production key

Then deploy:
```bash
helm install airflow helm -f my-values.yaml
```

For advanced configuration options refer to the official chart documentation.
