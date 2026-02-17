#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="$(cd "$SCRIPT_DIR/../../helm/disentangle" && pwd)"
GOLDEN_DIR="$SCRIPT_DIR"

echo "=== Updating Golden Files ==="
echo ""
echo "Chart: $CHART_DIR"
echo "Output: $GOLDEN_DIR"
echo ""

update() {
    local name="$1"
    shift
    echo "Updating $name.yaml..."

    local actual
    actual=$(helm template golden-test "$CHART_DIR" "$@" 2>&1)

    echo "$actual" > "$GOLDEN_DIR/$name.yaml"
    echo "  ✓ Written $(wc -l < "$GOLDEN_DIR/$name.yaml") lines"
}

# Default configuration
update "default"

# Minimal 3-node dev setup
update "minimal" \
    --set nodes.count=3 \
    --set persistence.enabled=false \
    --set pow.difficulty=8

# All features enabled
update "full-features" \
    --set nodes.count=7 \
    --set traffic.enabled=true \
    --set ingress.enabled=true \
    --set 'ingress.hosts[0].host=disentangle.example.com' \
    --set 'ingress.hosts[0].paths[0].path=/' \
    --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
    --set ingress.className=nginx \
    --set rpcService.type=LoadBalancer \
    --set persistence.size=10Gi

# ServiceAccount disabled
update "no-serviceaccount" \
    --set serviceAccount.create=false

# Custom resource limits (using values file to preserve string types)
update "custom-resources" \
    -f "$GOLDEN_DIR/custom-resources-values.yaml"

echo ""
echo "=== All golden files updated ==="
echo ""
echo "Files updated:"
for f in "$GOLDEN_DIR"/*.yaml; do
    [[ "$f" == *values.yaml ]] && continue
    printf "  - %s (%s)\n" "$f" "$(du -h "$f" | cut -f1)"
done
