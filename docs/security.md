# Security Considerations

Running Airflow in production requires attention to a few security aspects.

## Image Scanning
Run `tests/test_trivy.sh` regularly to scan the Docker image for vulnerabilities. Keep the base image and packages up to date.

## Secrets Management
Store connection credentials and other secrets in Kubernetes Secrets or a secret management tool such as HashiCorp Vault. Avoid committing sensitive data to Git.

## Network Policies
Consider applying Kubernetes NetworkPolicies to restrict pod-to-pod communication. Limit access to the webserver and database only to required components.

## RBAC
The example manifests use minimal RBAC permissions. Review the roles and tighten them to follow the principle of least privilege.

## Updates
Monitor Airflow and dependency release notes for security patches. Rebuild and redeploy the image when vulnerabilities are fixed.

## Automated Updates
The repository uses Dependabot to monitor the Dockerfile and GitHub Actions for security patches. Pull requests are created automatically when new versions are available.

## Image Signing
Images built by the CI pipeline are signed with [cosign](https://github.com/sigstore/cosign). The signature can be verified using the public key stored in the repository.

## Compliance Checks
Run `tests/test_security_compliance.sh` to perform a kube-score audit of all Kubernetes manifests. This should be executed before any production deployment.
