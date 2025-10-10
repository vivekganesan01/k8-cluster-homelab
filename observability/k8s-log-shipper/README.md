# Kubernetes Log Shipper with Vector and Victoria Logs

This setup uses Vector as a log collection agent and Victoria Logs for log storage and querying.

## Architecture

- **Vector Agent**: Deployed as a DaemonSet to collect logs from all nodes
- **Victoria Logs**: Deployed as VMInsert and VMSelect for log storage and querying
- **Log Flow**: Kubernetes Logs → Vector Agent → Victoria Logs VMInsert → VMSelect (for queries)

## Components

### Vector Agent
- **Role**: Log collection agent deployed as DaemonSet
- **Sources**: Collects Kubernetes container logs automatically
- **Transforms**: Parses JSON logs, adds timestamps, filters Vector's own logs
- **Sinks**: Sends logs to Victoria Logs via HTTP API

### Victoria Logs
- **VMInsert**: Receives and stores logs from Vector
- **VMSelect**: Provides query interface for logs
- **Storage**: Uses emptyDir for single-node setup (configure persistent storage for production)

## Configuration Files

- `vector.yml`: Helm values file for Vector Agent deployment
- `victoria_logs.yaml`: Kubernetes manifests for Victoria Logs deployment

## Deployment Instructions

### 1. Deploy Victoria Logs first
```bash
kubectl apply -f victoria_logs.yaml
```

### 2. Verify Victoria Logs is running
```bash
kubectl get pods -n observability
kubectl get svc -n observability
```

### 3. Deploy Vector Agent using Helm
```bash
# Add Vector Helm repository
helm repo add vector https://helm.vector.dev
helm repo update

# Deploy Vector Agent
helm install vector-agent vector/vector \
  --namespace observability \
  --values vector.yml
```

### 4. Verify Vector Agent deployment
```bash
kubectl get pods -n observability -l app.kubernetes.io/name=vector
```

### 5. Check logs are flowing
```bash
# Check Vector logs
kubectl logs -n observability -l app.kubernetes.io/name=vector

# Check Victoria Logs VMInsert logs
kubectl logs -n observability -l app=victoria-logs-vminsert
```

## Configuration Details

### Vector Configuration
- **Sources**: `kubernetes_logs` - automatically discovers and collects container logs
- **Transforms**: 
  - `parse_json`: Parses JSON formatted logs
  - `add_timestamp`: Adds timestamp if missing
  - `filter_vector_logs`: Prevents Vector from collecting its own logs
- **Sinks**: `victoria_logs` - HTTP sink to Victoria Logs VMInsert

### Victoria Logs Configuration
- **VMInsert**: Listens on port 8480 for HTTP and 8401 for gRPC
- **VMSelect**: Listens on port 8481 for queries
- **Storage**: 30-day retention policy
- **Memory**: 80% allowed memory usage

## Querying Logs

Once deployed, you can query logs using Victoria Logs VMSelect:

```bash
# Port forward to access VMSelect
kubectl port-forward -n observability svc/victoria-logs-vmselect 8481:8481

# Query logs (example)
curl "http://localhost:8481/select/logsql/query" -G \
  --data-urlencode 'query=SELECT * FROM logs LIMIT 10'
```

## Customization

### Filtering Logs
Edit the `customConfig.sources.kubernetes_logs` section in `vector.yml` to:
- Include/exclude specific namespaces: `include_namespaces` / `exclude_namespaces`
- Include/exclude specific containers: `include_container_names` / `exclude_container_names`
- Include/exclude specific labels: `include_labels` / `exclude_labels`

### Victoria Logs Settings
Edit `victoria_logs.yaml` to adjust:
- Retention period: `retentionPeriod`
- Memory limits: `memory.allowedPercent`
- Storage path: `storageDataPath`

## Production Considerations

1. **Persistent Storage**: Replace `emptyDir` with persistent volumes
2. **High Availability**: Deploy multiple replicas of VMInsert/VMSelect
3. **Resource Limits**: Adjust CPU/memory limits based on log volume
4. **Monitoring**: Add monitoring for Vector and Victoria Logs components
5. **Security**: Configure RBAC and network policies
