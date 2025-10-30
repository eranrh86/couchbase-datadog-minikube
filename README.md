# Couchbase on Minikube with Datadog Monitoring

This project deploys Couchbase Server on Minikube with full Datadog monitoring integration.

## 📋 Prerequisites

- Minikube installed and running
- kubectl configured
- Helm 3.x installed
- Datadog API key

## 🏗️ Architecture

This deployment includes:
- **Couchbase Operator**: Manages Couchbase cluster lifecycle
- **Couchbase Cluster**: 2-node cluster with data, index, and query services
- **Datadog Agent**: Monitors Couchbase metrics, logs, and traces
- **Datadog Operator**: Manages Datadog Agent deployment

## 📁 Project Structure

```
couchbase/
├── namespace.yaml                 # Couchbase namespace
├── couchbase-operator.yaml        # Couchbase Operator deployment
├── couchbase-cluster-crd.yaml     # CouchbaseCluster CRD
├── couchbase-secret.yaml          # Admin credentials
├── couchbase-cluster.yaml         # Couchbase cluster definition
├── couchbase-service.yaml         # Services for cluster access
├── couchbase-configmap.yaml       # Datadog integration config
├── datadog-secret.yaml            # Datadog API key (template)
├── datadog-agent.yaml             # Datadog Agent configuration
├── deploy.sh                      # Automated deployment script
├── verify.sh                      # Verification script
├── cleanup.sh                     # Cleanup script
└── README.md                      # This file
```

## 🚀 Quick Start

### 1. Start Minikube (if not running)

```bash
minikube start --memory=8192 --cpus=4
```

### 2. Set Your Datadog API Key

```bash
export DD_API_KEY='your-datadog-api-key-here'
```

### 3. Deploy Everything

```bash
cd /Users/eran.rahmani/Documents/VC/minikube/couchbase
chmod +x deploy.sh verify.sh cleanup.sh
./deploy.sh
```

The deployment script will:
1. Create the couchbase namespace
2. Install Datadog Operator
3. Deploy Couchbase CRD and Operator
4. Deploy Datadog Agent with Couchbase integration
5. Deploy Couchbase cluster (2 nodes)
6. Expose Couchbase UI via NodePort

### 4. Verify Deployment

```bash
./verify.sh
```

## 🔍 Accessing Couchbase

### Web UI

```bash
# Get Minikube IP
minikube service cb-cluster-ui -n couchbase

# Or manually:
echo "http://$(minikube ip):30091"
```

**Credentials:**
- Username: `Administrator`
- Password: `Password123!`

### From Command Line

```bash
# Get cluster status
kubectl get couchbasecluster -n couchbase

# View cluster details
kubectl describe couchbasecluster cb-cluster -n couchbase

# View pods
kubectl get pods -n couchbase
```

## 📊 Datadog Integration

### Check Datadog Agent Status

```bash
# Get Datadog Agent pods
kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog-agent

# Check agent status
DATADOG_POD=$(kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog-agent -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n couchbase $DATADOG_POD -- agent status
```

### Couchbase Check Status

```bash
# Check if Couchbase integration is running
kubectl exec -n couchbase $DATADOG_POD -- agent status | grep -A 20 "couchbase"
```

### Expected Metrics in Datadog

The following metrics will be collected:
- `couchbase.by_bucket.disk_used`
- `couchbase.by_bucket.item_count`
- `couchbase.by_bucket.ops_per_sec`
- `couchbase.by_bucket.quota_used`
- `couchbase.by_bucket.ram_used`
- `couchbase.hdd.free`
- `couchbase.hdd.used`
- `couchbase.ram.used`
- `couchbase.ram.quota_used`

## 🧪 Testing the Setup

### 1. Create a Test Bucket

Access the Couchbase UI and:
1. Go to "Buckets" tab
2. Click "ADD BUCKET"
3. Name: `test-bucket`
4. Memory Quota: 256 MB
5. Click "Add Bucket"

### 2. Insert Test Data

```bash
# Port-forward to Couchbase
kubectl port-forward -n couchbase svc/cb-cluster 8091:8091 &

# Use curl to insert data (or use the Web UI)
curl -X POST http://Administrator:Password123!@localhost:8091/pools/default/buckets/test-bucket/docs/test-doc \
  -d '{"key": "value", "test": true}'
```

