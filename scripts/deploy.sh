#!/usr/bin/env bash
set -euo pipefail

# Deploy Kubernetes resources onto an already-provisioned LKE cluster.
# Prerequisite: terraform apply must have completed successfully.
# Usage: ./scripts/deploy.sh <docker-registry-prefix>
# Example: ./scripts/deploy.sh akafinch

if [ $# -lt 1 ]; then
  echo "Usage: $0 <docker-registry-prefix> [image-tag]"
  echo "Example: $0 akafinch v1.0.0"
  exit 1
fi

REGISTRY="$1"
TAG="${2:-latest}"
WORKER_IMAGE="$REGISTRY/clip-clap-worker:$TAG"
DEMO_IMAGE="$REGISTRY/clip-clap-demo:$TAG"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
TF_DIR="$ROOT_DIR/terraform"

echo "==> Images: $WORKER_IMAGE / $DEMO_IMAGE"

# ---- Phase 1: Read Terraform outputs ----
echo "==> Phase 1: Reading Terraform outputs"
cd "$TF_DIR"

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

for NS in ray-system default; do
  kubectl create configmap inference-config \
    --from-literal=ray-serve-url="http://clip-clap-serve-svc.ray-system:8000" \
    --from-literal=obj-endpoint="$OBJ_ENDPOINT" \
    --from-literal=model-bucket="$MODEL_BUCKET" \
    --namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
done

# ---- Phase 5: NVIDIA Device Plugin ----
echo "==> Phase 5: NVIDIA device plugin"
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.19.0/deployments/static/nvidia-device-plugin.yml
echo "    Waiting for device plugin pods on GPU nodes..."
kubectl -n kube-system wait --for=condition=Ready pod -l k8s-app=nvidia-device-plugin-cni --timeout=3m || \
  echo "    WARNING: Some device plugin pods may have failed on CPU nodes (expected)"

# ---- Phase 6: KubeRay Operator ----
echo "==> Phase 6: KubeRay operator"
helm repo add kuberay https://ray-project.github.io/kuberay-helm/ 2>/dev/null || true
helm repo update
helm upgrade --install kuberay-operator kuberay/kuberay-operator \
  --namespace ray-system \
  --version 1.6.0 \
  --wait --timeout 5m

# ---- Phase 7: RayService ----
echo "==> Phase 7: RayService (CLIP + CLAP)"
sed "s|WORKER_IMAGE_PLACEHOLDER|$WORKER_IMAGE|g" \
  "$ROOT_DIR/kubernetes/kuberay/rayservice-clip-clap.yaml" | kubectl apply -f -
echo "    Waiting for RayService pods..."
kubectl -n ray-system wait --for=condition=Ready pod -l ray.io/serve=clip-clap --timeout=10m || \
  echo "    WARNING: Timeout waiting for Ray pods — check 'kubectl -n ray-system get pods'"

# ---- Phase 8: Monitoring ----
echo "==> Phase 8: Monitoring stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add dcgm-exporter https://nvidia.github.io/dcgm-exporter/helm-charts 2>/dev/null || true
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set "grafana.adminPassword=$GRAFANA_PASSWORD" \
  -f "$ROOT_DIR/kubernetes/monitoring/prometheus-values.yaml" \
  --wait --timeout 5m

helm upgrade --install dcgm-exporter dcgm-exporter/dcgm-exporter \
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

# ---- Phase 9: Demo App ----
echo "==> Phase 9: Demo app"
sed "s|DEMO_IMAGE_PLACEHOLDER|$DEMO_IMAGE|g" \
  "$ROOT_DIR/kubernetes/demo-app/deployment.yaml" | kubectl apply -f -
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
echo "Grafana admin password: (run 'terraform -chdir=$TF_DIR output grafana_admin_password')"
echo "Ray dashboard: kubectl -n ray-system port-forward svc/clip-clap-head-svc 8265:8265"
echo ""
