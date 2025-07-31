#!/bin/bash

set -e

CLUSTER_NAME="argo-cluster"
NODEPORT=31274

echo "🧹 Deleting old cluster (if exists)..."
kind delete cluster --name $CLUSTER_NAME || true

echo "🛠️ Creating new Kind cluster with NodePort mapping..."
cat <<EOF | kind create cluster --name $CLUSTER_NAME --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
    - containerPort: $NODEPORT
      hostPort: $NODEPORT
EOF

echo "🚀 Installing Argo CD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=Available --timeout=120s deployment/argocd-server -n argocd

echo "🌐 Changing Argo CD service to NodePort..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

echo "🔑 Fetching admin password..."
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 --decode)

echo "✅ Done!"
echo
echo "🌍 Access Argo CD UI at: https://localhost:$NODEPORT"
echo "👤 Username: admin"
echo "🔐 Password: $ARGOCD_PASS"
echo
echo "📟 To log in via CLI:"
echo "argocd login localhost:$NODEPORT --username admin --password $ARGOCD_PASS --insecure"

