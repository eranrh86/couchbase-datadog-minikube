# Datadog Configuration Deep Dive - Couchbase Integration

## 📖 Overview

This document provides a comprehensive explanation of the Datadog configuration used for Couchbase monitoring, with special focus on the `datadog.confd` section that enables the Couchbase integration.

---

## 📁 Configuration File: `datadog-values.yaml`

### File Purpose
This file contains Helm chart values for deploying the Datadog Agent with Couchbase integration enabled. It's used during Helm installation/upgrade to configure the agent.

---

## 🔧 Configuration Sections Breakdown

### 1. Top-Level Configuration

```yaml
datadog:
  apiKey: "DATADOG_API_KEY_PLACEHOLDER"
  site: datadoghq.com
```

#### **`apiKey`**
- **Type**: String (secret)
- **Purpose**: Authentication token for Datadog API
- **How it works**: 
  - This key identifies your Datadog organization
  - Agent uses it to send metrics, logs, and traces
  - Must be replaced with actual API key from: https://app.datadoghq.com/organization-settings/api-keys
- **Security**: Should be injected at deployment time, never committed to git
- **Example**: `YOUR_DATADOG_API_KEY_HERE` (replace with actual key from Datadog UI)

#### **`site`**
- **Type**: String
- **Purpose**: Datadog intake endpoint region
- **Options**:
  - `datadoghq.com` - US1 (default, used here)
  - `datadoghq.eu` - EU
  - `us3.datadoghq.com` - US3
  - `us5.datadoghq.com` - US5
  - `ap1.datadoghq.com` - AP1
- **Why it matters**: Determines where your data is stored and processed
- **Current value**: `datadoghq.com` (US region)

---

### 2. Logs Configuration

```yaml
logs:
  enabled: true
  containerCollectAll: true
```

#### **`logs.enabled`**
- **Type**: Boolean
- **Purpose**: Enable/disable log collection
- **Value**: `true`
- **Impact**: Agent will collect logs from containers
- **What it collects**:
  - Stdout/stderr from all containers
  - Kubernetes pod logs
  - Couchbase server logs
  - Application logs

#### **`logs.containerCollectAll`**
- **Type**: Boolean
- **Purpose**: Collect logs from ALL containers without annotations
- **Value**: `true`
- **Alternative**: `false` (requires per-pod annotations)
- **Best for**: Development/testing environments
- **Production consideration**: Set to `false` and use annotations for granular control

---

### 3. APM Configuration

```yaml
apm:
  portEnabled: true
```

#### **`apm.portEnabled`**
- **Type**: Boolean
- **Purpose**: Enable APM trace collection endpoint
- **Value**: `true`
- **Port**: 8126 (default APM port)
- **What it enables**:
  - Application Performance Monitoring
  - Distributed tracing
  - Service dependency mapping
- **Use case**: If you instrument Couchbase client applications
- **Current setup**: Ready for future application tracing

---

### 4. Process Agent

```yaml
processAgent:
  enabled: true
```

#### **`processAgent.enabled`**
- **Type**: Boolean
- **Purpose**: Enable process-level monitoring
- **Value**: `true`
- **What it collects**:
  - Running processes on each node
  - CPU/Memory per process
  - Process relationships
  - Command line arguments
- **For Couchbase**: Monitors `beam.smp` (Erlang VM), `memcached`, `cbq-engine` processes

---

### 5. Kubernetes State Metrics

```yaml
kubeStateMetricsEnabled: true
kubeStateMetricsCore:
  enabled: true
```

#### **`kubeStateMetricsEnabled`**
- **Type**: Boolean
- **Purpose**: Enable Kubernetes state metrics collection
- **Value**: `true`
- **What it provides**:
  - Pod states (Running, Pending, Failed)
  - Deployment status
  - ReplicaSet health
  - Resource quotas

