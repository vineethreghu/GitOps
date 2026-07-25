#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="demo"
CONFIG_FILE="kind-config.yaml"
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ROOT_APP_MANIFEST="bootstrap/root-app.yaml"

function ensure_kind_cluster() {
  if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Kind cluster '${CLUSTER_NAME}' already exists."
  else
    echo "Creating Kind cluster '${CLUSTER_NAME}'..."
    kind create cluster --name "${CLUSTER_NAME}" --config "${CONFIG_FILE}"
  fi

  echo "Using kubectl context kind-${CLUSTER_NAME}"
  kubectl config use-context "kind-${CLUSTER_NAME}"
}

function install_argocd() {
  echo "Ensuring namespace argocd exists..."
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

  echo "Downloading Argo CD install manifest..."
  local manifest
  manifest=$(mktemp)
  trap 'rm -f "${manifest}"' EXIT
  curl -fsSL "${ARGOCD_INSTALL_URL}" -o "${manifest}"

  echo "Applying Argo CD install manifest into namespace argocd..."
  if ! kubectl apply -n argocd -f "${manifest}" --validate=false; then
    echo "Standard apply failed, retrying with server-side apply..."
    kubectl apply --server-side --force-conflicts -n argocd -f "${manifest}"
  fi

  echo "Checking resources in argocd namespace..."
  kubectl get all -n argocd || true

  echo "Waiting for argocd-server deployment to become available..."
  kubectl wait --namespace argocd deployment/argocd-server --for condition=available --timeout=180s || {
    echo "ERROR: argocd-server deployment did not become available. Here are current argocd namespace resources:"
    kubectl get all -n argocd || true
    kubectl get events -n argocd --sort-by='.metadata.creationTimestamp' || true
    exit 1
  }
}

function apply_root_app() {
  echo "Applying App-of-Apps root manifest: ${ROOT_APP_MANIFEST}"
  kubectl apply -f "${ROOT_APP_MANIFEST}"
}

function print_next_steps() {
  cat <<EOF

Bootstrap complete.

Next, use the following to inspect Argo CD and access the UI:

  kubectl get pods -n argocd
  kubectl get applications -n argocd

To retrieve the initial Argo CD admin password:
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode

To access the Argo CD UI locally:
  kubectl port-forward svc/argocd-server -n argocd 8080:443

Then open http://127.0.0.1:8080
EOF
}

ensure_kind_cluster
install_argocd
apply_root_app
print_next_steps
