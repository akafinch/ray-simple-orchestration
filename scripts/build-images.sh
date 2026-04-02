#!/usr/bin/env bash
set -euo pipefail

# Build and push Docker images for the CLIP/CLAP worker and demo app.
# Usage: ./scripts/build-images.sh [registry-prefix] [tag]
#
# Examples:
#   ./scripts/build-images.sh myorg                  # myorg/clip-clap-{worker,demo}:latest
#   ./scripts/build-images.sh myorg v1.0.0           # myorg/clip-clap-{worker,demo}:v1.0.0

if [ $# -lt 1 ]; then
  echo "Usage: $0 <docker-registry-prefix> [tag]"
  echo "Example: $0 akafinch v1.0.0"
  exit 1
fi

REGISTRY="$1"
TAG="${2:-latest}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

WORKER_IMAGE="$REGISTRY/clip-clap-worker:$TAG"
DEMO_IMAGE="$REGISTRY/clip-clap-demo:$TAG"

echo "==> Building Ray Serve worker image: $WORKER_IMAGE"
docker build -t "$WORKER_IMAGE" "$ROOT_DIR/app/ray_serve"

echo "==> Building demo app image: $DEMO_IMAGE"
docker build \
  -f "$ROOT_DIR/app/backend/Dockerfile" \
  -t "$DEMO_IMAGE" \
  "$ROOT_DIR/app"

echo "==> Pushing images..."
docker push "$WORKER_IMAGE"
docker push "$DEMO_IMAGE"

echo ""
echo "Done. Images pushed:"
echo "  $WORKER_IMAGE"
echo "  $DEMO_IMAGE"