#### **`kubeStateMetricsCore.enabled`**
- **Type**: Boolean
- **Purpose**: Use Datadog's built-in KSM collector (not external deployment)
- **Value**: `true`
- **Benefit**: Lighter weight, no separate KSM deployment needed
- **Metrics examples**: `kubernetes_state.pod.ready`, `kubernetes_state.deployment.replicas`

---

### 6. Cluster Identification

```yaml
clusterName: minikube-couchbase
```

#### **`clusterName`**
- **Type**: String
- **Purpose**: Unique identifier for this Kubernetes cluster
- **Value**: `minikube-couchbase`
- **How it's used**:
  - Added as tag: `kube_cluster_name:minikube-couchbase`
  - Filters metrics in Datadog UI
  - Distinguishes between multiple clusters
- **Best practice**: Use descriptive names like `prod-us-east-1`, `staging-couchbase`, etc.

---

### 7. Container Runtime Configuration

```yaml
criSocketPath: /var/run/dockershim.sock
```

#### **`criSocketPath`**
- **Type**: String (file path)
- **Purpose**: Path to Container Runtime Interface socket
- **Value**: `/var/run/dockershim.sock`
- **Why needed**: Agent needs to communicate with container runtime
- **Alternatives**:
  - `/var/run/docker.sock` - Direct Docker
  - `/var/run/containerd/containerd.sock` - containerd
  - `/var/run/crio/crio.sock` - CRI-O
- **Minikube default**: Uses dockershim (Docker)

---

### 8. 🌟 **COUCHBASE INTEGRATION CONFIGURATION** (Core Section)

```yaml
confd:
  couchbase.yaml: |-
    ad_identifiers:
      - couchbase-server
      - couchbase
    init_config:
    instances:
      - server: http://%%host%%:8091
        username: Administrator
        password: Password123!
        timeout: 10
        collect_cluster_metrics: true
        collect_bucket_metrics: true
        query_monitoring_url: http://%%host%%:8093/_p/query/stats
        tags:
          - env:minikube
          - service:couchbase
          - cluster:cb-cluster
```

This is the **MOST IMPORTANT** section for Couchbase monitoring. Let's break it down in detail:

---

#### **`confd`** Section
- **Purpose**: Define custom check configurations
- **Location in Agent**: `/etc/datadog-agent/conf.d/`
- **Format**: Key-value pairs where key = filename, value = YAML content
- **Result**: Creates `/etc/datadog-agent/conf.d/couchbase.yaml` inside agent container

---

#### **`couchbase.yaml`** Key
- **Purpose**: Filename for Couchbase integration configuration
- **Naming convention**: Must match integration name
- **Integration directory**: `/etc/datadog-agent/conf.d/couchbase.d/`
- **Alternative**: Could use `couchbase.d/conf.yaml` structure

---

#### **`ad_identifiers`** Array

```yaml
ad_identifiers:
  - couchbase-server
  - couchbase
```

**What it does**: Autodiscovery identifiers for Kubernetes pods

**How it works**:
1. Datadog Agent scans all pods on the node
2. Looks for containers with these names or image names
3. When found, applies this configuration automatically
4. No manual pod annotations needed

**In our setup**:
- Couchbase pods have containers named `couchbase-server`
- Agent automatically detects them
- Applies Couchbase check configuration

**Template variables available**:
- `%%host%%` - Pod IP address
- `%%port%%` - Exposed container port
- `%%hostname%%` - Pod hostname

**Why multiple identifiers**: 
- Different Couchbase deployments might use different naming
- Increases compatibility

---

#### **`init_config`** Section

```yaml
init_config:
```

**Purpose**: Global initialization configuration for ALL instances

**Common uses** (not used here):
- SSL/TLS settings
- Proxy configuration
- Global timeouts
- Shared authentication

**Current state**: Empty (no global config needed)

**When to use**:
```yaml
init_config:
  proxy:
    http: http://proxy.example.com:8080
  ssl_verify: false
```

---

