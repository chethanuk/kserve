#!/bin/bash
set -e

# Check if essential commands are available
if ! command -v cat &> /dev/null || ! command -v sleep &> /dev/null; then
    echo "ERROR: Essential commands missing. Installing coreutils..."
    sudo apt-get update && sudo apt-get install -y coreutils || true
fi

echo "🔄 Running postStart script..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Start Docker daemon if not running (for Docker-in-Docker)
if command -v docker &> /dev/null; then
    if ! docker info >/dev/null 2>&1; then
        info "Starting Docker daemon..."
        sudo service docker start || sudo dockerd &> /dev/null & || true
        sleep 5
    fi
else
    warn "Docker not found, skipping Docker daemon check"
fi

# Start k3d cluster if it exists but is stopped
if command -v k3d &> /dev/null && k3d cluster list | grep -q "kserve-dev"; then
    if ! kubectl cluster-info >/dev/null 2>&1; then
        info "Starting k3d cluster..."
        k3d cluster start kserve-dev
        sleep 10
        
        # Wait for nodes to be ready
        kubectl wait --for=condition=Ready nodes --all --timeout=120s || true
    fi
else
    warn "k3d cluster 'kserve-dev' not found. Run onCreate.sh or postCreate.sh to create it."
fi

# Ensure kubeconfig is set correctly
export KUBECONFIG="${HOME}/.kube/config"

# Set up GitHub Container Registry authentication if GitHub token is available
if [ -n "${GITHUB_TOKEN}" ]; then
    info "Configuring GitHub Container Registry authentication..."
    echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_USER}" --password-stdin || true
fi

# Check cluster status
if command -v kubectl &> /dev/null; then
    info "Checking cluster status..."
    if kubectl cluster-info >/dev/null 2>&1; then
    info "Kubernetes cluster is running"
        kubectl get nodes
    else
        warn "Kubernetes cluster is not available"
    fi
else
    warn "kubectl not found, skipping cluster status check"
fi

# Install or update cert-manager if needed
if command -v kubectl &> /dev/null && ! kubectl get deployment -n cert-manager cert-manager >/dev/null 2>&1; then
    echo "📜 Installing cert-manager..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.yaml
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-cainjector -n cert-manager
fi

# Check if Istio is needed and install if missing
if [ "${INSTALL_ISTIO:-false}" = "true" ] && command -v kubectl &> /dev/null; then
    if ! kubectl get deployment -n istio-system istiod >/dev/null 2>&1; then
        echo "🕸️ Installing Istio..."
        istioctl install --set profile=default -y
        kubectl wait --for=condition=available --timeout=300s deployment/istiod -n istio-system
    fi
fi

# Set up local Docker registry if not exists
if command -v docker &> /dev/null && ! docker ps | grep -q kserve-registry; then
    echo "📦 Setting up local Docker registry..."
    docker run -d --restart=always \
        --name kserve-registry \
        -p 5000:5000 \
        -v /tmp/registry:/var/lib/registry \
        registry:2
fi

# Pull commonly used images to speed up development
if command -v docker &> /dev/null; then
    echo "🖼️ Pre-pulling common images..."
    docker pull python:3.12-slim &
    docker pull golang:1.24.1 &
fi

# Display helpful information
echo "
╔══════════════════════════════════════════════════════════════╗
║                 KServe Development Environment                ║
╠══════════════════════════════════════════════════════════════╣
║ Kubernetes Cluster: k3d-kserve-dev                          ║
║ Docker Registry:    kserve-registry:5000                    ║
║ Namespaces:        kserve, kserve-test                      ║
║                                                              ║
║ Quick Commands:                                              ║
║   k9s                 - Kubernetes CLI UI                   ║
║   kserve-test        - Check KServe installation           ║
║   make test          - Run tests                           ║
║   make docker-build  - Build Docker images                 ║
║                                                              ║
║ Port Forwards:                                              ║
║   8080 - KServe inference service                          ║
║   8443 - HTTPS traffic                                     ║
║   5000 - Local Docker registry                             ║
╚══════════════════════════════════════════════════════════════╝
"

echo "✅ postStart script completed!"