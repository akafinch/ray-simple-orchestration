#!/usr/bin/env bash
set -euo pipefail

# Full stack teardown — reverse order of deploy.
# Usage: ./scripts/teardown.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
TF_DIR="$ROOT_DIR/terraform"

if [ -f "$ROOT_DIR/kubeconfig" ]; then
  export KUBECONFIG="$ROOT_DIR/kubeconfig"

  echo "==> Removing demo app..."
  kubectl delete -f "$ROOT_DIR/kubernetes/demo-app/" --ignore-not-found

  echo "==> Removing monitoring stack..."
  helm uninstall dcgm-exporter --namespace monitoring 2>/dev/null || true
  helm uninstall kube-prometheus-stack --namespace monitoring 2>/dev/null || true

  echo "==> Removing RayService..."
  kubectl delete -f "$ROOT_DIR/kubernetes/kuberay/rayservice-clip-clap.yaml" --ignore-not-found

  echo "==> Removing KubeRay operator..."
  helm uninstall kuberay-operator --namespace ray-system 2>/dev/null || true

  echo "==> Removing secrets and config..."
  kubectl delete secret obj-storage-reader --namespace ray-system --ignore-not-found
  kubectl delete configmap inference-config --namespace ray-system --ignore-not-found
  kubectl delete configmap inference-config --namespace default --ignore-not-found
else
  echo "==> No kubeconfig found — skipping Kubernetes cleanup"
fi

echo "==> Destroying Terraform infrastructure..."
cd "$TF_DIR"
terraform destroy -auto-approve

echo "==> Cleaning up local files..."
rm -f "$ROOT_DIR/kubeconfig"

echo "==> Teardown complete."
