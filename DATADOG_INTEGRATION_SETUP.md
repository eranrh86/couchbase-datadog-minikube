# Connect Your Datadog Agent to This Couchbase Cluster

## Current Status

✅ **Couchbase is running** with metrics being generated  
⚠️ **Datadog Agent needs configuration** to collect Couchbase metrics

## Quick Setup

### Option 1: Deploy Datadog Agent in This Cluster (Recommended)

```bash
cd /Users/eran.rahmani/Documents/VC/minikube/couchbase

# Set your Datadog API key
export DD_API_KEY='your-api-key-from-datadog'

# Create secret
kubectl create secret generic datadog-secret \
  --from-literal api-key="$DD_API_KEY" \
  -n couchbase

# Deploy Datadog Agent with Couchbase integration
kubectl apply -f datadog-agent.yaml

# Verify agent is running
kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog
```

### Option 2: Configure Existing Datadog Agent

If you already have a Datadog agent running (which seems likely since you're seeing system metrics), you need to add Couchbase integration:

**1. Find your Datadog agent:**
```bash
kubectl get pods --all-namespaces | grep datadog
```

**2. Get Couchbase connection details:**
```bash
# Get service endpoint
kubectl get svc cb-cluster -n couchbase

# Couchbase URL: cb-cluster.couchbase.svc.cluster.local:8091
# Username: Administrator
# Password: Password123!
```

**3. Add Couchbase check to your Datadog agent:**

Create/update the Couchbase integration config:

```yaml
# Add to your DatadogAgent CR or ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: datadog-couchbase-config
  namespace: <your-datadog-namespace>
data:
  couchbase.yaml: |
    init_config:
    instances:
      - server: http://cb-cluster.couchbase.svc.cluster.local:8091
        username: Administrator
        password: Password123!
        timeout: 10
        collect_cluster_metrics: true
        collect_bucket_metrics: true
        tags:
          - env:minikube
          - service:couchbase
          - cluster:cb-cluster
```

**4. Or use Autodiscovery annotations:**

Add these annotations to the Couchbase service:

```yaml
annotations:
  ad.datadoghq.com/service.check_names: '["couchbase"]'
  ad.datadoghq.com/service.init_configs: '[{}]'
  ad.datadoghq.com/service.instances: |
    [
      {
        "server": "http://%%host%%:8091",
        "username": "Administrator",
        "password": "Password123!",
        "collect_cluster_metrics": true,
        "collect_bucket_metrics": true
      }
    ]
```

## Verify Integration is Working

```bash
# If using agent in couchbase namespace:
DD_POD=$(kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n couchbase $DD_POD -- agent status | grep -A 30 couchbase

# Expected output:
# couchbase (x.x.x)
# -----------------
#   Instance ID: couchbase:xxxx [OK]
#   Total Runs: X
#   Metric Samples: Last Run: 45+
```

## Expected Metrics in Datadog

Once configured, you should see these metrics within 1-2 minutes:

### Read/Write Operations
- `couchbase.by_bucket.cmd_get` (500+ operations from our test)
- `couchbase.by_bucket.bytes_read` 
- `couchbase.by_bucket.bytes_written`

### CAS Operations
- `couchbase.by_bucket.cas_hits` (~143 from our test)
- `couchbase.by_bucket.cas_misses`
- `couchbase.by_bucket.cas_badval` (~57 from our test)

### Disk I/O
- `couchbase.by_bucket.avg_disk_commit_time`
- `couchbase.by_bucket.avg_disk_update_time`
- `couchbase.by_bucket.avg_bg_wait_time`
- `couchbase.by_bucket.bg_wait_total`

### Cluster Health
- `couchbase.by_bucket.disk_used`
- `couchbase.by_bucket.item_count` (200+ items)
- `couchbase.by_bucket.ops_per_sec`
- `couchbase.by_bucket.ram_used`

## Generate More Traffic

To continuously generate metrics:

```bash
# Run traffic generator again
./generate-metrics.sh

# Or run continuous traffic
./continuous-traffic.sh  # Press Ctrl+C to stop
```

## Access Couchbase UI

```bash
# Get service URL
minikube service cb-cluster-ui -n couchbase

# Credentials:
# Username: Administrator
# Password: Password123!
```

## Troubleshooting

### Metrics Not Appearing

1. **Check Datadog agent can reach Couchbase:**
```bash
DD_POD=$(kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n couchbase $DD_POD -- curl -u Administrator:Password123! \
  http://cb-cluster.couchbase.svc.cluster.local:8091/pools
```

2. **Check agent logs:**
```bash
kubectl logs -n couchbase $DD_POD | grep -i couchbase
```

3. **Verify bucket exists:**
```bash
kubectl run -it --rm check --image=curlimages/curl --restart=Never -n couchbase -- \
  curl -u Administrator:Password123! \
  http://cb-cluster.couchbase.svc.cluster.local:8091/pools/default/buckets
```

### Re-run Traffic Generator

```bash
kubectl delete pod couchbase-traffic-generator -n couchbase
./generate-metrics.sh
```

## Dashboard Query Examples

Once metrics are flowing, try these queries in Datadog:

**Total Operations:**
```
sum:couchbase.by_bucket.cmd_get{cluster:cb-cluster}.as_count()
```

**CAS Success Rate:**
```
sum:couchbase.by_bucket.cas_hits{*} / 
  (sum:couchbase.by_bucket.cas_hits{*} + sum:couchbase.by_bucket.cas_misses{*}) * 100
```

**Average Latency:**
```
avg:couchbase.by_bucket.avg_disk_commit_time{cluster:cb-cluster}
```

**Data Volume:**
```
sum:couchbase.by_bucket.bytes_written{*}.as_count() / 1024 / 1024
```

---

**Your Couchbase cluster is ready and generating metrics!** 🎉

Just connect your Datadog agent using one of the options above, and the metrics will start flowing to your dashboard.

