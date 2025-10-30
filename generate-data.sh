#!/bin/bash

# Generate Test Data in Couchbase for Datadog Monitoring
set -e

echo "======================================"
echo "Couchbase Data Generator"
echo "======================================"
echo ""

# Get Couchbase credentials
CB_USER="Administrator"
CB_PASS="Password123!"
CB_HOST="cb-cluster-0000.couchbase.svc.cluster.local"

echo "Step 1: Port-forwarding to Couchbase..."
kubectl port-forward -n couchbase svc/cb-cluster-ui 8091:8091 &
PF_PID=$!
sleep 5

CB_URL="http://localhost:8091"

echo ""
echo "Step 2: Creating test bucket 'test-bucket'..."
curl -s -u $CB_USER:$CB_PASS -X POST $CB_URL/pools/default/buckets \
  -d name=test-bucket \
  -d bucketType=couchbase \
  -d ramQuota=256 \
  -d durabilityMinLevel=none \
  -d flushEnabled=1 \
  -d replicaNumber=1 || echo "Bucket may already exist"

sleep 5

echo ""
echo "Step 3: Creating test bucket 'metrics-bucket'..."
curl -s -u $CB_USER:$CB_PASS -X POST $CB_URL/pools/default/buckets \
  -d name=metrics-bucket \
  -d bucketType=couchbase \
  -d ramQuota=256 \
  -d durabilityMinLevel=none \
  -d flushEnabled=1 \
  -d replicaNumber=1 || echo "Bucket may already exist"

sleep 5

echo ""
echo "Step 4: Inserting sample documents..."

# Insert user documents
for i in {1..50}; do
  DOC_ID="user:$i"
  DOC_DATA="{\"type\":\"user\",\"id\":$i,\"name\":\"User $i\",\"email\":\"user$i@example.com\",\"age\":$((20 + RANDOM % 50)),\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"active\":true}"
  
  curl -s -u $CB_USER:$CB_PASS -X PUT "$CB_URL/pools/default/buckets/test-bucket/docs/$DOC_ID" \
    -H "Content-Type: application/json" \
    -d "$DOC_DATA" > /dev/null
  
  echo "  ✓ Inserted document $DOC_ID"
done

# Insert product documents
for i in {1..30}; do
  DOC_ID="product:$i"
  DOC_DATA="{\"type\":\"product\",\"id\":$i,\"name\":\"Product $i\",\"price\":$((10 + RANDOM % 990)),\"category\":\"Category $((RANDOM % 5 + 1))\",\"stock\":$((RANDOM % 1000)),\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  
  curl -s -u $CB_USER:$CB_PASS -X PUT "$CB_URL/pools/default/buckets/test-bucket/docs/$DOC_ID" \
    -H "Content-Type: application/json" \
    -d "$DOC_DATA" > /dev/null
  
  echo "  ✓ Inserted document $DOC_ID"
done

# Insert order documents
for i in {1..40}; do
  DOC_ID="order:$i"
  USER_ID=$((RANDOM % 50 + 1))
  PRODUCT_ID=$((RANDOM % 30 + 1))
  DOC_DATA="{\"type\":\"order\",\"id\":$i,\"user_id\":$USER_ID,\"product_id\":$PRODUCT_ID,\"quantity\":$((RANDOM % 10 + 1)),\"total\":$((100 + RANDOM % 9900)),\"status\":\"completed\",\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  
  curl -s -u $CB_USER:$CB_PASS -X PUT "$CB_URL/pools/default/buckets/test-bucket/docs/$DOC_ID" \
    -H "Content-Type: application/json" \
    -d "$DOC_DATA" > /dev/null
  
  echo "  ✓ Inserted document $DOC_ID"
done

# Insert metrics documents
for i in {1..20}; do
  DOC_ID="metric:$i"
  DOC_DATA="{\"type\":\"metric\",\"id\":$i,\"name\":\"metric_$i\",\"value\":$((RANDOM % 10000)),\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tags\":[\"env:prod\",\"service:api\"]}"
  
  curl -s -u $CB_USER:$CB_PASS -X PUT "$CB_URL/pools/default/buckets/metrics-bucket/docs/$DOC_ID" \
    -H "Content-Type: application/json" \
    -d "$DOC_DATA" > /dev/null
  
  echo "  ✓ Inserted document $DOC_ID"
done

echo ""
echo "Step 5: Performing read operations to generate metrics..."

# Generate read traffic
for i in {1..100}; do
  USER_ID=$((RANDOM % 50 + 1))
  curl -s -u $CB_USER:$CB_PASS "$CB_URL/pools/default/buckets/test-bucket/docs/user:$USER_ID" > /dev/null 2>&1 || true
done

echo "  ✓ Completed 100 read operations"

echo ""
echo "Step 6: Getting bucket statistics..."
curl -s -u $CB_USER:$CB_PASS "$CB_URL/pools/default/buckets/test-bucket/stats" | grep -o '"op":{"samples":\[[^]]*\]' | head -1

echo ""
echo "======================================"
echo "✅ Data Generation Complete!"
echo "======================================"
echo ""
echo "Summary:"
echo "  - Created 2 buckets: test-bucket, metrics-bucket"
echo "  - Inserted 50 user documents"
echo "  - Inserted 30 product documents"
echo "  - Inserted 40 order documents"
echo "  - Inserted 20 metric documents"
echo "  - Performed 100 read operations"
echo ""
echo "Total: 140 documents across 2 buckets"
echo ""
echo "Bucket Stats:"
curl -s -u $CB_USER:$CB_PASS "$CB_URL/pools/default/buckets" | grep -o '"name":"[^"]*"' || echo "Check Web UI for stats"

echo ""
echo "View in Couchbase UI: $CB_URL"
echo ""

# Cleanup
kill $PF_PID 2>/dev/null || true

