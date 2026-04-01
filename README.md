# CLIP/CLAP Inference Network on Akamai LKE + KubeRay

A production-patterned multimodal embedding inference service running on Akamai's Linode GPU infrastructure. Submit text, images, or audio and receive embedding vectors in real time from CLIP and CLAP models served on GPU via Ray Serve.

## What This Builds

- **LKE Kubernetes cluster** with dedicated CPU and GPU node pools (3x RTX 4000 Ada)
- **Ray Serve** deployments for [CLIP](https://huggingface.co/openai/clip-vit-large-patch14) (text + image embeddings) and [CLAP](https://huggingface.co/laion/clap-htsat-unfused) (audio embeddings), managed by the KubeRay operator
- **FastAPI backend** proxying inference requests to Ray Serve and exposing a REST API
- **Web UI** with a live embedding visualizer, cosine similarity demo, embedded Grafana metrics dashboard, and an architecture diagram
- **Monitoring stack** with Prometheus, Grafana, and NVIDIA DCGM exporter for GPU-level observability
- **Fully parameterized Terraform** with a documented path to multi-region expansion via Akamai GTM

```
User → NodeBalancer :80 → FastAPI → Ray Serve → GPU Workers (CLIP / CLAP)
                                                    ↑
                                          Model weights from
                                         Linode Object Storage
```

## Architecture

| Component | Runs On | Details |
|---|---|---|
| Ray Head + KubeRay Operator | CPU pool (2x g6-standard-4) | Scheduler only, no compute |
| CLIP (2 replicas) | GPU pool (2 of 3 RTX 4000 Ada nodes) | `openai/clip-vit-large-patch14`, 768-dim embeddings |
| CLAP (1 replica) | GPU pool (1 of 3 RTX 4000 Ada nodes) | `laion/clap-htsat-unfused`, 512-dim embeddings |
| Demo App | CPU pool | FastAPI + SvelteKit static frontend |
| Prometheus + Grafana | CPU pool | Ray Serve metrics + DCGM GPU metrics |
| Model Weights | Linode Object Storage (S3-compatible) | Pulled by init containers at pod startup |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3.x
- [Docker](https://docs.docker.com/get-docker/) (for building images)
- [linode-cli](https://www.linode.com/docs/products/tools/cli/get-started/) configured with a valid API token
- [huggingface-cli](https://huggingface.co/docs/huggingface_hub/guides/cli) (for downloading model weights)
- A [Linode API token](https://cloud.linode.com/profile/tokens) with full access
- A [Docker Hub](https://hub.docker.com/) account (or substitute your own registry)

## Quick Start

### 1. Configure

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars — set your linode_token and optionally operator_ips
```

### 2. Build and Push Docker Images

```bash
./scripts/build-images.sh <your-dockerhub-username>
```

This builds two images:
- `<username>/clip-clap-worker` — Ray head + GPU workers (based on `rayproject/ray:2.54.0-gpu`)
- `<username>/clip-clap-demo` — FastAPI backend + SvelteKit frontend

> If using a custom registry prefix, update the image references in `kubernetes/kuberay/rayservice-clip-clap.yaml` and `kubernetes/demo-app/deployment.yaml` to match.

### 3. Provision Infrastructure

```bash
cd terraform
terraform init
terraform apply
cd ..
```

This creates:
- VPC with private subnet and Cloud Firewall
- LKE cluster with CPU + GPU node pools
- Object Storage bucket and access keys

### 4. Upload Model Weights

```bash
./scripts/upload-models.sh
```

Downloads CLIP and CLAP from HuggingFace and uploads to the Object Storage bucket. This is a one-time step (~4GB transfer).

### 5. Deploy the Full Stack

```bash
./scripts/deploy.sh
```

This runs through 8 phases: kubeconfig extraction, namespace creation, secrets, KubeRay operator, RayService, monitoring stack (Prometheus + Grafana + DCGM), and the demo app. At the end it prints the external LoadBalancer IPs.

### 6. Access the Demo

```bash
# Get the demo app external IP
kubectl get svc demo-app-svc

# Get the Grafana external IP (admin password from Terraform)
kubectl get svc -n monitoring kube-prometheus-stack-grafana
terraform -chdir=terraform output grafana_admin_password
```

Open the demo app IP in a browser. The web UI provides:
- **Embed panel** — submit text, images, or audio and see the resulting embedding vector visualized as a waveform and 2D scatter plot
- **Similarity demo** — compare two texts and watch the cosine similarity score animate
- **Live metrics** — embedded Grafana dashboard showing Ray Serve throughput, latency, and GPU utilization
- **Architecture diagram** — SVG rendering of the deployed infrastructure

## API Reference

| Endpoint | Method | Description |
|---|---|---|
| `/embed/text` | POST | `{"text": "..."}` → CLIP embedding (768-dim) |
| `/embed/image` | POST | Multipart image upload → CLIP embedding |
| `/embed/audio` | POST | Multipart audio upload → CLAP embedding |
| `/similarity` | POST | `{"a": [...], "b": [...]}` → cosine similarity score |
| `/health` | GET | Liveness check + Ray Serve reachability |
| `/config` | GET | Runtime config (Ray Serve URL, Grafana URL) |
| `/metrics` | GET | Prometheus metrics |

## Teardown

```bash
./scripts/teardown.sh
```

Removes all Kubernetes resources in reverse order, then destroys the Terraform infrastructure.

## Project Structure

```
terraform/              Linode infrastructure (VPC, LKE, Object Storage)
kubernetes/
  kuberay/              RayService CRD (consolidated cluster + serve config)
  monitoring/           Prometheus + DCGM Helm values, Grafana dashboard JSON
  demo-app/             FastAPI deployment, service, shared ConfigMap
app/
  ray_serve/            CLIP + CLAP Ray Serve deployments, worker Dockerfile
  backend/              FastAPI app, routes, demo app Dockerfile
  frontend/             SvelteKit UI (static build served by FastAPI)
scripts/                Build, deploy, upload, teardown, kubeconfig scripts
docs/                   Multi-region expansion documentation
```

## Multi-Region Expansion

The deployment is parameterized for multi-region from day one. See [docs/multi-region-expansion.md](docs/multi-region-expansion.md) for the full expansion path using Terraform workspaces and Akamai GTM.

## Key Versions

| Component | Version |
|---|---|
| Ray | 2.54.0 |
| KubeRay Operator | 1.6.0 |
| Kubernetes (LKE) | 1.35 |
| Linode Terraform Provider | ~> 3.8 |
| Python | 3.11 |
| Node.js | 20 |
