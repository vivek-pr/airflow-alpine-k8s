# Architecture

The diagram below shows the high-level components involved when deploying the project on Kubernetes.

```mermaid
flowchart TD
    subgraph CI
        git[(Git Repository)] --> build(Docker Build)
    end
    build --> registry[(Container Registry)]
    registry --> helm[Helm Chart]
    helm --> cluster[Kubernetes Cluster]
    cluster --> web[Webserver]
    cluster --> sched[Scheduler]
    cluster --> worker[Worker]
    argocd[ArgoCD] --> cluster
```

The Docker image is built from the files in `docker/` and pushed to a registry. The Helm chart pulls this image and installs Airflow pods in the cluster. ArgoCD monitors the Git repository and applies any configuration changes automatically.
