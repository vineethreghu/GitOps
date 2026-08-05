# GitOps Progressive Delivery Platform

A GitOps framework demonstrating declarative infrastructure management, automated progressive delivery, and zero-trust security on Kubernetes.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                       │
│  ┌──────────────────┐                     ┌─────────────────┐   │
│  │   core/          │                     │  apps/demo-app/ │   │
│  │ ├─ Demo Apps     │                     │  ├─ base/       │   │
│  │ ├─ Ingress NGINX │                     │  ├─ overlays/   │   │
│  │ ├─ Sealed Secrets│                     │     ├─ staging  │   │
│  │ ├─ Argo Rollouts │                     │     └─ prod     │   │
│  │ └─ Prometheus    │                     │                 │   │
│  └──────────────────┘                     └─────────────────┘   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Git Sync (Auto)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster (Kind)                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  ArgoCD (GitOps Controller)                              │   │
│  │  ├─ Monitors Git repository                              │   │
│  │  ├─ Detects drift and auto-reconciles                    │   │
│  │  └─ Manages all applications declaratively               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐     │
│  │ Sealed       │  │ Ingress      │  │ Argo Rollouts      │     │
│  │ Secrets      │  │ NGINX        │  │ (Canary/B/G)       │     │
│  │ Controller   │  │ Controller   │  │ Controller         │     │
│  └──────────────┘  └──────────────┘  └────────────────────┘     │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │            Application Deployments                       │   │
│  │  ┌─────────────────┐        ┌─────────────────┐          │   │
│  │  │ staging/        │        │ prod/           │          │   │
│  │  │ └─ demo-app     │        │ └─ demo-app     │          │   │
│  │  │    (v1.0.0)     │        │    (v1.0.0)     │          │   │
│  │  │    Rollout      │        │    Rollout      │          │   │
│  │  │    + Analysis   │        │    + Analysis   │          │   │
│  │  └─────────────────┘        └─────────────────┘          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Prometheus (Metrics Collection)                          │   │
│  │ ├─ Ingress Controller Metrics                            │   │
│  │ ├─ Application Metrics                                   │   │
│  │ └─ Success Rate Analysis for Canary Validation           │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Implementations

### 1. **Declarative GitOps with ArgoCD**
- **App-of-Apps Pattern**: Root application manages all infrastructure and application deployments
- **Automated Sync**: Changes to Git automatically propagate to cluster
- **Drift Detection**: Self-healing mechanism corrects manual cluster changes
- **Namespace Isolation**: Staging and production environments in separate namespaces

### 2. **Progressive Delivery with Argo Rollouts**
- **Fully Automated Canary Strategy**: Gradual traffic shifting (20% → 50% → 100%)
- **Metrics-Driven Promotion**: Prometheus success rate analysis at each canary phase
- **Zero Manual Intervention**: No kubectl commands needed - promotion is automatic
- **Automatic Rollback**: Deployment aborts if success rate drops below 95%
- **Multi-Phase Validation**: Analysis runs at 20% and 50% traffic weights
- **Traffic Management**: Integration with Ingress NGINX for request routing

### 3. **Zero-Trust Security**
- **Sealed Secrets**: Encrypted secrets in Git, decrypted only in-cluster
- **No Plaintext Credentials**: All sensitive data encrypted with bitnami sealed-secrets
- **Master Key Backup**: Disaster recovery support via bootstrap/master-key.yaml
- **Security Context**: Non-root containers (UID 1000)

### 4. **Network & Resource Controls**
- **Network Policies**: Restrict ingress to NGINX controller and ArgoCD only
- **Resource Limits**: CPU (50m-100m) and Memory (32Mi-64Mi) boundaries
- **Health Probes**: Liveness and readiness checks for reliability
- **Pod Security**: runAsNonRoot enabled for all application pods

### 5. **Observability**
- **Prometheus Metrics**: System and application performance monitoring
- **Success Rate Tracking**: HTTP 5xx error rate analysis
- **Canary Analysis**: Real-time validation during progressive rollouts

## Repository Structure

