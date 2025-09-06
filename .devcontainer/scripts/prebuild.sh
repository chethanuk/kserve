#!/bin/bash
set -e

echo "🏗️ Running prebuild script for GitHub Codespaces..."

# This script runs during prebuild to cache dependencies and speed up container creation

# Download and cache Go dependencies
echo "📦 Caching Go dependencies..."
cd /workspaces/kserve
go mod download
go mod verify

# Pre-compile commonly used Go packages
echo "🔨 Pre-compiling Go packages..."
go build -v ./cmd/...
go test -c -o /dev/null ./pkg/... 2>/dev/null || true

# Install Python dependencies
echo "🐍 Caching Python dependencies..."
cd /workspaces/kserve/python/kserve
pip install --user -e . --no-cache-dir

# Download commonly used Docker images
echo "🖼️ Pre-pulling Docker images..."
docker pull gcr.io/kubebuilder/kube-rbac-proxy:v0.16.0 &
docker pull python:3.12-slim &
docker pull golang:1.24-alpine &
docker pull registry:2 &
wait

# Download Kubernetes manifests and tools
echo "📜 Downloading Kubernetes manifests..."
curl -LO https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.yaml
curl -LO https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

# Create cache directories with proper permissions
echo "📁 Setting up cache directories..."
mkdir -p /home/vscode/.cache/go-build \
         /home/vscode/.cache/pip \
         /home/vscode/.kube \
         /home/vscode/.docker \
         /home/vscode/.config \
         /home/vscode/.local/bin

# Cache kubectl plugins
echo "🔌 Installing kubectl plugins..."
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
kubectl krew install ctx ns tree neat || true

# Generate any needed code
echo "⚙️ Generating code..."
cd /workspaces/kserve
make generate || true

# Clean up to reduce image size
echo "🧹 Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
go clean -cache

echo "✅ Prebuild completed successfully!"
echo "📊 Disk usage after prebuild:"
df -h /