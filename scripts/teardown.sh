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
  kubectl delete deployment demo-app --ignore-not-found
  kubectl delete service demo-app-svc --ignore-not-found

  echo "==> Removing monitoring stack..."
  helm uninstall dcgm-exporter --namespace monitoring 2>/dev/null || true
  helm uninstall kube-prometheus-stack --namespace monitoring 2>/dev/null || true
  kubectl delete configmap grafana-dashboards-inference --namespace monitoring --ignore-not-found

  echo "==> Removing RayService..."
  kubectl delete rayservice clip-clap --namespace ray-system --ignore-not-found

  echo "==> Removing KubeRay operator..."
  helm uninstall kuberay-operator --namespace ray-system 2>/dev/null || true

  echo "==> Removing NVIDIA device plugin..."
  kubectl delete daemonset nvidia-device-plugin-daemonset --namespace kube-system --ignore-not-found

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