```
GitOps-main/
├── bootstrap.sh                    # Automated cluster setup script
├── kind-config.yaml                # Kind cluster configuration
├── README.md                       # This documentation
├── TASK.md                         # Assignment requirements & status
│
├── bootstrap/
│   ├── root-app.yaml               # ArgoCD App-of-Apps root
│   └── master-key.yaml             # (gitignored) Sealed Secrets disaster recovery key
│
├── core/                           # Infrastructure Components (managed by root-app)
│   ├── argo-rollouts.yaml          # Progressive delivery controller
│   ├── sealed-secrets.yaml         # Secret encryption controller
│   ├── ingress-nginx.yaml          # Ingress controller (NodePort on Kind)
│   ├── prometheus.yaml             # Metrics and monitoring
│   ├── demo-app-staging.yaml       # Staging environment application
│   └── demo-app-prod.yaml          # Production environment application
│
├── apps/
│   └── demo-app/                   # Demo application manifests
│       ├── base/                   # Base Kustomize configuration
│       │   ├── kustomization.yaml
│       │   ├── rollout.yaml        # Argo Rollout with Canary strategy
│       │   ├── service.yaml        # ClusterIP service
│       │   ├── ingress.yaml        # HTTP routing rules
│       │   ├── networkpolicy.yaml  # Network access controls
│       │   ├── sealed-secret.yaml  # Encrypted API key
│       │   └── analysis.yaml       # Prometheus success rate analysis
│       │
│       └── overlays/               # Environment-specific configurations
│           ├── staging/
│           │   └── kustomization.yaml  # staging-demo.local, v1.0.0
│           └── prod/
│               └── kustomization.yaml  # prod-demo.local, v1.0.0
│
└── src/                            # Application source code
    ├── Dockerfile                  # Multi-stage Node.js 18 Alpine image
    ├── package.json                # Express.js dependencies
    └── server.js                   # Simple REST API with health endpoint
```

## Quick Start

### Prerequisites
- Docker Desktop or compatible container runtime
- `kind` (Kubernetes in Docker)
- `kubectl` CLI
- `git`

### Bootstrap the Platform

```bash
# Clone the repository
git clone https://github.com/vineethreghu/GitOps.git
cd GitOps

# Run the bootstrap script (creates cluster, installs ArgoCD, deploys apps)
./bootstrap.sh
```

The script performs:
1. ✅ Creates a 2-node Kind cluster (control-plane + worker)
2. ✅ Installs ArgoCD in `argocd` namespace
3. ✅ Restores Sealed Secrets master key (if exists)
4. ✅ Deploys root-app (App-of-Apps pattern)
5. ✅ Syncs all infrastructure and applications

### Access ArgoCD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode && echo

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser to https://localhost:8080
# Username: admin
# Password: <retrieved from above>
```

## GitOps Workflow

### Application Update Flow

```
┌──────────────────┐
│ 1. Developer     │
│    Updates Image │ 
│    Tag in Git    │
└────────┬─────────┘
         │
         │ git push
         ▼
┌──────────────────────────────┐
│ 2. GitHub Repository Updated │
│    overlays/prod/            │
│    kustomization.yaml        │
│    newTag: 2.0.0             │
└────────┬─────────────────────┘
         │
         │ ArgoCD polls (every 3min)
         ▼
┌──────────────────────────────┐
│ 3. ArgoCD Detects Change     │
│    Auto-sync triggered       │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ 4. Argo Rollouts Canary - Phase 1    │
│    ├─ Create new ReplicaSet (v2.0.0) │
│    ├─ Route 20% traffic to canary    │
│    ├─ Wait 1 minute for stabilization│
│    └─ Run AnalysisRun (Prometheus)   │
└────────┬─────────────────────────────┘
         │
         │ ✅ Success rate >= 95%
         ▼
┌──────────────────────────────────────┐
│ 5. Canary Phase 2 (AUTO)             │
│    ├─ Increase to 50% traffic        │
│    ├─ Wait 2 minutes                 │
│    └─ Run AnalysisRun again          │
└────────┬─────────────────────────────┘
         │
         │ ✅ Success rate >= 95%
         ▼
┌──────────────────────────────────────┐
│ 6. Full Promotion (AUTO)             │
│    ├─ Route 100% traffic to v2.0.0   │
│    ├─ Scale down old ReplicaSet      │
│    └─ Deployment complete!           │
└──────────────────────────────────────┘

         │ If ANY analysis fails (3 consecutive)
         ▼
┌──────────────────────────────────────┐
│ 7. Automatic Rollback                │
│    ├─ Abort canary deployment        │
│    ├─ Route 100% back to v1.0.0      │
│    └─ Alert via ArgoCD UI            │
└──────────────────────────────────────┘
```
