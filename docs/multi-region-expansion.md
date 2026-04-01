# Multi-Region Expansion Path

This document describes how to expand the single-region CLIP/CLAP inference deployment to a multi-region architecture. The v1 design is already parameterized for this — no architectural rewrites required.

## Design Principle: Independent Clusters, Global Routing

Each region runs an **independent, self-contained inference unit** — its own LKE cluster, Ray deployment, monitoring stack, and model cache. Cross-region Ray federation is explicitly avoided because actor scheduling across regions would add hundreds of milliseconds to inference latency.

## Step 1: Terraform Workspaces

The root `variables.tf` already parameterizes `region` and `obj_storage_region`. Use Terraform workspaces to manage one deployment per region:

```bash
# Create workspace per region
terraform workspace new us-ord
terraform workspace new eu-west

# Deploy to a specific region
terraform workspace select us-ord
terraform apply -var="region=us-ord" -var="obj_storage_region=us-ord-1"

terraform workspace select eu-west
terraform apply -var="region=eu-west" -var="obj_storage_region=eu-central-1"
```

Each workspace maintains independent state. The `cluster_label` should include the region to avoid naming collisions:

```hcl
variable "cluster_label" {
  default = "clip-clap-inference-${var.region}"
}
```

## Step 2: Akamai GTM (Global Traffic Management)

Add latency-based DNS routing via Akamai GTM. Each region's NodeBalancer IP becomes a GTM target:

- **GTM Property Type:** Performance (latency-based)
- **Targets:** One data center per region, each pointing at the demo-app LoadBalancer IP
- **Health Checks:** HTTP probe against `/health` on each region's NodeBalancer
- **Failover:** If a region's health check fails, GTM routes traffic to the next-nearest healthy region

GTM configuration is managed outside Terraform (via the Akamai GTM Terraform provider or the Akamai Control Center). Add a `gtm/` Terraform module when expanding.

## Step 3: Object Storage Replication

Model weights must be available in each region's Object Storage for fast init-container pulls:

- Option A: Run `upload-models.sh` targeting each region's bucket independently
- Option B: Use cross-region bucket replication if/when Linode Object Storage supports it
- Option C: Pull from a central bucket with acceptable cold-start penalty (~30s extra from cross-region)

The init container's `OBJ_ENDPOINT` ConfigMap value already drives which bucket endpoint is used — no code changes needed.

## Step 4: Per-Region Deploy

The deploy script runs per-workspace:

```bash
for region in us-ord eu-west; do
  terraform workspace select $region
  export KUBECONFIG="./kubeconfig-$region"
  ./scripts/deploy.sh
done
```

Each region's Kubernetes resources are fully independent — no cross-cluster references.

## Step 5: Monitoring Strategy

Two options for cross-region observability:

### Option A: Federated Prometheus (Thanos)
- Deploy Thanos sidecar alongside each region's Prometheus
- Central Thanos Query aggregates across all regions
- Single Grafana instance queries the central Thanos endpoint
- Dashboards automatically show all regions via label selectors

### Option B: Central Grafana with Multi-Datasource
- Each region's Prometheus exposed via internal endpoint
- Central Grafana adds each as a separate datasource
- Dashboards use datasource templating to switch between regions

Thanos is the production-grade path. Multi-datasource is simpler for a demo expansion.

## Step 6: Secrets Management

For v1, secrets flow via Terraform outputs → deploy script → kubectl. At multi-region scale, adopt:

- **HashiCorp Vault** with per-region auth backends
- **Sealed Secrets** or **External Secrets Operator** pointing at a central secret store
- **Akamai Secrets Manager** if/when available on the platform

## What NOT to Do

- **Do not federate Ray clusters across regions.** Ray's actor model assumes low-latency networking. Cross-region scheduling would negate the performance benefit of GPU inference.
- **Do not share a single LKE cluster across regions.** LKE clusters are region-scoped. Each region must have its own cluster.
- **Do not use a single Object Storage bucket for all regions.** Cross-region pulls add latency to pod startup and create a single point of failure.

## Cost Projection

Per additional region (same 3x RTX 4000 Ada config):

| Component | Monthly Cost |
|---|---|
| 3x g2-gpu-rtx4000a1-s | $1,050 |
| 2x g6-standard-4 (CPU) | ~$80 |
| Object Storage (model cache) | ~$5 |
| NodeBalancer | ~$10 |
| GTM (incremental) | Varies by contract |
| **Total per region** | **~$1,145** |
