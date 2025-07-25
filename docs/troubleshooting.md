# Troubleshooting Guide

This page lists common issues encountered when building or deploying the project.

## Docker Build Fails
- Ensure Docker is installed and running
- Verify you have internet access to download packages
- Clear any previously cached layers with `docker build --no-cache`

## Helm Installation Issues
- Check that `helm dependency update helm` completed successfully
- Validate your custom values file with `helm lint`

## Pods Not Starting
- Inspect pod logs using `kubectl logs`
- Ensure the Kubernetes nodes have enough CPU and memory resources

## Database Migrations Hang
- Confirm the Airflow database connection details are correct
- Look for errors in the scheduler pod logs

For further help open an issue on GitHub.
