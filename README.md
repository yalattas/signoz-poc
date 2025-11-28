# SigNoz Deployment on Kind

This repository contains configuration files for deploying SigNoz (an open-source observability platform) on a local Kubernetes cluster using Kind (Kubernetes in Docker).

## Prerequisites

Before starting, ensure you have the following tools installed on your local machine:

- **Docker** - Container runtime
- **Kind** - Kubernetes in Docker
- **Helm** - Kubernetes package manager
- **Helmfile** - Declarative spec for deploying helm charts
- **kubectl** - Kubernetes CLI
- **k9s** (optional) - Terminal UI for Kubernetes cluster visualization

## Architecture Overview

This deployment consists of:
- **ClickHouse Operator** - Manages ClickHouse clusters in Kubernetes
- **ClickHouse Cluster** - Time-series database for storing observability data
- **SigNoz** - Observability platform (metrics, traces, logs)
- **OpenTelemetry Demo** (optional) - Sample ecommerce application for testing

---

## Setup Instructions

### Step 1: Create Kind Cluster

```bash
kind create cluster --name signoz
```

This creates a local Kubernetes cluster named `signoz` in Docker.

### Step 2: Deploy ClickHouse Operator

The ClickHouse Operator manages ClickHouse instances within Kubernetes.

```bash
helmfile apply -l name=clickhouse-operator
```

Wait for the operator to be fully running before proceeding.

### Step 3: Deploy ClickHouse Cluster

Deploy the ClickHouse cluster that will store SigNoz data.

```bash
helmfile apply -l name=clickhouse
```

**Wait for the ClickHouse cluster to be fully ready.** This may take a few minutes. You can monitor the status with:

```bash
kubectl get pods -n clickhouse -w
```

### Step 4: Deploy SigNoz

Deploy the main SigNoz platform.

```bash
helmfile apply -l name=signoz
```

**Wait for all SigNoz components to be running.** Monitor with:

```bash
kubectl get pods -n signoz -w
```

### Step 5: Deploy Demo Application (Optional)

The OpenTelemetry demo is an ecommerce platform with multiple microservices that generate telemetry data (metrics, traces, logs). This is useful for testing SigNoz functionality.

**Note:** This deployment includes many components and may consume significant resources.

```bash
helmfile apply -l name=demo
```

Monitor the deployment:

```bash
kubectl get pods -n test -w
```

---

## Quick Deploy (All at Once)

If you prefer to deploy everything in one command:

```bash
helmfile apply
```

**Note:** It's recommended to follow the step-by-step approach above to ensure each component is healthy before proceeding.

---

## Accessing Services

### SigNoz UI

Port-forward the SigNoz frontend:

```bash
kubectl port-forward -n signoz svc/signoz 8080:8080
```

Access at: http://localhost:8080

### ClickHouse Database Access

#### Option 1: Using ClickHouse CLI Pod

The `generated-clickhouse-pod.yaml` file contains a simple ClickHouse client pod for quick CLI access.

Apply the pod:
```bash
kubectl apply -f generated-clickhouse-pod.yaml
```

Connect to ClickHouse:
```bash
kubectl exec -it clickhouse-debug-pod -n signoz -- clickhouse-client --host clickhouse-clickhouse.clickhouse.svc.cluster.local --user default --password ""
```

#### Option 2: Port-Forward + DBeaver

Port-forward the ClickHouse service:
```bash
kubectl port-forward -n clickhouse svc/clickhouse-clickhouse 8123:8123
```

Connect using DBeaver or any ClickHouse client:
- **Host:** localhost
- **Port:** 8123
- **Username:** `default`
- **Password:** (leave empty)

---

## Cluster Management

### Using k9s

For an interactive terminal UI to manage your Kubernetes cluster:

```bash
k9s
```

k9s provides visualization and quick navigation across:
- Pods, Deployments, Services
- Logs and resource usage
- Easy port-forwarding
- Resource editing and deletion

### Useful kubectl Commands

```bash
# View all namespaces
kubectl get namespaces

# View pods in a specific namespace
kubectl get pods -n signoz
kubectl get pods -n clickhouse
kubectl get pods -n test

# View logs
kubectl logs -n signoz <pod-name> -f

# Describe resources
kubectl describe pod -n signoz <pod-name>
```

---

## Cleanup

To remove the entire setup:

```bash
# Delete all releases
helmfile destroy

# Delete the Kind cluster
kind delete cluster --name signoz
```

---

## Troubleshooting

### ClickHouse Not Ready

If ClickHouse pods are not starting:
```bash
kubectl describe pod -n clickhouse <clickhouse-pod-name>
kubectl logs -n clickhouse <clickhouse-pod-name>
```

### SigNoz Components Failing

Check if ClickHouse is fully operational first:
```bash
kubectl get pods -n clickhouse
```

Then check SigNoz logs:
```bash
kubectl logs -n signoz <pod-name> -f
```

### Resource Constraints

If running on limited resources, consider:
- Skipping the demo deployment
- Reducing replica counts in configuration files
- Allocating more resources to the Kind cluster

---

## Configuration Files

- `helmfile.yaml` - Main deployment configuration
- `operator.yaml` - ClickHouse operator configuration
- `clickhouse.yaml` - ClickHouse cluster settings
- `signoz.yaml` - SigNoz platform configuration
- `demo.yaml` - OpenTelemetry demo application settings
- `generated-clickhouse-pod.yaml` - ClickHouse CLI client pod

---

## Notes

- The demo deployment is **optional** and resource-intensive. It's a complete ecommerce platform with multiple services sending telemetry to the OpenTelemetry collector.
- All deployments are configured to use the `kind-signoz` Kubernetes context.
- Default timeout for helm operations is set to 96000 seconds (26.6 hours).

---

## Support

For issues related to:
- **SigNoz**: https://github.com/SigNoz/signoz
- **ClickHouse Operator**: https://github.com/Altinity/clickhouse-operator
- **OpenTelemetry Demo**: https://github.com/open-telemetry/opentelemetry-demo
