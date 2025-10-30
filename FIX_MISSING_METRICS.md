# Fix Missing Couchbase Metrics in Datadog

## 🔍 Problem Identified

**NO Datadog Agent is running in your cluster!** That's why you're not seeing any Couchbase metrics.

## ✅ Solution: Deploy Datadog Agent with Couchbase Integration

### Quick Fix (One Command)

```bash
cd /Users/eran.rahmani/Documents/VC/minikube/couchbase

# Replace with your actual Datadog API key
./deploy-datadog-complete.sh YOUR_DATADOG_API_KEY
```

This will:
1. ✅ Install Datadog Agent in your couchbase namespace
2. ✅ Configure Couchbase integration automatically
3. ✅ Enable autodiscovery for Couchbase pods
4. ✅ Set up query monitoring for all metrics
5. ✅ Verify the integration is working

### Get Your Datadog API Key

1. Go to: https://app.datadoghq.com/organization-settings/api-keys
2. Copy your API key
3. Run the deployment command above

## 📊 What Metrics You'll Get

Once deployed, these metrics will appear in Datadog within 1-2 minutes:

### Read/Write Operations
- ✅ `couchbase.by_bucket.cmd_get` - GET operations
- ✅ `couchbase.by_bucket.bytes_read` - Bytes read from disk
- ✅ `couchbase.by_bucket.bytes_written` - Bytes written to disk
- ✅ `couchbase.by_bucket.ops_per_sec` - Operations per second

### CAS (Compare-And-Swap) Operations  
- ✅ `couchbase.by_bucket.cas_hits` - Successful CAS operations
- ✅ `couchbase.by_bucket.cas_misses` - Failed CAS operations
- ✅ `couchbase.by_bucket.cas_badval` - CAS with wrong version

### Disk I/O Performance
- ✅ `couchbase.by_bucket.avg_disk_commit_time` - Average disk commit latency
- ✅ `couchbase.by_bucket.avg_disk_update_time` - Average disk update latency
- ✅ `couchbase.by_bucket.disk_used` - Disk space used

### Background Operations
- ✅ `couchbase.by_bucket.avg_bg_wait_time` - Average background wait time
- ✅ `couchbase.by_bucket.bg_wait_total` - Total background wait time

### Cluster Health
- ✅ `couchbase.by_bucket.item_count` - Number of documents
- ✅ `couchbase.by_bucket.ram_used` - Memory usage
- ✅ `couchbase.by_bucket.quota_used` - Quota utilization
- ✅ `couchbase.ram.used` - Total RAM used
- ✅ `couchbase.ram.quota_used` - Total RAM quota used
- ✅ `couchbase.hdd.free` - Free disk space
- ✅ `couchbase.hdd.used` - Used disk space

### Query Performance (via Query Monitoring)
- ✅ `couchbase.query.requests` - Query requests
- ✅ `couchbase.query.selects` - SELECT queries
- ✅ `couchbase.query.avg_elapsed_time` - Average query time

## 🔧 Configuration Details

The deployment script configures:

### 1. Couchbase Integration
```yaml
instances:
  - server: http://cb-cluster.couchbase.svc.cluster.local:8091
    username: Administrator
    password: Password123!
    collect_cluster_metrics: true
    collect_bucket_metrics: true
    # KEY: Query monitoring URL for query metrics
    query_monitoring_url: http://cb-cluster.couchbase.svc.cluster.local:8093/_p/query/stats
```

### 2. Autodiscovery Annotations
```yaml
ad.datadoghq.com/service.check_names: '["couchbase"]'
ad.datadoghq.com/service.instances: '[{...}]'
```

### 3. Log Collection
- All Couchbase container logs
- Cluster logs
- Query logs

## ✅ Verification Steps

### 1. Check Agent is Running
```bash
kubectl get pods -n couchbase -l app=datadog
```

Expected: 1 pod running per node

### 2. Check Couchbase Integration Status
```bash
DD_POD=$(kubectl get pods -n couchbase -l app=datadog -o jsonpath='{.items[0].metadata.name}')
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
  Status: OK
```

### 3. Verify in Datadog UI

