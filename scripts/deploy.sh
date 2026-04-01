#!/usr/bin/env bash
set -euo pipefail

# Full stack deploy: Terraform → Helm → kubectl
# Usage: ./scripts/deploy.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
TF_DIR="$ROOT_DIR/terraform"

# ---- Phase 1: Terraform ----
echo "==> Phase 1: Terraform apply"
cd "$TF_DIR"
terraform init
terraform apply -auto-approve

# Extract outputs
OBJ_READER_KEY=$(terraform output -raw obj_reader_key)
OBJ_READER_SECRET=$(terraform output -raw obj_reader_secret)
OBJ_ENDPOINT=$(terraform output -raw obj_endpoint)
MODEL_BUCKET=$(terraform output -raw model_bucket)
GRAFANA_PASSWORD=$(terraform output -raw grafana_admin_password)

# ---- Phase 2: Kubeconfig ----
echo "==> Phase 2: Kubeconfig"
"$SCRIPT_DIR/get-kubeconfig.sh" "$ROOT_DIR/kubeconfig"
export KUBECONFIG="$ROOT_DIR/kubeconfig"
echo "    Cluster nodes:"
kubectl get nodes -o wide

# ---- Phase 3: Namespaces ----
echo "==> Phase 3: Namespaces"
kubectl create namespace ray-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# ---- Phase 4: Secrets + ConfigMaps ----
echo "==> Phase 4: Secrets and ConfigMaps"
kubectl create secret generic obj-storage-reader \
  --from-literal=access-key="$OBJ_READER_KEY" \
  --from-literal=secret-key="$OBJ_READER_SECRET" \
  --namespace ray-system --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "$ROOT_DIR/kubernetes/demo-app/configmap.yaml"

# ---- Phase 5: KubeRay Operator ----
echo "==> Phase 5: KubeRay operator"
helm repo add kuberay https://ray-project.github.io/kuberay-helm/ 2>/dev/null || true
helm repo update
helm upgrade --install kuberay-operator kuberay/kuberay-operator \
  --namespace ray-system \
  --version 1.6.0 \
  --wait --timeout 5m

# ---- Phase 6: RayService ----
echo "==> Phase 6: RayService (CLIP + CLAP)"
kubectl apply -f "$ROOT_DIR/kubernetes/kuberay/rayservice-clip-clap.yaml"
echo "    Waiting for RayService pods..."
kubectl -n ray-system wait --for=condition=Ready pod -l ray.io/cluster --timeout=10m || \
  echo "    WARNING: Timeout waiting for Ray pods — check 'kubectl -n ray-system get pods'"

# ---- Phase 7: Monitoring ----
echo "==> Phase 7: Monitoring stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia 2>/dev/null || true
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set "grafana.adminPassword=$GRAFANA_PASSWORD" \
  -f "$ROOT_DIR/kubernetes/monitoring/prometheus-values.yaml" \
  --wait --timeout 5m

helm upgrade --install dcgm-exporter nvidia/dcgm-exporter \
  --namespace monitoring \
  -f "$ROOT_DIR/kubernetes/monitoring/dcgm-values.yaml" \
  --wait --timeout 3m

# Provision Grafana dashboards from JSON files
kubectl create configmap grafana-dashboards-inference \
  --from-file="$ROOT_DIR/kubernetes/monitoring/dashboards/ray-serve.json" \
  --from-file="$ROOT_DIR/kubernetes/monitoring/dashboards/gpu-utilization.json" \
  --namespace monitoring --dry-run=client -o yaml | \
  kubectl label --local -f - grafana_dashboard=1 -o yaml | \
  kubectl apply -f -

# ---- Phase 8: Demo App ----
echo "==> Phase 8: Demo app"
kubectl apply -f "$ROOT_DIR/kubernetes/demo-app/deployment.yaml"
kubectl apply -f "$ROOT_DIR/kubernetes/demo-app/service.yaml"
kubectl rollout status deployment/demo-app --timeout=3m

# ---- Summary ----
echo ""
echo "============================================"
echo "  Deploy complete!"
echo "============================================"
echo ""
echo "External services:"
kubectl get svc --all-namespaces -o wide | grep LoadBalancer
echo ""
echo "Grafana admin password: (run 'terraform -chdir=terraform output grafana_admin_password')"
echo "Ray dashboard: kubectl -n ray-system port-forward svc/clip-clap-head-svc 8265:8265"
echo ""
