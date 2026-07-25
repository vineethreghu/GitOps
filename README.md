# Step 1 — Infrastructure Automation

This repository contains the first stage of the Platform Engineering: provisioning a local Kubernetes cluster with Kind.

## Prerequisites

Install these tools on your local machine:
- **Docker** — `kind` runs Kubernetes nodes as Docker containers
- **kind** — Download from https://kind.sigs.k8s.io/
- **kubectl** — Download from https://kubernetes.io/docs/tasks/tools/

## Run

```bash
cd /home/ubuntu/Documents/Projects/on-prem-k8s/GitOps
chmod +x bootstrap.sh
./bootstrap.sh
```

## Verify

```bash
kubectl cluster-info --context kind-demo
kubectl get nodes
```

## Files

- `bootstrap.sh` — Creates a local Kind cluster and bootstraps Argo CD
- `kind-config.yaml` — Kind cluster configuration
- `README.md` — This file

## What you get

After running the script:
- A local Kubernetes cluster named `demo` with Docker containers as nodes
- Full `kubectl` access to the cluster
- Ready for the next step: installing Argo CD and the GitOps platform

## Next Step

After this succeeds, we move to Step 2: deploying Argo CD on the cluster.
