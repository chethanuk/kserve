#!/bin/bash
set -e

echo "📎 Running postAttach script..."

# Set terminal title
echo -ne "\033]0;KServe Development\007"

# Check cluster health
echo "🏥 Checking cluster health..."
kubectl get nodes -o wide || echo "⚠️ Cluster not ready"

# Display current context
echo "📍 Current Kubernetes context:"
kubectl config current-context

# Show KServe related pods
echo "🎯 KServe pods status:"
kubectl get pods -n kserve --no-headers 2>/dev/null || echo "No KServe pods found"
kubectl get pods -n kserve-test --no-headers 2>/dev/null || echo "No test pods found"

# Show any existing InferenceServices
echo "🤖 InferenceServices:"
kubectl get inferenceservice -A --no-headers 2>/dev/null || echo "No InferenceServices found"

# Git status
echo "📝 Git status:"
cd /workspaces/kserve
git status --short

# Show TODO if exists
if [ -f "TODO.md" ]; then
    echo "📋 TODO items:"
    head -10 TODO.md
fi

# Reminder about common tasks
echo "
💡 Quick tips:
   • Run 'make help' to see available make targets
   • Use 'k9s' for interactive Kubernetes management
   • Run './hack/quick_install.sh' to install KServe
   • Check '.devcontainer/README.md' for more details
"

echo "✅ postAttach script completed!"