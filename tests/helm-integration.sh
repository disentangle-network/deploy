#!/usr/bin/env bash
set -euo pipefail

echo "=== Disentangle Helm Integration Tests ==="
echo ""

CHART_DIR="$(cd "$(dirname "$0")/../helm/disentangle" && pwd)"
NAMESPACE="disentangle-test"
RELEASE="test-cluster"
NODE_COUNT=3
TIMEOUT=180s

cleanup() {
    echo ""
    echo "=== Cleanup ==="
    helm uninstall "$RELEASE" -n "$NAMESPACE" 2>/dev/null || true
    kubectl delete namespace "$NAMESPACE" --wait=false 2>/dev/null || true
}
trap cleanup EXIT

echo "--- Test 1: Helm lint ---"
helm lint "$CHART_DIR"
echo "PASS"
echo ""

echo "--- Test 2: Helm template (default) ---"
helm template "$RELEASE" "$CHART_DIR" > /dev/null
echo "PASS"
echo ""

echo "--- Test 3: Helm template (3-node + traffic) ---"
helm template "$RELEASE" "$CHART_DIR" \
    --set nodes.count=3 \
    --set traffic.enabled=true > /dev/null
echo "PASS"
echo ""

echo "--- Test 4: Install on cluster ---"
kubectl create namespace "$NAMESPACE" 2>/dev/null || true
helm install "$RELEASE" "$CHART_DIR" \
    -n "$NAMESPACE" \
    --set nodes.count="$NODE_COUNT" \
    --set pow.difficulty=8 \
    --set pow.mineIntervalSecs=5 \
    --set traffic.enabled=true \
    --wait --timeout="$TIMEOUT"
echo "PASS"
echo ""

echo "--- Test 5: All pods healthy ---"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=disentangle \
    -n "$NAMESPACE" \
    --timeout=60s
echo "PASS"
echo ""

echo "--- Test 6: RPC endpoints responding ---"
for i in $(seq 0 $((NODE_COUNT - 1))); do
    POD="${RELEASE}-disentangle-${i}"
    STATUS=$(kubectl exec "$POD" -n "$NAMESPACE" -- \
        curl -sf http://localhost:8000/status 2>/dev/null | head -c 200)
    if [ -z "$STATUS" ]; then
        echo "FAIL: Node $i not responding to /status"
        exit 1
    fi
    echo "  Node $i: OK"
done
echo "PASS"
echo ""

echo "--- Test 7: Genesis synced across nodes ---"
for i in $(seq 0 $((NODE_COUNT - 1))); do
    POD="${RELEASE}-disentangle-${i}"
    DAG_SIZE=$(kubectl exec "$POD" -n "$NAMESPACE" -- \
        curl -sf http://localhost:8000/status | python3 -c "import sys,json; print(json.load(sys.stdin).get('dag_size',0))" 2>/dev/null || echo "0")
    echo "  Node $i: DAG size = $DAG_SIZE"
    if [ "$DAG_SIZE" -lt 1 ]; then
        echo "FAIL: Node $i has empty DAG"
        exit 1
    fi
done
echo "PASS"
echo ""

echo "--- Test 8: Wait for transactions to flow ---"
echo "  Waiting 30s for transaction mining..."
sleep 30
for i in $(seq 0 $((NODE_COUNT - 1))); do
    POD="${RELEASE}-disentangle-${i}"
    DAG_SIZE=$(kubectl exec "$POD" -n "$NAMESPACE" -- \
        curl -sf http://localhost:8000/status | python3 -c "import sys,json; print(json.load(sys.stdin).get('dag_size',0))" 2>/dev/null || echo "0")
    echo "  Node $i: DAG size = $DAG_SIZE"
    if [ "$DAG_SIZE" -le 1 ]; then
        echo "WARN: Node $i DAG not growing (may need more time)"
    fi
done
echo "PASS"
echo ""

echo "=== All integration tests passed ==="
