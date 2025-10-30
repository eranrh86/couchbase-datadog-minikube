#!/bin/bash

# Cleanup Script for Couchbase + Datadog Deployment
set -e

echo "======================================"
echo "Couchbase + Datadog Cleanup"
echo "======================================"
echo ""

read -p "Are you sure you want to delete the Couchbase deployment? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Deleting Couchbase cluster..."
kubectl delete -f couchbase-cluster.yaml --ignore-not-found=true

echo "Waiting for cluster to terminate..."
sleep 10

echo "Deleting Couchbase services..."
kubectl delete -f couchbase-service.yaml --ignore-not-found=true

echo "Deleting Datadog Agent..."
kubectl delete -f datadog-agent.yaml --ignore-not-found=true

echo "Deleting Couchbase Operator..."
kubectl delete -f couchbase-operator.yaml --ignore-not-found=true

echo "Deleting Couchbase CRD..."
kubectl delete -f couchbase-cluster-crd.yaml --ignore-not-found=true

echo "Deleting ConfigMaps..."
kubectl delete -f couchbase-configmap.yaml --ignore-not-found=true

echo "Deleting Secrets..."
kubectl delete -f couchbase-secret.yaml --ignore-not-found=true
kubectl delete secret datadog-secret -n couchbase --ignore-not-found=true

echo "Uninstalling Datadog Operator..."
helm uninstall datadog-operator -n couchbase --ignore-not-found || true

echo "Deleting namespace..."
kubectl delete namespace couchbase --ignore-not-found=true

echo ""
echo "✅ Cleanup complete!"