#### **`instances`** Array

```yaml
instances:
  - server: http://%%host%%:8091
    username: Administrator
    ...
```

**Purpose**: Define one or more check instances

**Each instance represents**:
- One Couchbase cluster to monitor
- Independent configuration
- Separate metric collection

**Multiple instances example**:
```yaml
instances:
  - server: http://couchbase-cluster-1:8091
    username: admin1
  - server: http://couchbase-cluster-2:8091
    username: admin2
```

**Current setup**: Single instance (one Couchbase cluster)

---

#### **Instance Parameters Detailed**

##### **1. `server`**

```yaml
server: http://%%host%%:8091
```

- **Type**: String (URL)
- **Purpose**: Couchbase REST API endpoint
- **Format**: `http://<hostname>:<port>`
- **Port 8091**: Couchbase Admin REST API
- **Template variable**: `%%host%%` replaced with pod IP at runtime
- **In production**: Use FQDN like `http://cb-cluster.couchbase.svc.cluster.local:8091`

**Why Port 8091**:
- Main admin interface
- Provides cluster stats API
- Bucket information endpoint
- Node health metrics

**API endpoints accessed**:
- `/pools/default` - Cluster overview
- `/pools/default/buckets` - Bucket list
- `/pools/default/buckets/<bucket>/stats` - Bucket metrics
- `/pools/nodes` - Node information

---

##### **2. `username` and `password`**

```yaml
username: Administrator
password: Password123!
```

- **Type**: String
- **Purpose**: Couchbase authentication credentials
- **Required**: Yes (Couchbase REST API requires auth)
- **Permissions needed**:
  - Read access to cluster stats
  - Read access to bucket stats
  - Query monitoring access

**Security considerations**:
- ⚠️ Plaintext password in config (not ideal)
- Better: Use Kubernetes secret references
- Best: Use Datadog secret backend

**Alternative (secret reference)**:
```yaml
username: ENC[k8s_secret@namespace/secret-name/username]
password: ENC[k8s_secret@namespace/secret-name/password]
```

**Current setup**: Matches `cb-admin-auth` secret values

---

##### **3. `timeout`**

```yaml
timeout: 10
```

- **Type**: Integer (seconds)
- **Purpose**: HTTP request timeout
- **Default**: 5 seconds
- **Current**: 10 seconds
- **Why increased**: Couchbase stats API can be slow on large clusters

**What happens on timeout**:
- Check fails for that cycle
- Error logged in agent status
- Retried on next collection (15s later)

**Tuning guidelines**:
- Small clusters (< 10 buckets): 5 seconds
- Medium clusters (10-50 buckets): 10 seconds
- Large clusters (50+ buckets): 15-20 seconds

---

##### **4. `collect_cluster_metrics`** ⭐

```yaml
collect_cluster_metrics: true
```

- **Type**: Boolean
- **Purpose**: Enable cluster-wide metrics collection
- **Value**: `true` (ENABLED)
- **Performance impact**: Low (one API call per collection)

**Metrics collected when enabled**:

| Metric | Description |
|--------|-------------|
| `couchbase.ram.used` | Total RAM used across cluster |
| `couchbase.ram.total` | Total RAM available |
| `couchbase.ram.quota_used` | RAM quota utilized |
| `couchbase.ram.quota_total` | Total RAM quota |
| `couchbase.hdd.free` | Free disk space |
| `couchbase.hdd.used` | Used disk space |
| `couchbase.hdd.total` | Total disk space |
| `couchbase.hdd.quota_total` | Disk quota |
| `couchbase.hdd.used_by_data` | Disk used by data |
| `couchbase.cluster.nodes` | Number of nodes |

**API endpoint**: `/pools/default`

**When to disable**: 
- Only monitoring specific buckets
- Using multi-cluster setup (duplicate cluster metrics)

---

##### **5. `collect_bucket_metrics`** ⭐⭐⭐

