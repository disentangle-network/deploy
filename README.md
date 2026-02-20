# Disentangle Deploy

[![Helm CI](https://github.com/disentangle-network/deploy/actions/workflows/helm-ci.yml/badge.svg)](https://github.com/disentangle-network/deploy/actions/workflows/helm-ci.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Single-config cluster deployment for [Disentangle Protocol](https://github.com/disentangle-network/protocol) networks.

## Overview

This repository provides Helm charts, FluxCD overlays, and CI/CD pipelines for deploying Disentangle Protocol nodes to Kubernetes. It replaces the previous Fabric deployment overlay with native Disentangle support.

### Pipeline Position

```
yubikey-init -> genesis-operator -> oci-tf-bootstrap -> k8s-oci-foundation -> disentangle-deploy
```

This repo consumes a Kubernetes cluster with FluxCD (from k8s-oci-foundation) and deploys a Disentangle network on top.

## Quick Start

All commands assume you are in the `deploy/` directory.

### Local Development (Docker Compose)

For local development, use the Docker Compose setup in the [protocol repo](https://github.com/disentangle-network/protocol):

```bash
cd ../protocol
docker compose up
```

### Kubernetes (Helm)

```bash
# From the deploy/ directory
helm install disentangle ./helm/disentangle/ \
    --namespace disentangle --create-namespace \
    --set nodes.count=5
```

### Kubernetes (FluxCD GitOps)

Apply the appropriate overlay for your environment:

```bash
# Dev (3 nodes, traffic enabled)
kubectl apply -k gitops/overlays/dev/

# Staging (5 nodes)
kubectl apply -k gitops/overlays/staging/

# Production (7 nodes)
kubectl apply -k gitops/overlays/production/
```

## Architecture

All Disentangle nodes are identical except node-0, which serves as the bootstrap peer. The Helm chart uses a StatefulSet with a headless Service for peer discovery via DNS.

```
                    ┌─────────────────┐
                    │   Ingress/LB    │
                    │   (RPC access)  │
                    └────────┬────────┘
                             │ :8000
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────┴─────┐ ┌─────┴─────┐ ┌─────┴─────┐
        │  node-0   │ │  node-1   │ │  node-2   │
        │(bootstrap)│ │(follower) │ │(follower) │
        │ P2P:9000  │ │ P2P:9000  │ │ P2P:9000  │
        │ RPC:8000  │ │ RPC:8000  │ │ RPC:8000  │
        └─────┬─────┘ └─────┬─────┘ └─────┬─────┘
              │              │              │
              └──────────────┴──────────────┘
                     Headless Service
                   (P2P peer discovery)
```

## Configuration

See `helm/disentangle/values.yaml` for all available configuration options.

### Core Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `nodes.count` | 5 | Number of nodes in the network |
| `nodes.p2pPort` | 9000 | P2P networking port |
| `nodes.rpcPort` | 8000 | HTTP RPC port |
| `persistence.enabled` | true | Enable persistent storage |
| `persistence.size` | 1Gi | Storage size per node |
| `persistence.storageClass` | "" | Storage class (defaults to cluster default) |

### Container Image

| Parameter | Default | Description |
|-----------|---------|-------------|
| `image.repository` | ghcr.io/disentangle-network/disentangle-node | Container image repository |
| `image.tag` | "" | Image tag (defaults to Chart appVersion: 0.3.0) |
| `image.pullPolicy` | IfNotPresent | Image pull policy |

### Resources

| Parameter | Default | Description |
|-----------|---------|-------------|
| `resources.limits.cpu` | 500m | CPU limit per node |
| `resources.limits.memory` | 512Mi | Memory limit per node |
| `resources.requests.cpu` | 100m | CPU request per node |
| `resources.requests.memory` | 128Mi | Memory request per node |

### Traffic Generator

| Parameter | Default | Description |
|-----------|---------|-------------|
| `traffic.enabled` | false | Enable transaction generator CronJob |
| `traffic.interval` | "*/5 * * * *" | Cron schedule (every 5 minutes) |
| `traffic.txCount` | 10 | Number of transactions per run |

### Consensus Protocol

| Parameter | Default | Description |
|-----------|---------|-------------|
| `consensus.bootstrapStart` | 1000 | Bootstrap period start (generations) |
| `consensus.bootstrapEnd` | 6000 | Bootstrap period end (generations) |
| `consensus.confirmationDepth` | 6 | Descendant depth window for finality assessment |
| `consensus.curvatureMethod` | jaccard | Curvature calculation method |
| `consensus.fixedPointScale` | 65536 | Fixed-point arithmetic scale factor |

### Proof-of-Work

| Parameter | Default | Description |
|-----------|---------|-------------|
| `pow.difficulty` | 16 | Proof of Work difficulty bits |
| `pow.mineIntervalSecs` | 10 | Target mining interval in seconds |

### Networking

| Parameter | Default | Description |
|-----------|---------|-------------|
| `rpcService.type` | ClusterIP | RPC Service type |
| `rpcService.port` | 8000 | RPC Service port |
| `ingress.enabled` | false | Enable Ingress for external RPC access |

## Structure

```
deploy/
├── helm/disentangle/              # Helm chart
│   ├── Chart.yaml                 # Chart metadata (v0.1.0, appVersion 0.3.0)
│   ├── values.yaml                # Default configuration values
│   ├── templates/                 # Kubernetes manifests
│   │   ├── statefulset.yaml       # Node StatefulSet
│   │   ├── service-headless.yaml  # P2P discovery service
│   │   ├── service-rpc.yaml       # RPC access service
│   │   ├── configmap.yaml         # Configuration data
│   │   ├── serviceaccount.yaml    # RBAC service account
│   │   ├── ingress.yaml           # Optional external access
│   │   ├── cronjob-txgen.yaml     # Transaction generator
│   │   └── tests/                 # Helm test hooks
│   │       ├── test-connection.yaml
│   │       ├── test-genesis-sync.yaml
│   │       └── test-rpc-api.yaml
│   └── tests/                     # Chart test directory
│       └── __snapshot__/          # Test snapshots
├── gitops/                        # FluxCD overlays
│   ├── base/                      # Base Kustomize resources
│   └── overlays/                  # Environment-specific configs
│       ├── dev/                   # 3 nodes, traffic enabled
│       ├── staging/               # 5 nodes
│       └── production/            # 7 nodes
├── tests/                         # Integration tests
│   ├── helm-integration.sh        # End-to-end test script
│   ├── golden/                    # Golden template snapshots
│   │   ├── default.yaml
│   │   ├── full-features.yaml
│   │   ├── custom-resources.yaml
│   │   ├── minimal.yaml
│   │   └── no-serviceaccount.yaml
│   └── policies/                  # Policy-as-code tests
├── .github/workflows/             # CI/CD pipelines
├── .kube-linter.yaml              # Kubernetes manifest linting
├── .pre-commit-config.yaml        # Pre-commit hooks
├── .yamllint                      # YAML linting rules
├── Makefile                       # Common development tasks
└── renovate.json                  # Dependency management
```

## Testing

```bash
# Lint and template validation
helm lint helm/disentangle/
helm template test helm/disentangle/

# Full integration test (requires a Kubernetes cluster)
./tests/helm-integration.sh
```

## License

Apache-2.0
