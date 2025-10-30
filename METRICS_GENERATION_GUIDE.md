# Couchbase Metrics Generation Guide

## 📊 Generate All Couchbase Metrics for Datadog

This guide shows you how to generate database traffic that will populate **ALL** the Couchbase metrics you want to see in Datadog.

## 🎯 Target Metrics

The traffic generator will produce these metrics:

### Read Operations
- ✅ `couchbase.by_bucket.cmd_get` - GET operations
- ✅ `couchbase.by_bucket.bytes_read` - Data read from disk

### Write Operations  
- ✅ `couchbase.by_bucket.bytes_written` - Data written to disk
- ✅ `couchbase.by_bucket.avg_disk_commit_time` - Disk commit latency
- ✅ `couchbase.by_bucket.avg_disk_update_time` - Disk update latency

### CAS Operations
- ✅ `couchbase.by_bucket.cas_hits` - Successful CAS operations
- ✅ `couchbase.by_bucket.cas_misses` - Failed CAS operations
- ✅ `couchbase.by_bucket.cas_badval` - CAS with wrong version

### Background Operations
- ✅ `couchbase.by_bucket.avg_bg_wait_time` - Background wait time
- ✅ `couchbase.by_bucket.bg_wait_total` - Total background wait

## 🚀 Quick Start

### Prerequisites

1. **Minikube running**:
```bash
minikube delete  # Clean slate
minikube start --kubernetes-version=v1.30.0
```

2. **Couchbase deployed**:
```bash
cd /Users/eran.rahmani/Documents/VC/minikube/couchbase

# Deploy Couchbase
kubectl apply -f namespace.yaml
helm install couchbase-operator couchbase/couchbase-operator --namespace couchbase
kubectl apply -f couchbase-secret.yaml
kubectl apply -f couchbase-cluster.yaml

# Wait for cluster
kubectl wait --for=condition=available couchbasecluster/cb-cluster -n couchbase --timeout=300s
```

3. **Datadog Agent deployed** (with your API key):
```bash
export DD_API_KEY='your-api-key-here'
./deploy-datadog.sh $DD_API_KEY
```

### Generate Metrics Traffic

**Option 1: Automated Script** (Recommended)
```bash
./generate-metrics.sh
```

This will:
1. Create the `test-bucket` if needed
2. Deploy the traffic generator pod  
3. Run comprehensive database operations:
   - 200 initial writes (creates baseline data)
   - 500 read operations (cmd_get, bytes_read)
   - 300 update operations (disk_commit, disk_update)
   - 200 CAS operations (cas_hits, cas_misses, cas_badval)
   - 1000 mixed operations (realistic workload)
4. Show real-time progress
5. Complete in 2-3 minutes

**Option 2: Manual Deployment**
```bash
# Create bucket
kubectl run -it --rm bucket-creator --image=curlimages/curl --restart=Never -n couchbase -- \
  curl -u Administrator:Password123! -X POST \
  http://cb-cluster.couchbase.svc.cluster.local:8091/pools/default/buckets \
  -d name=test-bucket -d bucketType=couchbase -d ramQuota=256

# Deploy traffic generator
kubectl apply -f traffic-generator-pod.yaml

# Watch the logs
kubectl logs -f couchbase-traffic-generator -n couchbase
```

## 📈 What the Traffic Generator Does

### Phase 1: Initial Data Load (bytes_written)
- Inserts 200 user documents
- Variable document sizes (100-500 bytes each)
- Triggers: `bytes_written`, `avg_disk_commit_time`, `avg_disk_update_time`

### Phase 2: Read Operations (cmd_get, bytes_read)
- Performs 500 GET operations
- Random document selection
- Triggers: `cmd_get`, `bytes_read`

### Phase 3: Update Operations (disk I/O metrics)
- Updates 300 documents
- Modifies balances and metadata
- Triggers: `avg_disk_commit_time`, `avg_disk_update_time`, `bg_wait_total`

