# airflow-alpine-k8s

Custom Apache Airflow deployment with Alpine-based Docker images for Kubernetes using ArgoCD.

## Repository Structure

- **docker/** – Dockerfiles and related scripts
- **helm/** – Helm charts
- **k8s/** – Kubernetes manifests
- **docs/** – Project documentation
- **tests/** – Test cases and utilities

## Docker Image

The `docker/Dockerfile` builds a lightweight Airflow image based on
Alpine Linux 3.19. Build it locally with:

```bash
docker build -t airflow-alpine -f docker/Dockerfile .
```

## Helm Chart

The `helm/airflow` chart depends on Bitnami subcharts. Only `Chart.yaml` and the
optional `Chart.lock` are kept in version control. Run the following command to
download dependencies before deploying:

```bash
helm dependency build helm/airflow
```

## CI/CD

A GitHub Actions workflow builds and pushes a Docker image on every push or pull request to the `main` branch. Docker registry credentials are provided via repository secrets:

- `DOCKER_REGISTRY`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

Configure these secrets in your repository settings. The workflow file is located at `.github/workflows/docker-image.yml`.

## Branch Protection

Enable branch protection for `main` to require passing status checks and pull request reviews before merging.

## Testing

Basic validation scripts are available under `tests/`:

- `test_hadolint.sh` – lint the Dockerfile with [hadolint](https://github.com/hadolint/hadolint)
- `test_trivy.sh` – scan the Dockerfile for vulnerabilities using [Trivy](https://github.com/aquasecurity/trivy)
- `test_packages.sh` – verify required Alpine packages are listed in the Dockerfile

Run all tests with:

```bash
./tests/test_hadolint.sh
./tests/test_trivy.sh
./tests/test_packages.sh
```
