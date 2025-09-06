#!/bin/bash
# Quick setup script for KServe development environment

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         KServe Development Environment Setup                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

# Function to print colored messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in Codespaces
if [ "${CODESPACES}" = "true" ]; then
    info "Running in GitHub Codespaces environment"
else
    info "Running in local environment"
fi

# Make scripts executable
chmod +x .devcontainer/scripts/*.sh

# Option selection
echo ""
echo "Select setup option:"
echo "1) Full setup (k3d cluster + KServe installation)"
echo "2) Cluster only (k3d cluster without KServe)"
echo "3) Dependencies only (no cluster)"
echo "4) Reset everything"
echo ""
read -p "Enter option (1-4): " option

case $option in
    1)
        info "Starting full setup..."
        
        # Run onCreate script
        info "Setting up development environment..."
        .devcontainer/scripts/onCreate.sh
        
        # Run postStart script
        info "Starting services..."
        .devcontainer/scripts/postStart.sh
        
        # Install KServe
        info "Installing KServe..."
        if [ -f "./hack/quick_install.sh" ]; then
            ./hack/quick_install.sh
        else
            warn "quick_install.sh not found, skipping KServe installation"
        fi
        
        # Run postAttach script
        .devcontainer/scripts/postAttach.sh
        
        info "Full setup completed!"
        ;;
        
    2)
        info "Setting up k3d cluster only..."
        
        # Create k3d cluster
        if k3d cluster list | grep -q "kserve-dev"; then
            warn "Cluster 'kserve-dev' already exists"
        else
            k3d cluster create kserve-dev \
                --servers 1 \
                --agents 2 \
                --port "8080:80@loadbalancer" \
                --port "8443:443@loadbalancer" \
                --k3s-arg "--disable=traefik@server:0" \
                --registry-create kserve-registry:5000 \
                --wait
                
            info "Cluster created successfully"
        fi
        
        # Merge kubeconfig
        k3d kubeconfig merge kserve-dev --kubeconfig-merge-default
        
        # Create namespaces
        kubectl create namespace kserve --dry-run=client -o yaml | kubectl apply -f -
        kubectl create namespace kserve-test --dry-run=client -o yaml | kubectl apply -f -
        
        info "Cluster setup completed!"
        ;;
        
    3)
        info "Installing dependencies only..."
        
        # Install Python dependencies
        cd python/kserve && pip install -e . && cd ../..
        
        # Download Go dependencies
        go mod download
        
        # Install pre-commit hooks
        if [ -f ".pre-commit-config.yaml" ]; then
            pre-commit install
        fi
        
        info "Dependencies installed!"
        ;;
        
    4)
        warn "This will delete the k3d cluster and reset the environment"
        read -p "Are you sure? (y/N): " confirm
        
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            info "Resetting environment..."
            
            # Delete k3d cluster
            k3d cluster delete kserve-dev || true
            
            # Clean Docker
            docker system prune -af --volumes || true
            
            # Clean caches
            go clean -modcache || true
            pip cache purge || true
            
            info "Environment reset completed!"
        else
            info "Reset cancelled"
        fi
        ;;
        
    *)
        error "Invalid option"
        exit 1
        ;;
esac

# Display status
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check cluster status
if kubectl cluster-info &>/dev/null; then
    info "Kubernetes cluster is running"
    kubectl get nodes
else
    warn "Kubernetes cluster is not running"
fi

# Check KServe installation
if kubectl get deployment -n kserve kserve-controller-manager &>/dev/null; then
    info "KServe is installed"
    kubectl get pods -n kserve
else
    warn "KServe is not installed"
fi

# Display helpful commands
echo ""
echo -e "${GREEN}Helpful commands:${NC}"
echo "  k9s                    - Kubernetes terminal UI"
echo "  kubectl get pods -A    - List all pods"
echo "  kubectl get isvc -A    - List all InferenceServices"
echo "  make test              - Run tests"
echo "  make help              - Show all make targets"
echo ""
echo -e "${GREEN}For more information, see .devcontainer/README.md${NC}"