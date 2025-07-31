✅ Overview
Create a Kind cluster.

Install Argo CD in the cluster.

Serve your local Git repo via a local web server.

Push a GitOps NGINX manifest into the local repo.

Configure Argo CD to sync from that repo.

Expose NGINX via NodePort or port-forward and verify in browser.

Prerequisites
Ensure you have installed:

Docker

Kind

kubectl

Argo CD CLI (optional)

Python (for serving local Git repo)

Git

Step 1: Create a Kind Cluster
bash
Copy
Edit
cat <<EOF | kind create cluster --name argo-nginx --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
EOF

This maps container port 30080 to your local machine localhost:8080 (for NGINX browser access later).

📦 Step 2: Install Argo CD
bash
Copy
Edit
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
Wait a bit for all pods to be ready.

Step 3: Expose Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8083:443
Access Argo CD UI at https://localhost:8083

Get the initial admin password:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo


refer the workflow repo nginx-deploy.yaml nginx-service.yaml  kustomization.yaml

Step 6: Create Argo CD App (GitOps)

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-app
  namespace: argocd
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  project: default
  source:
    repoURL: http://host.docker.internal:8000
    targetRevision: HEAD
    path: .
    directory:
      recurse: true
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF


Step 7: Open NGINX in Browser
Once Argo CD syncs the app, access:

http://localhost:8080

You should see the default NGINX welcome page.