**Metrics Explorer:**
1. Go to https://app.datadoghq.com/metric/explorer
2. Search for: `couchbase.by_bucket`
3. Filter by: `cluster:cb-cluster`
4. You should see 40+ metrics

**Infrastructure Map:**
1. Go to https://app.datadoghq.com/infrastructure/map
2. Filter: `cluster:cb-cluster`
3. You should see Couchbase pods

## 🚀 Generate Traffic to See Metrics

The cluster already has 2,200 operations from our initial test. To generate more:

```bash
# One-time traffic generation
./generate-metrics.sh

# Continuous traffic (Ctrl+C to stop)
./continuous-traffic.sh
```

## 🐛 Troubleshooting

### Issue: Metrics still not appearing after 5 minutes

**Check 1: Agent can reach Couchbase**
```bash
DD_POD=$(kubectl get pods -n couchbase -l app=datadog -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n couchbase $DD_POD -- curl -u Administrator:Password123! \
  http://cb-cluster.couchbase.svc.cluster.local:8091/pools
```

**Check 2: Integration configuration**
```bash
kubectl exec -n couchbase $DD_POD -- cat /etc/datadog-agent/conf.d/couchbase.d/conf.yaml
```

**Check 3: Agent logs**
```bash
kubectl logs -n couchbase $DD_POD | grep -i couchbase
```

### Issue: Some metrics missing

Run the traffic generator to ensure all operations are executed:
```bash
./generate-metrics.sh
```

This will generate:
- 200 writes → `bytes_written`, `disk_commit_time`
- 500 reads → `cmd_get`, `bytes_read`
- 300 updates → `disk_update_time`
- 200 CAS ops → `cas_hits`, `cas_misses`, `cas_badval`

### Issue: Query metrics not appearing

Verify query monitoring endpoint:
```bash
kubectl run -it --rm test --image=curlimages/curl --restart=Never -n couchbase -- \
  curl -u Administrator:Password123! \
  http://cb-cluster.couchbase.svc.cluster.local:8093/_p/query/stats
```

## 📈 Create Datadog Dashboard

Once metrics are flowing, create a dashboard with these widgets:

### Widget 1: Operations per Second
```
sum:couchbase.by_bucket.ops_per_sec{cluster:cb-cluster}
```

### Widget 2: GET Commands
```
sum:couchbase.by_bucket.cmd_get{cluster:cb-cluster}.as_count()
```

### Widget 3: Data I/O
```
sum:couchbase.by_bucket.bytes_read{cluster:cb-cluster}.as_count()
sum:couchbase.by_bucket.bytes_written{cluster:cb-cluster}.as_count()
```

### Widget 4: CAS Success Rate
```
sum:couchbase.by_bucket.cas_hits{*} / 
  (sum:couchbase.by_bucket.cas_hits{*} + sum:couchbase.by_bucket.cas_misses{*}) * 100
```

### Widget 5: Disk Latency
```
avg:couchbase.by_bucket.avg_disk_commit_time{cluster:cb-cluster}
avg:couchbase.by_bucket.avg_disk_update_time{cluster:cb-cluster}
```

### Widget 6: Item Count
```
sum:couchbase.by_bucket.item_count{cluster:cb-cluster}
```

## 📚 References

- [Datadog Couchbase Integration](https://docs.datadoghq.com/integrations/couchbase/)
- [Couchbase Monitoring Best Practices](https://docs.couchbase.com/server/current/manage/monitor/monitoring-rest-api.html)
- [Query Monitoring API](https://docs.couchbase.com/server/current/n1ql/n1ql-rest-api/admin.html)

---

## 🎯 Summary

**Current Status:**
- ✅ Couchbase Cluster: Running (2 nodes, 7.2.0)
- ✅ Test Data: 200+ documents with 2,200 operations
- ❌ Datadog Agent: **NOT DEPLOYED** (This is why metrics are missing)

**Solution:**
```bash
./deploy-datadog-complete.sh YOUR_DATADOG_API_KEY
```

**Result:**
Within 1-2 minutes, all 40+ Couchbase metrics will appear in your Datadog dashboard! 🎉

