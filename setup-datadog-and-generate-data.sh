#!/bin/bash

# Complete Setup: Deploy Datadog and Generate Test Data
set -e

echo "======================================"
echo "Complete Couchbase + Datadog Setup"
echo "======================================"
echo ""

# Check if Datadog API key is provided
if [ -z "$1" ]; then
    echo "Usage: ./setup-datadog-and-generate-data.sh YOUR_DATADOG_API_KEY"
    echo ""
    echo "This script will:"
    echo "  1. Deploy Datadog Agent with Couchbase integration"
    echo "  2. Generate test data in Couchbase"
    echo "  3. Create continuous traffic for monitoring"
    echo ""
    echo "Get your API key from: https://app.datadoghq.com/organization-settings/api-keys"
    exit 1
fi

DD_API_KEY=$1

echo "Step 1: Deploying Datadog Agent..."
echo ""

# Create Datadog secret
kubectl create secret generic datadog-secret \
  --from-literal api-key="$DD_API_KEY" \
  -n couchbase \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Datadog secret created"

# Deploy Datadog Agent
kubectl apply -f datadog-agent.yaml

echo "✓ Datadog Agent deployed"
echo ""
echo "Waiting 30 seconds for Datadog Agent to start..."
sleep 30

# Check Datadog Agent status
echo ""
echo "Step 2: Verifying Datadog Agent..."
kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog

echo ""
echo "Step 3: Generating test data in Couchbase..."
echo ""

# Run data generation
./generate-data.sh

echo ""
echo "======================================"
echo "✅ Setup Complete!"
echo "======================================"
echo ""
echo "Datadog Agent Status:"
kubectl get datadogagent -n couchbase 2>/dev/null || echo "DatadogAgent resource not found (check manually)"
echo ""
echo "To verify Datadog is collecting Couchbase metrics:"
echo '  DATADOG_POD=$(kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog -o jsonpath='"'"'{.items[0].metadata.name}'"'"')'
echo '  kubectl exec -n couchbase $DATADOG_POD -- agent status | grep -A 30 couchbase'
echo ""
echo "To generate continuous traffic:"
echo "  ./continuous-traffic.sh"
echo ""
echo "View Couchbase UI:"
echo "  minikube service cb-cluster-ui -n couchbase"
echo ""
echo "Expected Metrics in Datadog:"
echo "  - couchbase.by_bucket.disk_used"
echo "  - couchbase.by_bucket.item_count"
echo "  - couchbase.by_bucket.ops_per_sec"
echo "  - couchbase.by_bucket.ram_used"
echo "  - couchbase.hdd.free/used"
echo "  - couchbase.ram.used"
echo ""
echo "Check Datadog Dashboard: https://app.datadoghq.com/infrastructure"
echo ""

