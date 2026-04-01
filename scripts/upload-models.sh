#!/usr/bin/env bash
set -euo pipefail

# Download CLIP + CLAP model weights from HuggingFace and upload to Linode Object Storage.
# Requires: terraform outputs available, s5cmd or aws-cli installed, huggingface-cli installed.
# Usage: ./scripts/upload-models.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"

echo "==> Reading Object Storage credentials from Terraform..."
cd "$TF_DIR"
OBJ_ENDPOINT=$(terraform output -raw obj_endpoint)
OBJ_BUCKET=$(terraform output -raw model_bucket)
export AWS_ACCESS_KEY_ID=$(terraform output -raw obj_writer_key)
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw obj_writer_secret)

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

echo "==> Downloading CLIP model (openai/clip-vit-large-patch14)..."
huggingface-cli download openai/clip-vit-large-patch14 \
  --local-dir "$WORK_DIR/clip/clip-vit-large-patch14" \
  --local-dir-use-symlinks False

echo "==> Downloading CLAP model (laion/clap-htsat-unfused)..."
huggingface-cli download laion/clap-htsat-unfused \
  --local-dir "$WORK_DIR/clap/clap-htsat-unfused" \
  --local-dir-use-symlinks False

echo "==> Uploading to Object Storage ($OBJ_ENDPOINT/$OBJ_BUCKET)..."
if command -v s5cmd &>/dev/null; then
  echo "    Using s5cmd (fast parallel upload)"
  export S3_ENDPOINT_URL="$OBJ_ENDPOINT"
  s5cmd sync "$WORK_DIR/clip/" "s3://$OBJ_BUCKET/clip/"
  s5cmd sync "$WORK_DIR/clap/" "s3://$OBJ_BUCKET/clap/"
else
  echo "    Using aws-cli (install s5cmd for faster uploads)"
  aws s3 sync "$WORK_DIR/clip/" "s3://$OBJ_BUCKET/clip/" \
    --endpoint-url "$OBJ_ENDPOINT"
  aws s3 sync "$WORK_DIR/clap/" "s3://$OBJ_BUCKET/clap/" \
    --endpoint-url "$OBJ_ENDPOINT"
fi

echo "==> Upload complete. Bucket contents:"
aws s3 ls "s3://$OBJ_BUCKET/" --endpoint-url "$OBJ_ENDPOINT" --recursive | head -20
echo "    ..."