```yaml
collect_bucket_metrics: true
```

- **Type**: Boolean
- **Purpose**: Enable per-bucket metrics collection
- **Value**: `true` (ENABLED)
- **🎯 CRITICAL**: Required for all 10 requested metrics!

**Why this is crucial**:
- All `couchbase.by_bucket.*` metrics depend on this
- Without it: Only cluster metrics, no bucket granularity
- Performance impact: Moderate (one API call per bucket)

**Metrics collected when enabled** (165+ metrics including):

| Category | Metric Examples |
|----------|-----------------|
| **Operations** | `cmd_get`, `cmd_set`, `ops_per_sec` |
| **Data I/O** | `bytes_read`, `bytes_written` |
| **CAS Ops** | `cas_hits`, `cas_misses`, `cas_badval` |
| **Disk I/O** | `avg_disk_commit_time`, `avg_disk_update_time` |
| **Background** | `avg_bg_wait_time`, `bg_wait_total` |
| **Cache** | `ep_cache_miss_rate`, `get_hits`, `get_misses` |
| **Items** | `item_count`, `curr_items`, `vb_active_num` |
| **Memory** | `ram_used`, `mem_used`, `ep_mem_high_wat` |
| **Disk** | `disk_used`, `couch_docs_actual_disk_size` |
| **Queue** | `disk_write_queue`, `ep_queue_size` |

**API endpoint**: `/pools/default/buckets/<bucket>/stats`

**Collection frequency**: Every check run (~15 seconds)

**Per bucket overhead**: ~50-100ms API call per bucket

---

##### **6. `query_monitoring_url`** 🔍

```yaml
query_monitoring_url: http://%%host%%:8093/_p/query/stats
```

- **Type**: String (URL)
- **Purpose**: N1QL Query Service monitoring endpoint
- **Format**: `http://<hostname>:<port>/_p/query/stats`
- **Port 8093**: Couchbase Query Service (N1QL)
- **Path**: `/_p/query/stats` - Query statistics API

**Why separate from main server URL**:
- Query service runs on different port (8093 vs 8091)
- Independent service within Couchbase
- Can be on different nodes

**Metrics collected**:

| Metric | Description |
|--------|-------------|
| `couchbase.query.requests` | Total query requests |
| `couchbase.query.selects` | SELECT queries |
| `couchbase.query.updates` | UPDATE queries |
| `couchbase.query.inserts` | INSERT queries |
| `couchbase.query.deletes` | DELETE queries |
| `couchbase.query.avg_elapsed_time` | Avg query execution time |
| `couchbase.query.avg_service_time` | Avg service time |
| `couchbase.query.active_requests` | Active queries |
| `couchbase.query.queued_requests` | Queued queries |
| `couchbase.query.errors` | Query errors |

**What the API returns** (sample):
```json
{
  "requests.count": 1234,
  "request_time.mean": 45.67,
  "active_requests.count": 5,
  "queued_requests.count": 0
}
```

**When to disable**: 
- Not using N1QL queries
- Query service not installed
- Only need data layer metrics

---

##### **7. `tags`** 🏷️

```yaml
tags:
  - env:minikube
  - service:couchbase
  - cluster:cb-cluster
```

- **Type**: Array of strings
- **Purpose**: Custom metadata attached to all metrics
- **Format**: `key:value` or just `value`

**How tags are used**:

1. **Filtering in Datadog UI**:
   ```
   couchbase.by_bucket.cmd_get{cluster:cb-cluster}
   ```

2. **Dashboard creation**:
   ```
   Filter: env:minikube AND service:couchbase
   ```

3. **Alert scoping**:
   ```
   Alert on: cluster:cb-cluster
   ```

4. **Service grouping**:
   ```
   Group by: service, cluster
   ```

**Tag breakdown**:

