# Couchbase + Datadog Deployment Status

## ✅ Completed Steps

### 1. Couchbase Deployment - COMPLETE
- ✅ Namespace `couchbase` created
- ✅ Couchbase Operator installed via Helm (v2.8.1)
- ✅ Couchbase Cluster `cb-cluster` deployed
  - Version: 7.2.0
  - Size: 2 nodes
  - Services: data, index, query
  - Status: Available

### 2. Datadog Operator - COMPLETE
- ✅ Datadog Operator installed via Helm
- ✅ Operator is running and ready

## 📋 Current Status

### Couchbase Cluster
```bash
kubectl get couchbasecluster -n couchbase
kubectl get pods -n couchbase | grep cb-cluster
```

**Expected Output:**
- cb-cluster-0000: Running
- cb-cluster-0002: Running

### Services
```bash
kubectl get svc -n couchbase | grep cb-cluster
```

**Exposed Services:**
- `cb-cluster-ui` - NodePort for Web UI access
- Individual pod services with NodePort for each node

## 🔧 Next Steps to Complete Integration

### Step 1: Set Your Datadog API Key

You need to provide your Datadog API key to enable monitoring:

```bash
export DD_API_KEY='your-datadog-api-key-here'
```

### Step 2: Deploy Datadog Agent

Run the deployment script:

```bash
cd /Users/eran.rahmani/Documents/VC/minikube/couchbase
chmod +x deploy-datadog.sh
./deploy-datadog.sh $DD_API_KEY
```

Or manually:

```bash
# Create the secret with your API key
kubectl create secret generic datadog-secret \
  --from-literal api-key="YOUR_API_KEY" \
  -n couchbase

# Deploy the Datadog Agent
kubectl apply -f datadog-agent.yaml
```

### Step 3: Verify Datadog Integration

```bash
# Check Datadog Agent pods
kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog

# Get agent status
DATADOG_POD=$(kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n couchbase $DATADOG_POD -- agent status

# Check Couchbase integration specifically
kubectl exec -n couchbase $DATADOG_POD -- agent status | grep -A 20 "couchbase"
```

## 🌐 Accessing Couchbase

### Web UI

Get the Minikube IP and access the UI:

```bash
minikube ip
# Then visit: http://<MINIKUBE_IP>:30946
```

Or use minikube service:

```bash
minikube service cb-cluster-ui -n couchbase
```

### Credentials

- **Username:** Administrator
- **Password:** Password123!

(Stored in secret `cb-admin-auth`)

## 📊 What to Expect in Datadog

Once the agent is deployed and configured, you should see:

### Metrics
- `couchbase.by_bucket.*` - Bucket-level metrics
- `couchbase.hdd.*` - Disk usage
- `couchbase.ram.*` - Memory usage
- `couchbase.ops_per_sec` - Operations per second

### Logs
- All container logs from Couchbase pods
- Auto-multiline detection enabled

### Infrastructure
- Pods visible in Infrastructure > Containers
- Filter by `kube_namespace:couchbase`

## 🔍 Troubleshooting

### Couchbase Not Running

```bash
# Check cluster status
kubectl get couchbasecluster -n couchbase

# Check pod logs
kubectl logs -n couchbase cb-cluster-0000

# Check operator logs
kubectl logs -n couchbase -l app.kubernetes.io/name=couchbase-operator
```

### Datadog Agent Issues

```bash
# Check agent logs
kubectl logs -n couchbase -l app.kubernetes.io/name=datadog

# Check DatadogAgent resource
kubectl get datadogagent -n couchbase -o yaml
```

### Cannot Access UI

```bash
# Verify service
kubectl get svc cb-cluster-ui -n couchbase

# Check minikube
minikube status

# Get exact URL
minikube service cb-cluster-ui -n couchbase --url
```

## 📁 Project Files

- `namespace.yaml` - Namespace definition
- `couchbase-cluster.yaml` - Couchbase cluster configuration
- `couchbase-secret.yaml` - Admin credentials
- `datadog-agent.yaml` - Datadog Agent configuration
- `datadog-secret.yaml` - Datadog API key (template)
- `deploy-datadog.sh` - Automated Datadog deployment
- `verify.sh` - Verification script
- `cleanup.sh` - Cleanup script
- `README.md` - Full documentation

## 🎯 Quick Commands

```bash
# View all resources
kubectl get all -n couchbase

# Watch pods
kubectl get pods -n couchbase --watch

# Access Couchbase UI
minikube service cb-cluster-ui -n couchbase

# Port forward (alternative access)
kubectl port-forward -n couchbase svc/cb-cluster-ui 8091:8091
# Then visit: http://localhost:8091

# Full status check
./verify.sh
```

## ⚠️ Important Notes

1. **Couchbase requires significant resources** - Minikube should have at least 6GB RAM and 2 CPUs
2. **Data persistence** - The cluster uses PersistentVolumes (5Gi per pod)
3. **Production settings** - Current configuration has warnings about production settings (auto-failover, anti-affinity, etc.)
4. **Datadog API Key** - Required for the agent to send data to Datadog

## 🔄 Restart After Minikube Stop

If you stop and restart minikube:

```bash
# Start minikube
minikube start

# Pods should auto-restart, but if needed:
kubectl delete pod -n couchbase --all

# Wait for pods to come back
kubectl get pods -n couchbase --watch
```

## 📚 References

- [Couchbase Operator Docs](https://docs.couchbase.com/operator/current/overview.html)
- [Datadog Couchbase Integration](https://docs.datadoghq.com/integrations/couchbase/)
- [Datadog Operator](https://github.com/DataDog/datadog-operator)

