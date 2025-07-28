# Security Considerations

Running Airflow in production requires attention to a few security aspects.

## Image Scanning
Run `tests/test_trivy.sh` regularly to scan the Docker image for vulnerabilities. Keep the base image and packages up to date.

### Required Tools

The security test suite expects `hadolint`, `trivy`, `cosign` and `kube-score` to be installed. On Debian-based systems these can be installed with:

```bash
sudo apt-get update
sudo apt-get install -y trivy
curl -L -o hadolint "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64"
sudo install -m 0755 hadolint /usr/local/bin/hadolint
curl -L -o cosign "https://github.com/sigstore/cosign/releases/download/v2.2.3/cosign-linux-amd64"
sudo install -m 0755 cosign /usr/local/bin/cosign
curl -L -o kube-score.tar.gz "https://github.com/zegl/kube-score/releases/download/v1.17.0/kube-score_1.17.0_linux_amd64.tar.gz"
tar -xzf kube-score.tar.gz
sudo install -m 0755 kube-score /usr/local/bin/kube-score
```

## Secrets Management
Store connection credentials and other secrets in Kubernetes Secrets or a secret management tool such as HashiCorp Vault. Avoid committing sensitive data to Git.

## Network Policies
Consider applying Kubernetes NetworkPolicies to restrict pod-to-pod communication. Limit access to the webserver and database only to required components.

## RBAC
The example manifests use minimal RBAC permissions. Review the roles and tighten them to follow the principle of least privilege.

## Non-Root Containers
The Docker images define a dedicated `airflow` user (UID/GID `50000`) with a home
directory at `/opt/airflow`. Running Airflow as a non-root user improves
container security and works well with Kubernetes security contexts. The
`tests/test_user_permissions.sh` script verifies that the image uses the correct
UID/GID and file permissions.
All Python packages are installed under `/opt/airflow/.local` by this user to
avoid modifying system directories.

## Updates
Monitor Airflow and dependency release notes for security patches. Rebuild and redeploy the image when vulnerabilities are fixed.

## Automated Updates
The repository uses Dependabot to monitor the Dockerfile and GitHub Actions for security patches. Pull requests are created automatically when new versions are available.

## Image Signing
Images built by the CI pipeline are signed with [cosign](https://github.com/sigstore/cosign). The signature can be verified using the public key stored in the repository.

## Compliance Checks
Run `tests/test_security_compliance.sh` to perform a kube-score audit of all Kubernetes manifests. This should be executed before any production deployment.
