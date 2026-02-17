#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="$(cd "$SCRIPT_DIR/../../helm/disentangle" && pwd)"
GOLDEN_DIR="$SCRIPT_DIR"
FAILURES=0

compare() {
    local name="$1"
    shift
    local actual
    actual=$(helm template golden-test "$CHART_DIR" "$@" 2>&1)

    if [ ! -f "$GOLDEN_DIR/$name.yaml" ]; then
        echo "FAIL: Golden file $name.yaml does not exist. Run update.sh first."
        FAILURES=$((FAILURES + 1))
        return
    fi

    if ! diff -u "$GOLDEN_DIR/$name.yaml" <(echo "$actual") > /dev/null 2>&1; then
        echo "FAIL: $name.yaml differs from golden file"
        echo ""
        echo "Diff output:"
        diff -u "$GOLDEN_DIR/$name.yaml" <(echo "$actual") | head -50 || true
        echo ""
        FAILURES=$((FAILURES + 1))
    else
        echo "PASS: $name"
    fi
}

echo "=== Golden File Regression Tests ==="
echo ""
echo "Chart: $CHART_DIR"
echo "Golden files: $GOLDEN_DIR"
echo ""

# Default configuration
compare "default"

# Minimal 3-node dev setup
compare "minimal" \
    --set nodes.count=3 \
    --set persistence.enabled=false \
    --set pow.difficulty=8

# All features enabled
compare "full-features" \
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
compare "no-serviceaccount" \
    --set serviceAccount.create=false

# Custom resource limits (using values file to preserve string types)
compare "custom-resources" \
    -f "$GOLDEN_DIR/custom-resources-values.yaml"

echo ""
if [ "$FAILURES" -gt 0 ]; then
    echo "=== $FAILURES golden file test(s) FAILED ==="
    echo ""
    echo "If changes are intentional, run:"
    echo "  $SCRIPT_DIR/update.sh"
    echo ""
    exit 1
else
    echo "=== All golden file tests passed ==="
fi
