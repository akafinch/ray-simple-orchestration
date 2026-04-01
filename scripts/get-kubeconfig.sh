#!/usr/bin/env bash
set -euo pipefail

# Extract kubeconfig from Terraform state and write to a local file.
# Usage: ./scripts/get-kubeconfig.sh [output-path]

OUTPUT="${1:-./kubeconfig}"

echo "==> Extracting kubeconfig from Terraform state..."
cd "$(dirname "$0")/../terraform"
terraform output -raw kubeconfig | base64 -d > "$OUTPUT"
chmod 600 "$OUTPUT"

echo "==> Kubeconfig written to $OUTPUT"
echo "    export KUBECONFIG=$OUTPUT"
