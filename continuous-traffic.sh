#!/bin/bash

# Generate Continuous Traffic to Couchbase for Datadog Monitoring
set -e

echo "======================================"
echo "Couchbase Continuous Traffic Generator"
echo "======================================"
echo ""
echo "This script will generate continuous traffic to Couchbase."
echo "Press Ctrl+C to stop."
echo ""

# Get Couchbase credentials
CB_USER="Administrator"
CB_PASS="Password123!"

echo "Starting port-forward..."
kubectl port-forward -n couchbase svc/cb-cluster-ui 8091:8091 &
PF_PID=$!
sleep 5

CB_URL="http://localhost:8091"

echo "Starting traffic generation..."
echo ""

COUNTER=0
while true; do
  COUNTER=$((COUNTER + 1))
  
  # Random operation type
  OP_TYPE=$((RANDOM % 4))
  
  case $OP_TYPE in
    0)
      # Read user
      USER_ID=$((RANDOM % 50 + 1))
      curl -s -u $CB_USER:$CB_PASS "$CB_URL/pools/default/buckets/test-bucket/docs/user:$USER_ID" > /dev/null 2>&1
      echo "[$COUNTER] READ: user:$USER_ID"
      ;;
    1)
      # Read product
      PRODUCT_ID=$((RANDOM % 30 + 1))
      curl -s -u $CB_USER:$CB_PASS "$CB_URL/pools/default/buckets/test-bucket/docs/product:$PRODUCT_ID" > /dev/null 2>&1
      echo "[$COUNTER] READ: product:$PRODUCT_ID"
      ;;
    2)
      # Create new order
      ORDER_ID=$((50 + RANDOM % 1000))
      USER_ID=$((RANDOM % 50 + 1))
      PRODUCT_ID=$((RANDOM % 30 + 1))
      DOC_DATA="{\"type\":\"order\",\"id\":$ORDER_ID,\"user_id\":$USER_ID,\"product_id\":$PRODUCT_ID,\"quantity\":$((RANDOM % 10 + 1)),\"total\":$((100 + RANDOM % 9900)),\"status\":\"pending\",\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
      
      curl -s -u $CB_USER:$CB_PASS -X PUT "$CB_URL/pools/default/buckets/test-bucket/docs/order:$ORDER_ID" \
        -H "Content-Type: application/json" \
        -d "$DOC_DATA" > /dev/null 2>&1
      echo "[$COUNTER] WRITE: order:$ORDER_ID"
      ;;
    3)
      # Update metric
      METRIC_ID=$((RANDOM % 20 + 1))
      DOC_DATA="{\"type\":\"metric\",\"id\":$METRIC_ID,\"name\":\"metric_$METRIC_ID\",\"value\":$((RANDOM % 10000)),\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tags\":[\"env:prod\",\"service:api\"]}"
      
      curl -s -u $CB_USER:$CB_PASS -X PUT "$CB_URL/pools/default/buckets/metrics-bucket/docs/metric:$METRIC_ID" \
        -H "Content-Type: application/json" \
        -d "$DOC_DATA" > /dev/null 2>&1
      echo "[$COUNTER] UPDATE: metric:$METRIC_ID"
      ;;
  esac
  
  # Show stats every 20 operations
  if [ $((COUNTER % 20)) -eq 0 ]; then
    echo ""
    echo "--- Stats after $COUNTER operations ---"
    curl -s -u $CB_USER:$CB_PASS "$CB_URL/pools/default/buckets/test-bucket" | grep -o '"itemCount":[0-9]*' | head -1
    echo ""
  fi
  
  # Random sleep between 0.5 and 2 seconds
  sleep 0.$((RANDOM % 15 + 5))
done

# Cleanup (only reached if interrupted)
trap "kill $PF_PID 2>/dev/null || true; echo 'Stopped.'; exit 0" INT TERM

