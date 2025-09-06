#!/bin/bash
set -e

echo "🎯 Running KServe postCreate setup..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Set up GitHub Container Registry for ko
info "Setting up GitHub Container Registry for ko..."
if [ -n "${GITHUB_USER}" ]; then
    export KO_DOCKER_REPO="ghcr.io/${GITHUB_USER}"
    echo "export KO_DOCKER_REPO='ghcr.io/${GITHUB_USER}'" >> ~/.bashrc
    echo "export KO_DOCKER_REPO='ghcr.io/${GITHUB_USER}'" >> ~/.zshrc
    info "KO_DOCKER_REPO set to: ghcr.io/${GITHUB_USER}"
else
    # Fall back to local registry
    export KO_DOCKER_REPO="kserve-registry:5000"
    echo "export KO_DOCKER_REPO='kserve-registry:5000'" >> ~/.bashrc
    echo "export KO_DOCKER_REPO='kserve-registry:5000'" >> ~/.zshrc
    warn "GITHUB_USER not set, using local registry: kserve-registry:5000"
fi

# Configure git for DCO sign-off
info "Configuring git for DCO sign-off..."
git config --global user.name "${GITHUB_USER:-Developer}"
git config --global user.email "${GITHUB_EMAIL:-developer@example.com}"
git config --global commit.gpgsign false
git config --global format.signoff true

# Install Go tools required by KServe
info "Installing Go development tools..."
go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.16.2
go install github.com/google/ko@latest
go install github.com/google/go-licenses@latest
go install github.com/google/addlicense@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest

# Install pre-commit hooks
info "Installing pre-commit hooks..."
cd /workspaces/kserve
if [ ! -f ".pre-commit-config.yaml" ]; then
    cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        args: ['--allow-multiple-documents']
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: mixed-line-ending

  - repo: https://github.com/golangci/golangci-lint
    rev: v1.64.8
    hooks:
      - id: golangci-lint

  - repo: https://github.com/psf/black
    rev: 24.3.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/PyCQA/flake8
    rev: 7.1.0
    hooks:
      - id: flake8
        args: ['--config=.flake8']
EOF
fi
pre-commit install --install-hooks

# Install Python development dependencies
info "Installing Python development environment..."
cd /workspaces/kserve/python/kserve
pip install --user -e ".[test]" || pip install --user -e .

# Install additional Python servers for testing
for server in sklearnserver xgbserver lgbserver pmmlserver paddleserver huggingfaceserver; do
    if [ -d "/workspaces/kserve/python/${server}" ]; then
        info "Installing ${server}..."
        cd "/workspaces/kserve/python/${server}"
        pip install --user -e . || true
    fi
done

cd /workspaces/kserve

# Download Go dependencies
info "Downloading Go dependencies..."
go mod download
go mod tidy

# Build development tools
info "Building KServe development tools..."
make controller-gen kustomize

# Generate code and manifests
info "Generating code and manifests..."
make generate manifests

# Create cache directories
mkdir -p ~/.cache/go-build ~/.cache/pip ~/.docker

# Install KServe dependencies (cert-manager, Istio, Knative)
info "Installing KServe and its dependencies..."
if [ -f "./hack/quick_install.sh" ]; then
    # Check if user wants serverless or raw deployment mode
    if [ "${DEPLOYMENT_MODE}" = "RawDeployment" ]; then
        info "Installing KServe in RawDeployment mode..."
        ./hack/quick_install.sh -r
    else
        info "Installing KServe in Serverless mode (with Knative)..."
        ./hack/quick_install.sh -s
    fi
else
    error "quick_install.sh not found!"
fi

# Wait for all pods to be ready
info "Waiting for all system pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n kserve --timeout=300s || true
kubectl wait --for=condition=Ready pods --all -n cert-manager --timeout=300s || true

if [ "${DEPLOYMENT_MODE}" != "RawDeployment" ]; then
    kubectl wait --for=condition=Ready pods --all -n knative-serving --timeout=300s || true
    kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s || true
fi

# Deploy a sample model for testing
info "Deploying a sample sklearn model for testing..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: kserve-test
  labels:
    istio-injection: enabled
---
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: sklearn-iris
  namespace: kserve-test
spec:
  predictor:
    model:
      modelFormat:
        name: sklearn
      storageUri: "gs://kfserving-examples/models/sklearn/1.0/model"
EOF

# Create a helper script for common tasks
cat > ~/kserve-dev.sh <<'EOF'
#!/bin/bash

case "$1" in
    test)
        echo "Running KServe tests..."
        cd /workspaces/kserve && make test
        ;;
    e2e)
        echo "Running E2E tests..."
        cd /workspaces/kserve/test/e2e && python -m pytest -v
        ;;
    build)
        echo "Building KServe images..."
        cd /workspaces/kserve && make docker-build
        ;;
    deploy)
        echo "Deploying KServe to cluster..."
        cd /workspaces/kserve && make deploy-dev
        ;;
    logs)
        kubectl logs -n kserve deployment/kserve-controller-manager -f
        ;;
    status)
        echo "KServe Status:"
        kubectl get pods -n kserve
        echo ""
        echo "InferenceServices:"
        kubectl get inferenceservice -A
        ;;
    *)
        echo "Usage: kserve-dev.sh {test|e2e|build|deploy|logs|status}"
        exit 1
        ;;
esac
EOF
chmod +x ~/kserve-dev.sh

# Add aliases to shell configs
cat >> ~/.bashrc <<'EOF'

# KServe development aliases
alias ks='kubectl get inferenceservice'
alias ksw='watch kubectl get inferenceservice'
alias ksd='kubectl describe inferenceservice'
alias ksl='kubectl logs -n kserve deployment/kserve-controller-manager'
alias ksdev='~/kserve-dev.sh'

# Quick cluster access
export KSERVE_NAMESPACE=kserve-test

# Function to test inference
kserve-predict() {
    local service=$1
    local namespace=${2:-kserve-test}
    local data=${3:-'{"instances": [[5.1, 3.5, 1.4, 0.2]]}'}
    
    local url=$(kubectl get inferenceservice ${service} -n ${namespace} -o jsonpath='{.status.url}')
    echo "Sending prediction request to: ${url}/v1/models/${service}:predict"
    curl -X POST "${url}/v1/models/${service}:predict" \
        -H "Content-Type: application/json" \
        -d "${data}"
}
EOF

# Copy to zsh config as well
tail -n 20 ~/.bashrc >> ~/.zshrc

# Display summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           KServe Development Environment Ready!               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║ Cluster:          k3d-kserve-dev                             ║"
echo "║ Registry:         ${KO_DOCKER_REPO}                          ║"
echo "║ Deployment Mode:  ${DEPLOYMENT_MODE:-Serverless}             ║"
echo "║                                                               ║"
echo "║ Quick Commands:                                               ║"
echo "║   make test       - Run unit tests                           ║"
echo "║   make e2e-test   - Run E2E tests                           ║"
echo "║   ksdev status    - Check KServe status                     ║"
echo "║   ksdev logs      - View controller logs                    ║"
echo "║   k9s             - Kubernetes terminal UI                  ║"
echo "║                                                               ║"
echo "║ Sample Model:                                                ║"
echo "║   kubectl get isvc -n kserve-test                           ║"
echo "║   kserve-predict sklearn-iris                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

info "✅ PostCreate setup completed successfully!"