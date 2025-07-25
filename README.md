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

The repo provides a wrapper chart in `helm/Chart.yaml` which pulls in the
official Airflow Helm chart as a dependency. A custom `helm/values-alpine.yaml`
overrides the image reference and resource limits for the Alpine image. Render
the manifests with:

```bash
helm dependency update helm
helm template airflow helm -f helm/values-alpine.yaml
```

## CI/CD

A GitHub Actions workflow builds the Docker image and runs local validation tests
on every push or pull request to the `main` branch. The workflow no longer
pushes images to a registry. Instead, it ensures that the Dockerfile builds and
that the container starts successfully. The workflow file is located at
`.github/workflows/docker-image.yml`.

## Branch Protection

Enable branch protection for `main` to require passing status checks and pull request reviews before merging.

## Testing

Test scripts are available under `tests/`:

- `test_hadolint.sh` – lint the Dockerfile with [hadolint](https://github.com/hadolint/hadolint)
- `test_trivy.sh` – scan the Dockerfile for vulnerabilities using [Trivy](https://github.com/aquasecurity/trivy)
- `test_packages.sh` – verify required Alpine packages are listed in the Dockerfile
- `test_docker_build.sh` – build the Docker image and ensure Airflow starts
- `test_k8s_integration.sh` – deploy the Helm chart on KIND and validate the cluster
- `test_end_to_end.sh` – trigger an example DAG inside the KIND cluster
- `test_performance.sh` – compare startup time of the Alpine image with the official image
- `test_load.sh` – run a basic load test against the Airflow webserver
- `test_disaster_recovery.sh` – verify pods recover if deleted
- `test_security_compliance.sh` – check manifests with `kube-score`

Run the basic checks with:

```bash
./tests/test_hadolint.sh
./tests/test_trivy.sh
./tests/test_packages.sh
./tests/test_docker_build.sh
```

## Kubernetes Integration Testing

An optional script `tests/test_k8s_integration.sh` provisions a temporary
[KIND](https://kind.sigs.k8s.io/) cluster and deploys the Helm chart. It
verifies that the webserver, scheduler and worker pods start, checks database
migrations, confirms Redis/Celery connectivity and ensures DAGs load correctly.

Run the integration test (requires `kind`, `kubectl` and `helm` in your PATH):

```bash
./tests/test_k8s_integration.sh
```

### Additional Test Suites

Other scripts provide broader test coverage:

```bash
./tests/test_end_to_end.sh        # run a DAG in a temporary cluster
./tests/test_performance.sh       # compare image startup times
./tests/test_load.sh              # apply load to the webserver
./tests/test_disaster_recovery.sh # simulate pod failures
./tests/test_security_compliance.sh # score manifests with kube-score
```

## ArgoCD Deployment

Manifests for ArgoCD are available under `k8s/argocd`. The base configuration
creates an `Application` that syncs this repository's Helm chart. Environment
overlays for `dev`, `staging` and `prod` adjust the target namespace and Git
branch. The sync policy enables automatic deployment, pruning and self-healing.

See [docs/argocd.md](docs/argocd.md) for detailed setup instructions, including
notification configuration and how to test automated sync and rollback.
