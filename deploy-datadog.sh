#!/bin/bash

# Deploy Datadog Agent with Couchbase Integration
set -e

echo "======================================"
echo "Deploying Datadog Agent"
echo "======================================"
echo ""

# Check if Datadog API key is provided
if [ -z "$1" ]; then
    echo "Usage: ./deploy-datadog.sh YOUR_DATADOG_API_KEY"
    echo ""
    echo "Example: ./deploy-datadog.sh abcd1234efgh5678"
    exit 1
fi

DD_API_KEY=$1

echo "Creating Datadog secret..."
kubectl create secret generic datadog-secret \
  --from-literal api-key="$DD_API_KEY" \
  -n couchbase \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Deploying Datadog Agent..."
kubectl apply -f datadog-agent.yaml

echo ""
echo "Waiting for Datadog Agent to be ready..."
sleep 15

echo ""
echo "Checking Datadog Agent status..."
kubectl get datadogagent -n couchbase
kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog

echo ""
echo "======================================"
echo "✅ Datadog Agent Deployed!"
echo "======================================"
echo ""
echo "To check the Datadog Agent status:"
echo '  DATADOG_POD=$(kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog -o jsonpath='"'"'{.items[0].metadata.name}'"'"')'
echo '  kubectl exec -n couchbase $DATADOG_POD -- agent status'
echo ""
echo "Check for Couchbase integration:"
echo '  kubectl exec -n couchbase $DATADOG_POD -- agent status | grep -A 20 "couchbase"'
echo ""

