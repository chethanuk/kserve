#!/bin/bash
set -e

echo "🚀 Starting KServe development environment initial setup..."

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

# Create necessary directories
info "Creating necessary directories..."
mkdir -p ~/.kube ~/.docker ~/.cache/go-build ~/.cache/pip ~/.local/bin || true

# Set up environment variables
info "Setting up environment variables..."
export GOPATH="${HOME}/go"
export PATH="${GOPATH}/bin:/usr/local/go/bin:${HOME}/.local/bin:${PATH}"

# Check if running in the container
if [ ! -d "/workspaces/kserve" ]; then
    warn "Not in expected workspace directory, adjusting..."
    cd /workspace/kserve || cd /workspaces/kserve || true
fi

# Install Python dependencies if directory exists
if [ -d "python/kserve" ]; then
    info "Installing Python SDK..."
    cd python/kserve
    pip install --user --upgrade pip setuptools wheel || true
    pip install --user -e . || true
    cd ../..
else
    warn "Python SDK directory not found, skipping Python setup"
fi

# Download Go dependencies if go.mod exists
if [ -f "go.mod" ]; then
    info "Downloading Go dependencies..."
    go mod download || true
else
    warn "go.mod not found, skipping Go dependency download"
fi

# Install essential Go tools
info "Installing Go development tools..."
go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.16.2 || true
go install github.com/google/ko@latest || true

info "✅ onCreate setup completed!"