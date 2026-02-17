# Disentangle Protocol - Installation Guide

Quick start guide for deploying the Disentangle Protocol network using Helm.

## Prerequisites

- Kubernetes cluster (1.20+)
- Helm 3.x
- kubectl configured to access your cluster
- At least 5Gi of persistent storage available (1Gi per node with default 5 nodes)

## Quick Install

```bash
# Navigate to the Helm chart directory
cd /Users/lclose/DISENTANGLE-NETWORK/deploy/helm

# Install with default settings (5 nodes)
helm install disentangle ./disentangle

# Wait for nodes to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=disentangle --timeout=300s
```

## Verify Installation

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=disentangle

# Expected output:
# NAME            READY   STATUS    RESTARTS   AGE
# disentangle-0   1/1     Running   0          2m
# disentangle-1   1/1     Running   0          2m
# disentangle-2   1/1     Running   0          2m
# disentangle-3   1/1     Running   0          2m
# disentangle-4   1/1     Running   0          2m

# Test RPC endpoint
kubectl port-forward svc/disentangle-rpc 8000:8000 &
curl http://localhost:8000/status
curl http://localhost:8000/graph
```

## Common Configurations

### Minimal Development Setup (3 nodes)

```bash
helm install disentangle ./disentangle \
  --set nodes.count=3 \
  --set resources.limits.cpu=250m \
  --set resources.limits.memory=256Mi
```

### Production Setup (10 nodes with persistence)

```bash
helm install disentangle ./disentangle \
  --set nodes.count=10 \
  --set persistence.size=5Gi \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi \
  --set resources.requests.cpu=250m \
  --set resources.requests.memory=256Mi
```

### With Traffic Generator (for testing)

```bash
helm install disentangle ./disentangle \
  --set traffic.enabled=true \
  --set traffic.interval="*/2 * * * *" \
  --set traffic.txCount=20
```

### With External Access (Ingress)

```bash
helm install disentangle ./disentangle \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=disentangle.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix
```

## Custom Values File

Create a `custom-values.yaml`:

```yaml
nodes:
  count: 7

persistence:
  size: 2Gi

resources:
  limits:
    cpu: 750m
    memory: 768Mi
  requests:
    cpu: 200m
    memory: 256Mi

traffic:
  enabled: true
  interval: "*/3 * * * *"
  txCount: 15

consensus:
  confirmationDepth: 8
  curvatureMethod: jaccard

pow:
  difficulty: 18
```

Install with custom values:

```bash
helm install disentangle ./disentangle -f custom-values.yaml
```

## Testing Network Health

```bash
# Test bootstrap node (node-0)
kubectl exec disentangle-0 -- wget -qO- http://localhost:8000/status

# Test follower node (node-1)
kubectl exec disentangle-1 -- wget -qO- http://localhost:8000/status

# View DAG structure
kubectl exec disentangle-0 -- wget -qO- http://localhost:8000/graph

# Check P2P connectivity (node logs)
kubectl logs disentangle-0 | grep -i "peer"
kubectl logs disentangle-1 | grep -i "peer"
```

## Scaling the Network

```bash
# Scale up to 10 nodes
helm upgrade disentangle ./disentangle --set nodes.count=10

# Scale down to 3 nodes (will delete nodes 3-9)
helm upgrade disentangle ./disentangle --set nodes.count=3
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade disentangle ./disentangle --set nodes.count=7

# Rollback to previous release
helm rollback disentangle
```

## Monitoring

```bash
# Watch pod status
kubectl get pods -l app.kubernetes.io/name=disentangle -w

# Stream logs from all nodes
kubectl logs -f -l app.kubernetes.io/name=disentangle --all-containers=true

# Stream logs from specific node
kubectl logs -f disentangle-0

# View transaction generator logs
kubectl logs -l app.kubernetes.io/component=txgen
```

## Troubleshooting

### Pods not starting

```bash
# Check pod events
kubectl describe pod disentangle-0

# Check persistent volume claims
kubectl get pvc -l app.kubernetes.io/name=disentangle

# Check storage class
kubectl get storageclass
```

### Network connectivity issues

```bash
# Check headless service
kubectl get svc disentangle-headless
kubectl get endpoints disentangle-headless

# Test DNS resolution from within a pod
kubectl exec disentangle-1 -- nslookup disentangle-0.disentangle-headless

# Test P2P connectivity
kubectl exec disentangle-1 -- nc -zv disentangle-0.disentangle-headless 9000
```

### RPC endpoint not responding

```bash
# Check RPC service
kubectl get svc disentangle-rpc

# Test from within cluster
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://disentangle-rpc:8000/status

# Check node logs for errors
kubectl logs disentangle-0 | grep -i error
```

### Storage issues

```bash
# Check PVC status
kubectl get pvc

# Describe PVC for events
kubectl describe pvc data-disentangle-0

# Check if storage class supports dynamic provisioning
kubectl describe storageclass

# Manual PVC creation (if needed)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-disentangle-0
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
EOF
```

## Uninstalling

```bash
# Uninstall the chart
helm uninstall disentangle

# Delete persistent volume claims (optional - data will be lost)
kubectl delete pvc -l app.kubernetes.io/name=disentangle

# Verify cleanup
kubectl get all -l app.kubernetes.io/name=disentangle
```

## Next Steps

- Configure ingress for external access
- Enable transaction generator for load testing
- Integrate with monitoring tools (Prometheus, Grafana)
- Set up backup for persistent volumes
- Configure resource quotas for production

For more information, see the [README.md](README.md).
