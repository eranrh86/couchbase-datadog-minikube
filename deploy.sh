#!/bin/bash

# Couchbase Deployment Script for Minikube with Datadog Monitoring
set -e

echo "======================================"
echo "Couchbase + Datadog Deployment"
echo "======================================"
echo ""

# Check if Datadog API key is set
if [ -z "$DD_API_KEY" ]; then
    echo "⚠️  WARNING: DD_API_KEY environment variable is not set!"
    echo "Please set your Datadog API key:"
    echo "export DD_API_KEY='your-api-key-here'"
    echo ""
    read -p "Enter your Datadog API key: " DD_API_KEY
    if [ -z "$DD_API_KEY" ]; then
        echo "❌ Datadog API key is required. Exiting..."
        exit 1
    fi
fi

echo "Step 1: Creating couchbase namespace..."
kubectl apply -f namespace.yaml

echo ""
echo "Step 2: Installing Datadog Operator..."
helm repo add datadog https://helm.datadoghq.com || true
helm repo update
kubectl create secret generic datadog-secret --from-literal api-key="$DD_API_KEY" -n couchbase --dry-run=client -o yaml | kubectl apply -f -

# Install Datadog Operator
helm upgrade --install datadog-operator datadog/datadog-operator -n couchbase --wait

echo ""
echo "Step 3: Installing Couchbase CRD..."
kubectl apply -f couchbase-cluster-crd.yaml

echo ""
echo "Step 4: Deploying Couchbase Operator..."
kubectl apply -f couchbase-operator.yaml

echo ""
echo "Step 5: Waiting for Couchbase Operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/couchbase-operator -n couchbase

echo ""
echo "Step 6: Creating Couchbase admin credentials..."
kubectl apply -f couchbase-secret.yaml

echo ""
echo "Step 7: Deploying Datadog Agent with Couchbase integration..."
kubectl apply -f datadog-agent.yaml

echo ""
echo "Step 8: Waiting for Datadog Agent to be ready..."
sleep 10

echo ""
echo "Step 9: Deploying Couchbase Cluster..."
kubectl apply -f couchbase-cluster.yaml

echo ""
echo "Step 10: Deploying Couchbase Services..."
kubectl apply -f couchbase-service.yaml

echo ""
echo "Step 11: Applying Couchbase Datadog ConfigMap..."
kubectl apply -f couchbase-configmap.yaml

echo ""
echo "======================================"
echo "✅ Deployment Complete!"
echo "======================================"
echo ""
echo "Couchbase cluster is being provisioned..."
echo ""
echo "To check the status:"
echo "  kubectl get all -n couchbase"
echo ""
echo "To access Couchbase UI:"
echo "  minikube service cb-cluster-ui -n couchbase"
echo "  Or visit: http://$(minikube ip):30091"
echo ""
echo "Credentials:"
echo "  Username: Administrator"
echo "  Password: Password123!"
echo ""
echo "To view logs:"
echo "  kubectl logs -n couchbase -l app=couchbase-operator"
echo "  kubectl logs -n couchbase -l couchbase_cluster=cb-cluster"
echo ""
echo "To check Datadog Agent status:"
echo "  kubectl get datadogagent -n couchbase"
echo "  kubectl get pods -n couchbase -l app.kubernetes.io/name=datadog-agent"
echo ""
echo "Wait a few minutes for Couchbase cluster to be fully ready..."

