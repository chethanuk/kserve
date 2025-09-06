#!/bin/bash
set -e

echo "🔄 Running updateContent script..."

# Update git repository
echo "📥 Pulling latest changes..."
cd /workspaces/kserve
git fetch origin || true

# Update Go dependencies
echo "📦 Updating Go dependencies..."
go mod download
go mod tidy

# Update Python dependencies
echo "🐍 Updating Python dependencies..."
cd /workspaces/kserve/python/kserve
pip install --user -e . --upgrade --no-cache-dir

# Update pre-commit hooks
echo "🔧 Updating pre-commit hooks..."
cd /workspaces/kserve
if [ -f ".pre-commit-config.yaml" ]; then
    pre-commit autoupdate || true
fi

# Clean up old Docker images to save space
echo "🧹 Cleaning up old Docker images..."
docker image prune -f || true

# Update tools
echo "🛠️ Updating development tools..."
go install -tags extended golang.org/x/tools/gopls@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

echo "✅ updateContent script completed!"