# KServe Development Container

## 🚀 Overview

This devcontainer provides a fully-featured KServe development environment that follows the official [KServe Developer Guide](https://kserve.github.io/website/docs/developer-guide) exactly. It automates all setup steps to save developers hours of manual configuration.

## ✨ Features

### Pre-installed Tools & Languages
- **Go 1.24.1+** - Required version for KServe development
- **Python 3.12** - With uv for virtual environment management
- **Docker-in-Docker** - Full Docker support inside container
- **Kubernetes Tools**:
  - kubectl, helm, kustomize
  - k3d (lightweight Kubernetes clusters)
  - kind (alternative cluster option)
  - k9s (terminal UI for Kubernetes)
- **Development Tools**:
  - ko (container image builder)
  - controller-gen (Kubernetes controller tools)
  - golangci-lint (Go linter)
  - black & flake8 (Python formatters)
  - pre-commit hooks
  - GitHub CLI

### Automated Setup

The devcontainer automatically:
1. Creates a k3d Kubernetes cluster (`kserve-dev`)
2. Installs KServe and all dependencies (cert-manager, Istio, Knative)
3. Configures GitHub Container Registry for image pushing
4. Sets up pre-commit hooks
5. Installs Python SDK and all server dependencies
6. Generates code and manifests
7. Deploys a sample model for testing

## 🏃 Quick Start

### For GitHub Codespaces

1. Click "Code" → "Codespaces" → "Create codespace on master"
2. Wait for the container to build and initialize (5-10 minutes first time)
3. The environment will be ready with KServe installed!

### For Local Development

1. Install prerequisites:
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [VS Code](https://code.visualstudio.com/)
   - [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. Clone and open in container:
   ```bash
   git clone https://github.com/kserve/kserve.git
   cd kserve
   code .
   # Press F1 → "Dev Containers: Reopen in Container"
   ```

## 🔧 Configuration

### Environment Variables

The container automatically configures:
- `GOPATH=/home/vscode/go`
- `KO_DOCKER_REPO=ghcr.io/${GITHUB_USER}` (or local registry)
- `KSERVE_NAMESPACE=kserve-test`
- `KUBECONFIG=/home/vscode/.kube/config`
- `DOCKER_BUILDKIT=1`

### GitHub Container Registry Setup

For pushing images to GHCR:
1. Create a GitHub Personal Access Token with `write:packages` scope
2. Set environment variables:
   ```bash
   export GITHUB_USER=your-username
   export GITHUB_TOKEN=your-token
   ```
3. The container will automatically configure authentication

### Deployment Modes

Choose between two modes by setting `DEPLOYMENT_MODE`:
- **Serverless** (default): Full KServe with Knative
- **RawDeployment**: Lightweight without Knative

## 📚 Development Workflows

### Building and Testing

```bash
# Run all tests
make test

# Run specific tests
go test ./pkg/controller/v1beta1/...

# Python tests
cd python/kserve && pytest

# E2E tests
make test-e2e

# Format and lint
make fmt vet go-lint py-fmt py-lint
```

### Building Images

```bash
# Build controller
make docker-build IMG=your-repo/controller:tag

# Build with ko (recommended)
ko build ./cmd/manager

# Build Python servers
make docker-build-sklearn
make docker-build-xgb
```

### Deploying Changes

```bash
# Deploy development version
make deploy-dev

# Deploy specific component
make deploy-dev-sklearn

# Apply custom manifests
kubectl apply -f config/samples/
```

### Working with InferenceServices

```bash
# List all InferenceServices
kubectl get isvc -A

# Deploy a sample model
kubectl apply -f docs/samples/v1beta1/sklearn/v1/sklearn.yaml

# Check status
kubectl describe isvc sklearn-iris -n kserve-test

# Test prediction
curl -X POST http://sklearn-iris.kserve-test.svc.cluster.local/v1/models/sklearn-iris:predict \
  -H "Content-Type: application/json" \
  -d '{"instances": [[5.1, 3.5, 1.4, 0.2]]}'
```

## 🛠️ Helper Commands

The container includes helpful aliases:

```bash
# Kubernetes shortcuts
k          # kubectl
kgp        # kubectl get pods
kgs        # kubectl get svc
klog       # kubectl logs
kexec      # kubectl exec -it

# KServe specific
ks         # kubectl get inferenceservice
ksw        # watch kubectl get inferenceservice
ksd        # kubectl describe inferenceservice
ksl        # kubectl logs -n kserve deployment/kserve-controller-manager

# Development helper
ksdev status    # Check KServe installation
ksdev test      # Run tests
ksdev build     # Build images
ksdev deploy    # Deploy to cluster
ksdev logs      # View controller logs
```

## 🐛 Troubleshooting

### Cluster Issues

```bash
# Check cluster status
kubectl cluster-info
k3d cluster list

# Restart cluster
k3d cluster stop kserve-dev
k3d cluster start kserve-dev

# Reset everything
k3d cluster delete kserve-dev
./hack/quick_install.sh -s
```

### Build Issues

```bash
# Clean and rebuild
make clean
go clean -modcache
make generate manifests

# Update dependencies
go mod download
go mod tidy
```

### Pod Issues

```bash
# Check pod logs
kubectl logs -n kserve deployment/kserve-controller-manager
kubectl logs pod-name -c storage-initializer

# Debug failing pods
kubectl describe pod pod-name
kubectl get events -n namespace
```

## 📋 Pre-commit Hooks

The container automatically installs pre-commit hooks that run:
- Go formatting and linting
- Python black and flake8
- YAML validation
- Trailing whitespace removal
- File ending fixes

To run manually:
```bash
pre-commit run --all-files
```

## 🔄 Keeping Updated

```bash
# Update devcontainer
git pull origin master
# Rebuild container (F1 → "Dev Containers: Rebuild Container")

# Update KServe components
./hack/quick_install.sh -s

# Update Go dependencies
go get -u ./...
go mod tidy
```

## 📊 Resource Requirements

- **CPU**: 4+ cores recommended
- **Memory**: 8GB minimum, 16GB recommended
- **Storage**: 32GB minimum
- **Network**: Good internet connection for pulling images

## 🤝 Contributing Workflow

1. **Create feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes and test**:
   ```bash
   # Make your changes
   make test
   make precommit
   ```

3. **Sign commits (required)**:
   ```bash
   git commit -s -m "feat: add new feature"
   ```

4. **Push and create PR**:
   ```bash
   git push origin feature/my-feature
   gh pr create
   ```

## 📝 Additional Resources

- [KServe Developer Guide](https://kserve.github.io/website/docs/developer-guide)
- [Contributing Guide](https://github.com/kserve/community/blob/main/CONTRIBUTING.md)
- [KServe Documentation](https://kserve.github.io/website/)
- [CLAUDE.md](../CLAUDE.md) - AI assistant instructions

## ⚡ Quick Setup Script

For manual setup or troubleshooting, run:
```bash
.devcontainer/setup.sh
```

Options:
1. Full setup (cluster + KServe)
2. Cluster only
3. Dependencies only
4. Reset everything

## 🎯 Development Tips

1. **Use k9s** for visual cluster management
2. **Enable auto-save** in VS Code for real-time formatting
3. **Use ko** for faster image building during development
4. **Check controller logs** when debugging issues
5. **Run pre-commit** before pushing to catch issues early

## 🚨 Important Notes

- The first container build takes 10-15 minutes
- Subsequent starts are much faster (1-2 minutes)
- The k3d cluster persists between container restarts
- All tools are pre-configured with optimal settings
- DCO sign-off is automatically configured

## 💡 Pro Tips

### Speed up builds:
```bash
export DOCKER_BUILDKIT=1
export KO_DOCKER_REPO=kserve-registry:5000  # Use local registry
```

### Debug controller:
```bash
# Enable verbose logging
kubectl edit configmap/inferenceservice-config -n kserve
# Set log level to debug
```

### Test locally:
```bash
# Port forward to access services
kubectl port-forward svc/sklearn-iris-predictor-default 8080:80 -n kserve-test
curl localhost:8080/v1/models/sklearn-iris:predict -d @input.json
```

---

**Need help?** Check the [KServe Slack](https://kubeflow.slack.com) #kserve-dev channel or open an issue!