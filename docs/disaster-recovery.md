# Disaster Recovery Guide

This document outlines how to back up and restore the Airflow metadata database and provides guidance for recovering a failed deployment.

## Backup Procedure

1. Ensure the PostgreSQL client is available in the Airflow container (installed by default).
2. Identify the scheduler pod:
   ```bash
   kubectl get pods -n airflow -l component=scheduler
   ```
3. Create a database dump:
   ```bash
   POD=$(kubectl get pods -n airflow -l component=scheduler -o jsonpath='{.items[0].metadata.name}')
   kubectl exec -n airflow "$POD" -- pg_dump -U airflow -d airflow > airflow_backup.sql
   ```
4. Store the dump in a safe location such as object storage or a secure volume.

## Restore Procedure

1. Recreate the Airflow cluster if needed using the Helm chart or ArgoCD.
2. Copy the backup file into the scheduler pod:
   ```bash
   kubectl cp airflow_backup.sql "$POD":/tmp/airflow_backup.sql -n airflow
   ```
3. Restore the database:
   ```bash
   kubectl exec -i -n airflow "$POD" -- psql -U airflow -d airflow < /tmp/airflow_backup.sql
   ```
4. Restart the webserver and scheduler pods to ensure they pick up the restored state:
   ```bash
   kubectl rollout restart deployment airflow-webserver -n airflow
   kubectl rollout restart deployment airflow-scheduler -n airflow
   ```

## Disaster Recovery Tips

- Keep regular off-site backups of the metadata database.
- Store a copy of your Helm values and Kubernetes manifests in version control.
- Periodically test the restore procedure in a staging environment.