### Phase 4: CAS Operations (concurrency metrics)
- 200 Compare-And-Swap operations
- 30% intentional CAS conflicts
- Triggers: `cas_hits`, `cas_misses`, `cas_badval`

### Phase 5: Mixed Workload (realistic traffic)
- 1000 operations mixing all types
- 10ms delay between operations
- Simulates real application traffic

## 🔍 Verify Metrics in Datadog

### 1. Check Datadog Agent is Collecting
```bash
# Get Datadog pod
DD_POD=$(kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog -o jsonpath='{.items[0].metadata.name}')

# Check Couchbase integration status
kubectl exec -n couchbase $DD_POD -- agent status | grep -A 30 couchbase
```

Expected output:
```
couchbase (x.x.x)
-----------------
  Instance ID: couchbase:xxxx [OK]
  Configuration Source: file:/etc/datadog-agent/conf.d/couchbase.d/conf.yaml
  Total Runs: 10
  Metric Samples: Last Run: 45, Total: 450
  Events: Last Run: 0, Total: 0
  Service Checks: Last Run: 1, Total: 10
  Average Execution Time: 234ms
```

### 2. View in Datadog UI

**Metrics Explorer:**
1. Go to https://app.datadoghq.com/metric/explorer
2. Search for: `couchbase.by_bucket`
3. You should see all metrics listed above

**Create Dashboard:**
1. Go to Dashboards → New Dashboard
2. Add widgets for key metrics:
   - `couchbase.by_bucket.cmd_get` (Timeseries)
   - `couchbase.by_bucket.bytes_written` (Query Value)
   - `couchbase.by_bucket.cas_hits` vs `cas_misses` (Stacked)
   - `couchbase.by_bucket.avg_disk_commit_time` (Heatmap)

### 3. Sample Queries

**Total GET Operations:**
```
sum:couchbase.by_bucket.cmd_get{*}
```

**Data Written (MB):**
```
sum:couchbase.by_bucket.bytes_written{*} / 1024 / 1024
```

**CAS Success Rate:**
```
sum:couchbase.by_bucket.cas_hits{*} / 
  (sum:couchbase.by_bucket.cas_hits{*} + sum:couchbase.by_bucket.cas_misses{*}) * 100
```

**Average Disk Latency:**
```
avg:couchbase.by_bucket.avg_disk_commit_time{*}
```

## 🔄 Continuous Traffic Generation

For ongoing metrics (useful for testing dashboards):

```bash
# Run continuous traffic
./continuous-traffic.sh
```

This generates operations every 0.5-2 seconds indefinitely until you press Ctrl+C.

## 🛠️ Troubleshooting

### No Metrics in Datadog

**Check 1: Datadog Agent Running**
```bash
kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog
```

**Check 2: Couchbase Integration Configured**
```bash
kubectl get datadogagent -n couchbase -o yaml | grep -A 5 couchbase
```

**Check 3: Bucket Exists**
```bash
kubectl run -it --rm check-bucket --image=curlimages/curl --restart=Never -n couchbase -- \
  curl -u Administrator:Password123! \
  http://cb-cluster.couchbase.svc.cluster.local:8091/pools/default/buckets
```

**Check 4: Agent Logs**
```bash
kubectl logs -n couchbase -l app.kubernetes.io/name=datadog --tail=100 | grep -i couchbase
```

### Traffic Generator Fails

**Check pod status:**
```bash
kubectl get pod couchbase-traffic-generator -n couchbase
kubectl logs couchbase-traffic-generator -n couchbase
```

**Common issues:**
- Bucket doesn't exist → Run `./generate-metrics.sh` which creates it
- Can't connect to Couchbase → Check cluster is ready: `kubectl get couchbasecluster -n couchbase`
- Python dependencies → The pod auto-installs them, check logs

### Low Metric Values

If metrics show but values are low:

