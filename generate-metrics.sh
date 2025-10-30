#!/bin/bash

# Generate Couchbase Metrics Traffic
set -e

echo "======================================"
echo "Couchbase Metrics Traffic Generator"
echo "======================================"
echo ""

echo "This script will generate database operations to produce metrics:"
echo "  - cmd_get (read operations)"
echo "  - bytes_read / bytes_written"
echo "  - CAS operations (hits, misses, badval)"
echo "  - Disk commit/update times"
echo "  - Background wait times"
echo ""

# Check if pod already exists
if kubectl get pod couchbase-traffic-generator -n couchbase &>/dev/null; then
    echo "Cleaning up previous traffic generator..."
    kubectl delete pod couchbase-traffic-generator -n couchbase --ignore-not-found=true
    sleep 5
fi

echo "Step 1: Creating test bucket if it doesn't exist..."
kubectl run -it --rm couchbase-bucket-creator --image=curlimages/curl --restart=Never -n couchbase -- \
  curl -s -u Administrator:Password123! -X POST \
  http://cb-cluster.couchbase.svc.cluster.local:8091/pools/default/buckets \
  -d name=test-bucket \
  -d bucketType=couchbase \
  -d ramQuota=256 \
  -d durabilityMinLevel=none \
  -d flushEnabled=1 \
  -d replicaNumber=1 2>/dev/null || echo "  (Bucket may already exist)"

echo ""
echo "Step 2: Deploying traffic generator pod..."
kubectl apply -f traffic-generator-pod.yaml

echo ""
echo "Step 3: Waiting for pod to start..."
kubectl wait --for=condition=Ready pod/couchbase-traffic-generator -n couchbase --timeout=60s 2>/dev/null || echo "Pod starting..."

echo ""
echo "Step 4: Watching traffic generation (this will take a few minutes)..."
echo "========================================================================"
kubectl logs -f couchbase-traffic-generator -n couchbase

echo ""
echo "======================================"
echo "✅ Traffic Generation Complete!"
echo "======================================"
echo ""
echo "Metrics should now be visible in Datadog:"
echo ""
echo "1. Go to Datadog → Metrics Explorer"
echo "2. Search for: couchbase.by_bucket"
echo "3. You should see:"
echo "   - couchbase.by_bucket.cmd_get"
echo "   - couchbase.by_bucket.bytes_read"
echo "   - couchbase.by_bucket.bytes_written"
echo "   - couchbase.by_bucket.cas_hits"
echo "   - couchbase.by_bucket.cas_misses"
echo "   - couchbase.by_bucket.cas_badval"
echo "   - couchbase.by_bucket.avg_disk_commit_time"
echo "   - couchbase.by_bucket.avg_disk_update_time"
echo "   - couchbase.by_bucket.avg_bg_wait_time"
echo "   - couchbase.by_bucket.bg_wait_total"
echo ""
echo "To run again: ./generate-metrics.sh"
echo "To clean up: kubectl delete pod couchbase-traffic-generator -n couchbase"
echo ""

