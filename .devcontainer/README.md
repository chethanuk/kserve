# KServe Development Environment

This development container provides a complete environment for KServe development with all required tools pre-installed and configured. It enables contributors to quickly set up a local development environment that matches the KServe CI/CD pipeline requirements.

## Prerequisites

- **GitHub Codespaces** (recommended) or **Docker Desktop** with dev containers support
- **VS Code** with the Dev Containers extension
- **System Requirements**:
  - Minimum: 4 CPUs, 8GB RAM, 32GB storage  
  - Recommended: 8 CPUs, 16GB RAM, 64GB storage

## Quick Start

### GitHub Codespaces (Recommended)
1. Navigate to the [KServe repository](https://github.com/kserve/kserve)
2. Click **Code** → **Codespaces** → **Create codespace on master**
3. Wait for automatic setup (k3d cluster creation and dependency installation)
4. Install KServe components: `./hack/quick_install.sh`

### Local Development
1. Clone the repository: `git clone https://github.com/kserve/kserve.git`
2. Open in VS Code and select "Reopen in Container"
3. Follow the same setup steps as Codespaces

## Development Environment

### Core Technologies
- **Go 1.24**: KServe controller and CLI development
- **Python 3.12**: Python SDK, model servers, and testing
- **Docker-in-Docker**: Container builds and local registry
- **k3d**: Lightweight Kubernetes cluster for development

### Kubernetes Stack
- **kubectl**: Kubernetes CLI with essential plugins
- **helm**: Package manager for Kubernetes applications  
- **k9s**: Terminal-based Kubernetes dashboard
- **istioctl**: Istio service mesh management
- **kustomize**: Kubernetes configuration templating

### Development Tools  
- **ko**: Efficient Go application builds for Kubernetes
- **controller-gen**: Kubernetes controller code generation
- **golangci-lint**: Comprehensive Go code analysis
- **kubebuilder**: Kubernetes operator development framework

## KServe Development Workflow

### 1. Environment Setup
```bash
# Verify cluster is running
k3d cluster list

# Install KServe (serverless mode - default)
./hack/quick_install.sh

# Or install in raw deployment mode
./hack/quick_install.sh -r
```

### 2. Build and Test
```bash
# Run unit tests
make test

# Run integration tests  
make test-integration

# Run end-to-end tests
make test-e2e

# Build all components
make docker-build
```

### 3. Development Cycle
```bash
# Make code changes to controller/SDK

# Generate CRDs and manifests
make manifests

# Build and deploy changes
make deploy

# Test with sample InferenceService
kubectl apply -f docs/samples/v1beta1/sklearn/v1/sklearn.yaml
```

### 4. Python SDK Development
```bash
# Install SDK in editable mode
cd python/kserve && pip install -e .

# Run Python tests
cd python && make test

# Build Python model servers
make docker-build-sklearn
```

## Configuration

### Container Environment
The devcontainer automatically configures:
- **KUBECONFIG**: Points to k3d cluster configuration
- **KO_DOCKER_REPO**: Local registry at `kserve-registry:5000`
- **Go modules**: Cached for faster builds
- **Python packages**: Pre-installed KServe SDK dependencies

### Port Forwarding
- **8080**: KServe inference endpoints
- **8081**: Additional services  
- **5000**: Local container registry

### Persistent Storage
Caches are preserved across container rebuilds:
- Go module cache: Faster dependency downloads
- Docker layer cache: Reduced image build times
- pip cache: Accelerated Python package installation

## Testing Your Changes

### InferenceService Testing
```bash
# Deploy sample model
kubectl apply -f docs/samples/v1beta1/sklearn/v1/sklearn.yaml

# Check deployment status
kubectl get inferenceservice sklearn-iris -n kserve-test

# Test inference
kubectl get inferenceservice sklearn-iris -n kserve-test -o jsonpath='{.status.url}'
curl -v -H "Content-Type: application/json" <URL>/v1/models/sklearn-iris:predict -d @input.json
```

### Controller Testing
```bash
# View controller logs
kubectl logs -f -n kserve deployment/kserve-controller-manager

# Debug with detailed logging
kubectl patch configmap -n kserve config-logging --patch '{"data":{"zap-logger-config":"{\"level\":\"debug\"}"}}'
```

## Troubleshooting

### Cluster Issues
```bash
# Check cluster health
kubectl get nodes
kubectl get pods -A

# Restart k3d cluster
k3d cluster stop kserve
k3d cluster start kserve

# Recreate cluster if needed  
k3d cluster delete kserve
k3d cluster create kserve --servers 1 --agents 1 --registry-create kserve-registry:5000
```

### Build Problems
```bash
# Clear Go module cache
go clean -modcache

# Reset Docker environment
docker system prune -af

# Rebuild containers
make docker-build
```

### Storage Issues
```bash
# Check disk usage
df -h

# Clean up development artifacts
docker system prune -af --volumes
go clean -cache
pip cache purge
```

## Key Commands

### Kubernetes Shortcuts
```bash
kubectl get inferenceservice        # List InferenceServices
kubectl get servingruntime          # List ServingRuntimes  
kubectl describe isvc <name>        # Detailed InferenceService info
kubectl logs -f <pod>               # Follow pod logs
```

### Development Commands
```bash
make help                          # Show all available make targets
make manifests                     # Generate CRDs and RBAC
make fmt                          # Format Go code  
make vet                          # Run Go vet
make test                         # Run unit tests
make deploy                       # Deploy to cluster
```

## Integration with CI/CD

This development environment mirrors the KServe CI pipeline:
- Same Go and Python versions as GitHub Actions
- Identical test frameworks and linting tools
- Compatible container build processes
- Matching Kubernetes versions for e2e testing

## Contributing Guidelines

1. **Fork and Branch**: Create feature branches from `master`
2. **Code Quality**: Run `make fmt vet lint test` before committing  
3. **Documentation**: Update relevant docs for API changes
4. **Testing**: Add tests for new functionality
5. **Commit Messages**: Follow conventional commit format

## Additional Resources

- **KServe Documentation**: https://kserve.github.io/website/
- **Developer Guide**: https://kserve.github.io/website/docs/developer/
- **API Reference**: https://kserve.github.io/website/docs/reference/api/
- **Contributing Guidelines**: https://github.com/kserve/kserve/blob/master/CONTRIBUTING.md
- **Community Slack**: #kserve on Kubeflow Slack
- **Community Meetings**: https://github.com/kserve/community

For issues or suggestions regarding the development environment, please open an issue in the [KServe repository](https://github.com/kserve/kserve/issues).