1. **Run traffic generator multiple times:**
```bash
kubectl delete pod couchbase-traffic-generator -n couchbase
./generate-metrics.sh
```

2. **Run continuous traffic:**
```bash
./continuous-traffic.sh
# Let it run for 10-15 minutes
```

3. **Check Datadog collection interval** (default: 15 seconds)
```bash
kubectl get datadogagent -n couchbase -o yaml | grep -i interval
```

## 📊 Expected Metric Ranges

After running the traffic generator, you should see approximately:

| Metric | Expected Range |
|--------|---------------|
| `cmd_get` | 500-1500 operations |
| `bytes_read` | 100KB - 5MB |
| `bytes_written` | 200KB - 10MB |
| `cas_hits` | 140-200 |
| `cas_misses` | 60-100 |
| `cas_badval` | 60-100 |
| `avg_disk_commit_time` | 0.1-5ms |
| `avg_disk_update_time` | 10-100μs |
| `avg_bg_wait_time` | 10-1000μs |

## 🎨 Sample Datadog Dashboard JSON

Create a dashboard with this JSON:

```json
{
  "title": "Couchbase Performance Metrics",
  "widgets": [
    {
      "definition": {
        "title": "GET Operations",
        "type": "timeseries",
        "requests": [
          {
            "q": "sum:couchbase.by_bucket.cmd_get{*}",
            "display_type": "line"
          }
        ]
      }
    },
    {
      "definition": {
        "title": "Bytes Read vs Written",
        "type": "timeseries",
        "requests": [
          {
            "q": "sum:couchbase.by_bucket.bytes_read{*}",
            "display_type": "area"
          },
          {
            "q": "sum:couchbase.by_bucket.bytes_written{*}",
            "display_type": "area"
          }
        ]
      }
    },
    {
      "definition": {
        "title": "CAS Operations",
        "type": "timeseries",
        "requests": [
          {
            "q": "sum:couchbase.by_bucket.cas_hits{*}",
            "display_type": "bars"
          },
          {
            "q": "sum:couchbase.by_bucket.cas_misses{*}",
            "display_type": "bars"
          },
          {
            "q": "sum:couchbase.by_bucket.cas_badval{*}",
            "display_type": "bars"
          }
        ]
      }
    },
    {
      "definition": {
        "title": "Average Disk Commit Time",
        "type": "query_value",
        "requests": [
          {
            "q": "avg:couchbase.by_bucket.avg_disk_commit_time{*}",
            "aggregator": "avg"
          }
        ],
        "precision": 2
      }
    }
  ]
}
```

## 📝 Quick Reference

| Command | Purpose |
|---------|---------|
| `./generate-metrics.sh` | Generate all metrics (one-time, 2-3 min) |
| `./continuous-traffic.sh` | Generate ongoing traffic |
| `./verify.sh` | Check deployment status |
| `kubectl get pods -n couchbase` | View all pods |
| `kubectl logs -f couchbase-traffic-generator -n couchbase` | Watch traffic generation |
| `kubectl delete pod couchbase-traffic-generator -n couchbase` | Clean up generator |

## 🎯 Success Criteria

You'll know it's working when:

1. ✅ Traffic generator completes without errors
2. ✅ Datadog agent shows "Instance OK" for Couchbase
3. ✅ Metrics appear in Datadog within 1-2 minutes
4. ✅ All 10 target metrics have data points
5. ✅ Dashboard visualizations show data

## 🆘 Need Help?

1. Check logs: `kubectl logs -n couchbase <pod-name>`
2. Verify network: `kubectl exec -it <pod> -n couchbase -- curl cb-cluster:8091`
3. Check Datadog docs: https://docs.datadoghq.com/integrations/couchbase/
4. Run verification: `./verify.sh`

---

**Ready to generate metrics?** Run `./generate-metrics.sh` and watch your Datadog dashboard come alive! 🚀

