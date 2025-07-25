# Performance Tuning

This page lists a few tweaks that can help the Alpine based image run efficiently.

## Image Optimisations

- Only the minimal set of Alpine packages are installed. Avoid adding extra packages unless absolutely required.
- Use multi-stage builds to keep layers small and reduce attack surface.

## Airflow Settings

- Increase the number of worker processes by adjusting `workers` in `values-alpine.yaml` to match the CPU resources available.
- Enable gzip compression for the webserver by setting the `webserver.worker_class` to `gthread`.
- Use a local executor with high parallelism when running on small nodes.

## Kubernetes

- Tune resource limits in your values file to prevent CPU throttling.
- Mount persistent volumes with the `noatime` option for slightly better IO performance.