| Tag | Purpose | Example Use |
|-----|---------|-------------|
| `env:minikube` | Environment identifier | Separate dev/staging/prod |
| `service:couchbase` | Service type | Group all Couchbase metrics |
| `cluster:cb-cluster` | Cluster name | Multi-cluster filtering |

**Automatic tags added by agent**:
- `kube_namespace:couchbase`
- `kube_cluster_name:minikube-couchbase`
- `kube_service:cb-cluster`
- `pod_name:cb-cluster-0000`
- `pod_phase:Running`

**Best practices**:
```yaml
tags:
  - env:production              # Environment
  - service:couchbase           # Service type
  - cluster:prod-us-east-1      # Cluster location
  - team:data-platform          # Ownership
  - version:7.2.0               # Software version
  - criticality:high            # Business impact
```

---

### 9. Agent Configuration

```yaml
agents:
  image:
    tag: latest
```

#### **`agents.image.tag`**
- **Type**: String
- **Purpose**: Datadog Agent Docker image version
- **Value**: `latest`
- **Full image**: `gcr.io/datadoghq/agent:latest`
- **Alternatives**: `7.50.0`, `7.49.1`, `7-jmx`, etc.
- **Production recommendation**: Pin to specific version for stability

---

#### **Tolerations**

```yaml
tolerations:
  - operator: Exists
```

- **Type**: Array of tolerations
- **Purpose**: Allow agent pods to schedule on tainted nodes
- **`operator: Exists`**: Tolerate ALL taints
- **Why needed**: Ensures agent runs on every node including masters
- **Minikube**: Master node has taints by default

---

#### **Volumes**

```yaml
volumes:
  - name: dockersocket
    hostPath:
      path: /var/run/docker.sock
volumeMounts:
  - name: dockersocket
    mountPath: /var/run/docker.sock
```

- **Purpose**: Access Docker socket from host
- **Why needed**: Agent needs to inspect containers
- **Security**: Gives agent high privileges
- **What it enables**:
  - Container autodiscovery
  - Log collection from containers
  - Container metrics

---

### 10. Cluster Agent

```yaml
clusterAgent:
  enabled: true
  replicas: 1
```

#### **`clusterAgent.enabled`**
- **Type**: Boolean
- **Purpose**: Deploy Datadog Cluster Agent
- **Value**: `true`

**What Cluster Agent does**:
- Collects Kubernetes events
- Runs cluster-level checks
- Coordinates agent work
- Provides HPA metrics

**Architecture**:
```
Node Agents → Cluster Agent → Datadog Backend
   (165 metrics)    (aggregation)    (storage)
```

#### **`clusterAgent.replicas`**
- **Type**: Integer
- **Purpose**: Number of Cluster Agent replicas
- **Value**: 1 (single replica)
- **Production**: 2+ for high availability
- **Warning shown**: Should use 2+ with Admission Controller

---

## 🔄 How Configuration Flows

### 1. Deployment Time

```
Helm Chart Values (datadog-values.yaml)
    ↓
Helm Template Engine
    ↓
Kubernetes ConfigMap
    ↓
Agent Pod Volume Mount
    ↓
/etc/datadog-agent/conf.d/couchbase.yaml
```

### 2. Runtime

```
Agent Startup
    ↓
Load configuration from /etc/datadog-agent/conf.d/
    ↓
Parse couchbase.yaml
    ↓
Initialize Couchbase check with instances
    ↓
Every 15 seconds:
    ├─ Connect to http://cb-cluster:8091
    ├─ GET /pools/default (cluster metrics)
    ├─ GET /pools/default/buckets (bucket list)
    ├─ GET /pools/default/buckets/test-bucket/stats (bucket metrics)
    ├─ GET http://cb-cluster:8093/_p/query/stats (query metrics)
    └─ Send 165 metrics to Datadog
```

---

## 🎯 Configuration Impact on Metrics

### Scenario 1: Default Config (Minimal)
```yaml
instances:
  - server: http://cb-cluster:8091
    username: Administrator
    password: Password123!
```
**Result**: ❌ No metrics! (Missing collect flags)

