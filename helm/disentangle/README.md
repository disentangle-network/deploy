# Disentangle Protocol Helm Chart

Helm chart for deploying a Disentangle Protocol network on Kubernetes.

## Features

- StatefulSet deployment for stable network topology
- Automatic bootstrap node configuration (node-0)
- Persistent storage for node identity state
- RPC service with optional ingress
- Optional transaction generator CronJob for testing
- Configurable consensus and PoW parameters
- Security hardening with PSP and non-root containers

## Installation

```bash
# Install with default values (5 nodes)
helm install disentangle ./disentangle

# Install with custom node count
helm install disentangle ./disentangle --set nodes.count=10

# Install with traffic generator enabled
helm install disentangle ./disentangle --set traffic.enabled=true
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `ghcr.io/disentangle-network/disentangle-node` |
| `image.tag` | Container image tag | `Chart.appVersion` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `nodes.count` | Number of nodes in the network | `5` |
| `nodes.p2pPort` | P2P communication port | `9000` |
| `nodes.rpcPort` | HTTP RPC port | `8000` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Persistent volume size | `1Gi` |
| `persistence.storageClass` | Storage class name | `""` (default) |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `serviceAccount.create` | Create service account | `true` |
| `rpcService.type` | RPC service type | `ClusterIP` |
| `rpcService.port` | RPC service port | `8000` |
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `traffic.enabled` | Enable transaction generator | `false` |
| `traffic.interval` | CronJob schedule | `*/5 * * * *` |
| `traffic.txCount` | Transactions per run | `10` |
| `consensus.bootstrapStart` | Bootstrap start parameter | `1000` |
| `consensus.bootstrapEnd` | Bootstrap end parameter | `6000` |
| `consensus.confirmationDepth` | Confirmation depth | `6` |
| `consensus.curvatureMethod` | Curvature method | `jaccard` |
| `consensus.fixedPointScale` | Fixed point scale | `65536` |
| `pow.difficulty` | PoW difficulty | `16` |
| `pow.mineIntervalSecs` | Mining interval in seconds | `10` |

## Network Architecture

The chart deploys a Disentangle Protocol network with the following components:

- **Bootstrap Node (node-0)**: First node that starts without a bootstrap peer
- **Follower Nodes (node-1 to node-N)**: Connect to node-0 via libp2p multiaddr
- **Headless Service**: Provides stable DNS for StatefulSet pods
- **RPC Service**: Load balances RPC requests across all nodes
- **Transaction Generator**: Optional CronJob for testing network load

## Accessing the Network

### Internal Access (within cluster)

```bash
# Access RPC service
curl http://disentangle-rpc:8000/status

# Access specific node
curl http://disentangle-0.disentangle-headless:8000/status
```

### External Access (with ingress)

```bash
# Enable ingress
helm upgrade disentangle ./disentangle --set ingress.enabled=true \
  --set 'ingress.hosts[0].host=disentangle.example.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix'

# Access via ingress
curl https://disentangle.example.com/status
```

## Testing with Transaction Generator

```bash
# Enable traffic generator
helm upgrade disentangle ./disentangle --set traffic.enabled=true

# View generated transactions
kubectl logs job/disentangle-txgen-<timestamp>
```

## Monitoring

```bash
# Check node status
kubectl get pods -l app.kubernetes.io/name=disentangle

# View node logs
kubectl logs -f disentangle-0

# Check RPC endpoint
kubectl port-forward svc/disentangle-rpc 8000:8000
curl http://localhost:8000/status
```

## Scaling

```bash
# Scale to 10 nodes
helm upgrade disentangle ./disentangle --set nodes.count=10

# Scale down to 3 nodes
helm upgrade disentangle ./disentangle --set nodes.count=3
```

## Uninstall

```bash
helm uninstall disentangle

# Delete PVCs (if needed)
kubectl delete pvc -l app.kubernetes.io/name=disentangle
```

## License

Apache-2.0
