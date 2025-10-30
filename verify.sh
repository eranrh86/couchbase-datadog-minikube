#!/bin/bash

# Verification Script for Couchbase + Datadog Integration
set -e

echo "======================================"
echo "Couchbase + Datadog Verification"
echo "======================================"
echo ""

echo "1. Checking Couchbase Namespace..."
kubectl get namespace couchbase
echo ""

echo "2. Checking Couchbase Operator..."
kubectl get deployment couchbase-operator -n couchbase
echo ""

echo "3. Checking Couchbase Cluster..."
kubectl get couchbasecluster cb-cluster -n couchbase
echo ""

echo "4. Checking Couchbase Pods..."
kubectl get pods -n couchbase -l couchbase_cluster=cb-cluster
echo ""

echo "5. Checking Couchbase Services..."
kubectl get svc -n couchbase
echo ""

echo "6. Checking Datadog Agent..."
kubectl get datadogagent -n couchbase
echo ""

echo "7. Checking Datadog Agent Pods..."
kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog-agent
echo ""

echo "8. Checking if Couchbase is ready..."
COUCHBASE_PODS=$(kubectl get pods -n couchbase -l couchbase_cluster=cb-cluster -o jsonpath='{.items[*].status.containerStatuses[0].ready}')
if [[ "$COUCHBASE_PODS" == *"true"* ]]; then
    echo "✅ Couchbase pods are ready"
else
    echo "⚠️  Couchbase pods are still starting up. Run this script again in a few minutes."
fi
echo ""

echo "9. Testing Couchbase Connection..."
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
echo "Couchbase UI: http://$MINIKUBE_IP:30091"
echo "Credentials: Administrator / Password123!"
echo ""

echo "10. Checking Datadog Integration..."
echo "Looking for Datadog Agent logs related to Couchbase..."
DATADOG_POD=$(kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog-agent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ ! -z "$DATADOG_POD" ]; then
    echo "Datadog Agent Pod: $DATADOG_POD"
    echo "Checking for Couchbase check in Datadog Agent..."
    kubectl exec -n couchbase $DATADOG_POD -- agent status 2>/dev/null | grep -A 10 "couchbase" || echo "Run: kubectl exec -n couchbase $DATADOG_POD -- agent status"
else
    echo "⚠️  Datadog Agent pod not found yet"
fi
echo ""

echo "======================================"
echo "Verification Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Visit Couchbase UI: http://$MINIKUBE_IP:30091"
echo "2. Login with Administrator / Password123!"
echo "3. Check Datadog Dashboard for Couchbase metrics"
echo "4. Create a bucket in Couchbase to generate metrics"
echo ""

