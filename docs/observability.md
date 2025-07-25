# Monitoring and Observability

This guide explains how to deploy a basic monitoring stack for the Airflow Alpine distribution.
It covers Prometheus metrics collection, Grafana dashboards, log aggregation, and health checks.

## Prometheus Metrics

The Airflow Helm chart can expose metrics through the built in StatsD exporter.
Enable it in your `values` file:

```yaml
statsd:
  enabled: true
  serviceMonitor:
    enabled: true
```

This creates a `ServiceMonitor` that a Prometheus operator can scrape.
Example manifests for a standalone Prometheus server are provided under `k8s/monitoring`.

## Grafana Dashboards

A minimal Grafana deployment is available in `k8s/monitoring/grafana.yaml`.
It includes a ConfigMap with example dashboards for Airflow.
Point Grafana at the Prometheus service to visualise metrics.

## Logging Aggregation

Logs can be aggregated using Loki and Promtail. The file `k8s/monitoring/loki.yaml`
deploys a single Loki instance and a Promtail DaemonSet to ship container logs.
Grafana is pre-configured to query Loki for log data.

## Health Checks

The Docker image exposes a health check via `airflow info`. Additionally, the
webserver provides an HTTP endpoint at `/health` which returns a JSON status.
The provided test script `tests/test_observability.sh` verifies this endpoint.

## Alerting Rules

Sample PrometheusRule definitions live in `k8s/monitoring/prometheus-rules.yaml`.
They include a basic alert if the Airflow scheduler stops reporting heartbeats.
Adjust or extend these rules to suit your environment.

## Testing on Alpine

Run the observability test to ensure metrics and health endpoints work:

```bash
./tests/test_observability.sh
```

The script builds the Docker image, starts the webserver, waits for it to become
healthy and then queries the `/health` endpoint.
