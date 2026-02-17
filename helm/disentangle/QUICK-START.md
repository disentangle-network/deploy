# Disentangle Protocol - Quick Start

## One-Line Install

```bash
cd /Users/lclose/DISENTANGLE-NETWORK/deploy/helm && helm install disentangle ./disentangle
```

## Essential Commands

```bash
# Install
helm install disentangle ./disentangle

# Check status
kubectl get pods -l app.kubernetes.io/name=disentangle

# Test network
kubectl port-forward svc/disentangle-rpc 8000:8000 &
curl http://localhost:8000/status
curl http://localhost:8000/graph

# View logs
kubectl logs -f disentangle-0

# Upgrade
helm upgrade disentangle ./disentangle --set nodes.count=7

# Uninstall
helm uninstall disentangle
```

## Common Configurations

### Development (3 nodes, minimal resources)
```bash
helm install disentangle ./disentangle \
  --set nodes.count=3 \
  --set resources.limits.memory=256Mi
```

### Testing (with traffic generator)
```bash
helm install disentangle ./disentangle \
  --set traffic.enabled=true
```

### Production (10 nodes, high availability)
```bash
helm install disentangle ./disentangle \
  --set nodes.count=10 \
  --set persistence.size=5Gi \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi
```

## RPC Endpoints

Once port-forwarding is active (`kubectl port-forward svc/disentangle-rpc 8000:8000`):

```bash
# Node status
curl http://localhost:8000/status

# DAG structure
curl http://localhost:8000/graph

# Submit transaction
curl -X POST http://localhost:8000/transaction \
  -H "Content-Type: application/json" \
  -d '{"from":"alice","to":"bob","amount":100}'

# Identity endpoints
curl http://localhost:8000/identity/list
curl http://localhost:8000/identity/create

# Capability endpoints
curl http://localhost:8000/capability/list
curl http://localhost:8000/capability/grant

# Governance endpoints
curl http://localhost:8000/governance/proposals
curl http://localhost:8000/governance/vote
```

## Troubleshooting

### Pods not ready?
```bash
kubectl describe pod disentangle-0
kubectl logs disentangle-0
```

### Need to reset?
```bash
helm uninstall disentangle
kubectl delete pvc -l app.kubernetes.io/name=disentangle
helm install disentangle ./disentangle
```

### Check network connectivity?
```bash
kubectl exec disentangle-1 -- nslookup disentangle-0.disentangle-headless
kubectl logs disentangle-0 | grep -i peer
```

## File Locations

- Chart definition: `Chart.yaml`
- Default values: `values.yaml`
- Templates: `templates/`
- Full documentation: `README.md`
- Detailed install guide: `INSTALL.md`
