#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="$(cd "$SCRIPT_DIR/../../helm/disentangle" && pwd)"
POLICY_DIR="$SCRIPT_DIR"

echo "=== OPA Conftest Policy Tests ==="
echo ""

# Render chart and split into individual documents
RENDERED=$(helm template policy-test "$CHART_DIR")

echo "--- Testing default configuration ---"
echo "$RENDERED" | conftest test --policy "$POLICY_DIR" -

echo ""
echo "--- Testing with traffic enabled ---"
helm template policy-test "$CHART_DIR" --set traffic.enabled=true | \
    conftest test --policy "$POLICY_DIR" -

echo ""
echo "--- Testing with all features ---"
helm template policy-test "$CHART_DIR" \
    --set traffic.enabled=true \
    --set ingress.enabled=true \
    --set 'ingress.hosts[0].host=test.example.com' \
    --set 'ingress.hosts[0].paths[0].path=/' \
    --set 'ingress.hosts[0].paths[0].pathType=Prefix' | \
    conftest test --policy "$POLICY_DIR" -

echo ""
echo "=== All policy tests passed ==="