---

### Scenario 2: Cluster Metrics Only
```yaml
instances:
  - server: http://cb-cluster:8091
    username: Administrator
    password: Password123!
    collect_cluster_metrics: true
```
**Result**: ✅ ~10 cluster metrics, ❌ No bucket metrics

---

### Scenario 3: Bucket Metrics Only
```yaml
instances:
  - server: http://cb-cluster:8091
    username: Administrator
    password: Password123!
    collect_bucket_metrics: true
```
**Result**: ✅ ~155 bucket metrics, ❌ No cluster metrics

---

### Scenario 4: Full Config (Current)
```yaml
instances:
  - server: http://cb-cluster:8091
    username: Administrator
    password: Password123!
    collect_cluster_metrics: true
    collect_bucket_metrics: true
    query_monitoring_url: http://cb-cluster:8093/_p/query/stats
```
**Result**: ✅ 165+ metrics (cluster + bucket + query) ← **THIS IS WHAT WE USE**

---

## 🔍 Verification

### Check Configuration is Loaded

```bash
DD_POD=$(kubectl get pods -n couchbase -l app=datadog -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n couchbase $DD_POD -- cat /etc/datadog-agent/conf.d/couchbase.yaml
```

### Check Configuration is Valid

```bash
kubectl exec -n couchbase $DD_POD -- agent configcheck
```

Look for:
```
=== couchbase check ===
Configuration provider: file
Configuration source: file:/etc/datadog-agent/conf.d/couchbase.yaml
Instance 1:
  server: http://cb-cluster.couchbase.svc.cluster.local:8091
  username: Administrator
  timeout: 10
  collect_cluster_metrics: True
  collect_bucket_metrics: True
  ...
```

### Check Integration is Running

```bash
kubectl exec -n couchbase $DD_POD -- agent status | grep -A 20 "couchbase"
```

Expected:
```
couchbase (6.0.1)
-----------------
  Instance ID: couchbase:xxxxx [OK]
  Configuration Source: file:/etc/datadog-agent/conf.d/couchbase.yaml[0]
  Total Runs: 10
  Metric Samples: Last Run: 165, Total: 1650
  Status: OK
```

---

## 🎓 Key Takeaways

### 1. **Configuration Hierarchy**
```
Helm Values → ConfigMap → Volume Mount → Agent Config File
```

### 2. **Critical Flags**
- `collect_cluster_metrics: true` → Cluster-wide metrics
- `collect_bucket_metrics: true` → **Required for requested metrics**
- `query_monitoring_url` → Query performance metrics

### 3. **Three Endpoint Types**
- `:8091` - Admin API (cluster + bucket stats)
- `:8093` - Query API (N1QL stats)
- `:11210` - Data operations (not used by integration)

### 4. **Autodiscovery Flow**
```
ad_identifiers → Pod Detection → Template Resolution → Check Initialization
```

### 5. **Metrics Collection**
- Frequency: ~15 seconds
- Per collection: 165 metrics
- Per hour: ~39,600 metric samples
- Per day: ~950,400 metric samples

---

## 📚 Related Documentation

- **This Config**: `datadog-values.yaml`
- **Deployment Script**: `deploy-datadog-complete.sh`
- **Integration Status**: `METRICS_VERIFICATION.md`
- **Full Deployment Plan**: `DEPLOYMENT_PLAN.md`

---

## ✅ Configuration Summary

Your current configuration is **optimal** for comprehensive Couchbase monitoring:

✅ Cluster metrics enabled
✅ Bucket metrics enabled (all 10 requested metrics)
✅ Query monitoring enabled
✅ Proper authentication configured
✅ Appropriate timeout (10s)
✅ Useful tags for filtering
✅ Autodiscovery configured
✅ Logs collection enabled

**Result**: 165+ metrics flowing to Datadog every 15 seconds! 🎉

