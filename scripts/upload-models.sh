#!/usr/bin/env bash
set -euo pipefail

# Download CLIP + CLAP model weights from HuggingFace and upload to Linode Object Storage.
# Requires: terraform outputs available, s5cmd installed, hf CLI (pip install huggingface_hub).
# Usage: ./scripts/upload-models.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"

echo "==> Reading Object Storage credentials from Terraform..."
cd "$TF_DIR"
OBJ_ENDPOINT=$(terraform output -raw obj_endpoint)
OBJ_BUCKET=$(terraform output -raw model_bucket)
export AWS_ACCESS_KEY_ID=$(terraform output -raw obj_writer_key)
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw obj_writer_secret)
export S3_ENDPOINT_URL="$OBJ_ENDPOINT"

echo "    Endpoint: $OBJ_ENDPOINT"
echo "    Bucket:   $OBJ_BUCKET"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

echo "==> Downloading CLIP model (openai/clip-vit-large-patch14)..."
hf download openai/clip-vit-large-patch14 \
  --local-dir "$WORK_DIR/clip/clip-vit-large-patch14"

echo "==> Downloading CLAP model (laion/clap-htsat-unfused)..."
hf download laion/clap-htsat-unfused \
  --local-dir "$WORK_DIR/clap/clap-htsat-unfused"

echo "==> Uploading to Object Storage..."
s5cmd sync "$WORK_DIR/clip/" "s3://$OBJ_BUCKET/clip/"
s5cmd sync "$WORK_DIR/clap/" "s3://$OBJ_BUCKET/clap/"

echo "==> Upload complete. Bucket contents:"
s5cmd ls "s3://$OBJ_BUCKET/*" | head -20
echo "    ..."