### 3. Check Datadog Dashboard

1. Go to Datadog UI
2. Navigate to Infrastructure > Containers
3. Filter by `kube_namespace:couchbase`
4. Check Metrics Explorer for `couchbase.*` metrics
5. View logs from Couchbase containers

## 🔧 Troubleshooting

### Couchbase Pods Not Starting

```bash
# Check operator logs
kubectl logs -n couchbase -l app=couchbase-operator

# Check pod events
kubectl describe pods -n couchbase -l couchbase_cluster=cb-cluster
```

### Datadog Agent Not Collecting Metrics

```bash
# Check agent logs
kubectl logs -n couchbase -l app.kubernetes.io/name=datadog-agent

# Verify service annotations
kubectl get svc cb-cluster -n couchbase -o yaml
```

### Storage Issues

```bash
# Check PVCs
kubectl get pvc -n couchbase

# If storage is full, increase in couchbase-cluster.yaml
# and reapply:
kubectl apply -f couchbase-cluster.yaml
```

## 🔄 Manual Deployment Steps

If you prefer to deploy manually:

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Install Datadog Operator
helm repo add datadog https://helm.datadoghq.com
helm repo update
kubectl create secret generic datadog-secret \
  --from-literal api-key="$DD_API_KEY" -n couchbase
helm install datadog-operator datadog/datadog-operator -n couchbase

# 3. Deploy Couchbase CRD and Operator
kubectl apply -f couchbase-cluster-crd.yaml
kubectl apply -f couchbase-operator.yaml

# 4. Wait for operator
kubectl wait --for=condition=available --timeout=300s \
  deployment/couchbase-operator -n couchbase

# 5. Create secrets
kubectl apply -f couchbase-secret.yaml

# 6. Deploy Datadog Agent
kubectl apply -f datadog-agent.yaml

# 7. Deploy Couchbase cluster
kubectl apply -f couchbase-cluster.yaml
kubectl apply -f couchbase-service.yaml

# 8. Apply ConfigMap
kubectl apply -f couchbase-configmap.yaml
```

## 🗑️ Cleanup

To remove the entire deployment:

```bash
./cleanup.sh
```

Or manually:

```bash
kubectl delete namespace couchbase
helm uninstall datadog-operator -n couchbase
kubectl delete crd couchbaseclusters.couchbase.com
```

## 📚 Additional Resources

- [Couchbase Operator Documentation](https://docs.couchbase.com/operator/current/overview.html)
- [Datadog Couchbase Integration](https://docs.datadoghq.com/integrations/couchbase/)
- [Couchbase Server Documentation](https://docs.couchbase.com/server/current/introduction/intro.html)

## ⚙️ Configuration

### Scaling the Cluster

Edit `couchbase-cluster.yaml` and change the `size` parameter:

```yaml
servers:
  - size: 3  # Increase to 3 nodes
```

Then apply:

```bash
kubectl apply -f couchbase-cluster.yaml
```

### Changing Resources

Modify resource limits in `couchbase-cluster.yaml`:

```yaml
resources:
  limits:
    cpu: "4"
    memory: 4Gi
  requests:
    cpu: "2"
    memory: 2Gi
```

### Adding More Services

Couchbase supports multiple services:
- `data` - Data service
- `index` - Index service  
- `query` - Query service
- `fts` - Full-text search
- `analytics` - Analytics service
- `eventing` - Eventing service

## 🔐 Security Notes

⚠️ **Important**: The default password in this deployment is `Password123!`. For production use:

1. Change the password in `couchbase-secret.yaml`
2. Update the password in `couchbase-service.yaml` annotations
3. Update the password in `couchbase-configmap.yaml`
4. Use proper secret management (e.g., Sealed Secrets, Vault)

## 📝 Notes

- The deployment uses Couchbase Server 7.2.0
- Storage: Each node gets 5GB of persistent storage
- Resources: Each node gets 1-2 CPU cores and 1-2GB RAM
- NodePort 30091 exposes the Couchbase UI
- Auto-discovery is configured for the Datadog agent

