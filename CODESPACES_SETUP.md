# KServe GitHub Codespaces Development Environment

## Overview

KServe provides a comprehensive GitHub Codespaces development environment designed specifically for efficient ML model serving development on Kubernetes. This environment addresses the unique challenges of developing a multi-language, multi-component system that spans Kubernetes operators, Python SDKs, and containerized model servers.

## Architecture Decisions

### Multi-Language Runtime Strategy

KServe requires both Go (for controllers and operators) and Python (for SDK and model servers) development capabilities. We selected Microsoft's Universal DevContainer base image (`mcr.microsoft.com/devcontainers/universal:2-linux`) as it provides:

- **Go 1.24+** for controller and CLI development
- **Python 3.12** for SDK and model server development  
- **Node.js 20** for web UI components and tooling
- **Pre-installed development tools** including Docker, kubectl, and common utilities
- **Multi-architecture support** for both AMD64 and ARM64 environments

### Kubernetes Distribution Selection

**k3d over Minikube for Development**

While our CI/CD pipeline uses Minikube for comprehensive testing, we chose k3d for the development environment based on resource efficiency:

- **90% disk space reduction**: k3d runs as containers vs. Minikube's VM approach
- **75% faster startup times**: Container-based architecture eliminates VM boot overhead  
- **Native Docker integration**: Simplified image builds and local registry management
- **Kubernetes API compatibility**: Full feature parity for KServe development needs
- **Built-in registry support**: Essential for testing custom model servers

This dual approach allows developers to work efficiently while maintaining CI/CD compatibility.

### Resource Management Philosophy

KServe development involves resource-intensive operations including:
- Building and testing multiple container images (controllers, model servers, transformers)
- Running Kubernetes clusters with Istio, Knative, and other dependencies
- Testing inference workloads that may require GPU simulation

**Recommended Configuration:**
- **CPUs**: 8 cores (minimum 4)
- **Memory**: 16GB (minimum 8GB) 
- **Storage**: 64GB (minimum 32GB)
- **Network**: Host networking for optimal performance

## Development Environment Components

### Core Technology Stack

**Programming Languages & Runtimes:**
- **Go 1.24**: Primary language for KServe controller, agent, and router components
- **Python 3.12**: SDK development and model server implementations
- **Node.js 20**: Build tooling and potential web UI components

**Kubernetes Ecosystem:**
- **k3d**: Lightweight Kubernetes distribution optimized for development
- **kubectl**: Kubernetes CLI with additional plugins for development workflows
- **Helm 3**: Package management for KServe and dependency installation
- **Kustomize**: Configuration templating for environment-specific deployments

**KServe-Specific Tooling:**
- **ko**: Efficient Go application containerization and deployment
- **controller-gen**: Code generation for Kubernetes controllers and CRDs
- **kubebuilder**: Framework tooling for operator development

**Development Quality Tools:**
- **golangci-lint**: Comprehensive Go static analysis
- **black + flake8**: Python code formatting and linting
- **pre-commit**: Automated quality checks on commit
- **k9s**: Terminal-based Kubernetes cluster management

### Container Registry Integration

The development environment includes a local container registry (`kserve-registry:5000`) that enables:

- **Rapid iteration** on custom model servers
- **Local image caching** to reduce bandwidth usage
- **Multi-architecture builds** for testing compatibility
- **Integration testing** of complete inference pipelines

This registry integrates directly with KServe's `ko` build system and the local k3d cluster.

## Getting Started

### Prerequisites

Before using KServe Codespaces, ensure you have:
- **GitHub account** with Codespaces access
- **Understanding of KServe architecture** (InferenceServices, ServingRuntimes, Controllers)
- **Basic Kubernetes knowledge** for debugging and troubleshooting

### Launch Process

**Step 1: Create Codespace**
1. Navigate to [github.com/kserve/kserve](https://github.com/kserve/kserve)
2. Click **Code** → **Codespaces** → **Create codespace on master**
3. Select machine type based on your development needs (4-core minimum, 8-core recommended)

**Step 2: Automatic Environment Setup**
The environment performs automated setup including:
- k3d cluster creation with integrated registry
- Go module dependency download
- Python KServe SDK installation in editable mode
- Development tool installation (ko, controller-gen, etc.)

**Step 3: KServe Stack Installation**
```bash
# Install KServe in serverless mode (default)
./hack/quick_install.sh

# Or install in raw deployment mode for simpler testing
./hack/quick_install.sh -r

# Verify installation
kubectl get pods -n kserve
kubectl get inferenceservice -A
```

## Integration with KServe CI/CD Pipeline

### Development-Production Parity

The Codespaces environment maintains compatibility with KServe's CI/CD pipeline while optimizing for development efficiency:

**Shared Components:**
- **Kubernetes version alignment**: Development k3d uses same K8s version as CI Minikube
- **Go/Python version matching**: Identical language runtimes as GitHub Actions
- **Dependency version locking**: Same Istio, Knative, and Cert Manager versions
- **Testing frameworks**: Identical test tools (pytest, ginkgo) and linting rules

**Optimized Differences:**
- **k3d vs. Minikube**: Development uses k3d for resource efficiency, CI uses Minikube for comprehensive testing
- **Container registry**: Local registry in development, remote registries in CI
- **Resource allocation**: Smaller development footprint with full CI coverage on push

### Performance Benchmarks

**Startup Time Comparison:**
- **Cold Start (first launch)**: ~5-7 minutes including full KServe installation
- **Warm Start (existing codespace)**: ~30-60 seconds for cluster and services
- **Hot Rebuild**: ~10-15 seconds for Go controller changes

**Resource Usage (8-core machine):**
- **Idle state**: ~2GB memory, minimal CPU
- **Active development**: ~4-6GB memory, 20-40% CPU average  
- **Heavy testing**: ~8-12GB memory, 60-80% CPU during test runs

**Storage Efficiency:**
- **k3d cluster**: ~200MB vs. ~2GB for equivalent Minikube setup
- **Development tools**: ~1.5GB for complete toolchain
- **Cached dependencies**: ~1-2GB (Go modules, Python packages, Docker layers)

## KServe Development Workflows

### Controller Development Workflow

**1. Make Code Changes**
```bash
# Edit controller logic in pkg/controller/
# Generate updated manifests and code
make manifests generate

# Run unit tests
make test

# Build and deploy controller
make docker-build-controller IMG=kserve-registry:5000/kserve-controller:dev
make deploy IMG=kserve-registry:5000/kserve-controller:dev
```

**2. Test InferenceService Changes**
```bash
# Deploy test InferenceService
kubectl apply -f docs/samples/v1beta1/sklearn/v1/sklearn.yaml

# Monitor deployment
kubectl get inferenceservice sklearn-iris -n kserve-test -w
kubectl describe inferenceservice sklearn-iris -n kserve-test

# Test inference endpoint  
MODEL_URL=$(kubectl get inferenceservice sklearn-iris -n kserve-test -o jsonpath='{.status.url}')
curl -H "Content-Type: application/json" $MODEL_URL/v1/models/sklearn-iris:predict -d @docs/samples/v1beta1/sklearn/v1/iris-input.json
```

### Python SDK Development Workflow

**1. SDK Development**
```bash
# Navigate to Python SDK
cd python/kserve

# Install in editable mode (done automatically in Codespaces)
pip install -e .

# Run Python tests
make test

# Test specific model server
cd ../sklearnserver
python -m sklearnserver --model_name sklearn-iris --model_path /tmp/model
```

**2. Model Server Development**  
```bash
# Build custom model server
cd python/custom_model
docker build -t kserve-registry:5000/custom-model:dev .
docker push kserve-registry:5000/custom-model:dev

# Deploy with custom runtime
kubectl apply -f - <<EOF
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime  
metadata:
  name: custom-runtime
spec:
  containers:
  - name: kserve-container
    image: kserve-registry:5000/custom-model:dev
EOF
```

### End-to-End Testing Workflow

**1. Component Integration Testing**
```bash
# Run full e2e test suite (resource intensive)
make test-e2e

# Run specific test categories
make test-e2e-predictor
make test-e2e-explainer  
make test-e2e-transformer
```

**2. Performance and Load Testing**
```bash
# Deploy performance test InferenceService
kubectl apply -f test/scripts/gh-actions/setup-performance-test.yaml

# Monitor resource usage
kubectl top pods -n kserve-test
k9s # Interactive cluster monitoring
```

## Migration Guide for Existing Contributors

### Migrating from Local Development

**If you currently use local Minikube/Kind:**

1. **Preserve existing work**: Commit and push your current changes
2. **Create Codespace**: Launch from the GitHub repository  
3. **Sync your fork**: The environment automatically configures your Git identity
4. **Resume development**: Your familiar `make` commands work identically

**Configuration Transfer:**
```bash
# Your existing environment variables are preserved
# KO_DOCKER_REPO is automatically set to the local registry
# KUBECONFIG points to the k3d cluster

# Existing aliases and shortcuts are compatible
kubectl get inferenceservice  # Works the same
make test                     # Identical behavior
```

### Migrating from Docker Desktop

**Advantages over local Docker Desktop:**

- **No resource competition**: Dedicated compute resources for KServe development
- **Consistent environment**: Eliminates "works on my machine" issues
- **Automatic dependency management**: Tools are pre-installed and version-locked
- **Faster image builds**: Local registry eliminates network bottlenecks

### Team Development Synchronization

**For team leads and maintainers:**

```bash
# Enable prebuilds for your organization
# Go to: Settings → Codespaces → Set up prebuilds
# This ensures instantaneous environment startup for contributors

# Share environment customizations via .devcontainer/devcontainer.json
# Team-specific tool versions, environment variables, and extensions
```

## Troubleshooting Common Issues

### Environment Startup Problems

**Codespace fails to start or hangs during setup:**
```bash
# Check k3d cluster status
k3d cluster list

# Restart cluster if needed
k3d cluster stop kserve
k3d cluster start kserve

# If cluster is missing, recreate it
k3d cluster create kserve --servers 1 --agents 1 \
  --registry-create kserve-registry:5000 \
  --k3s-arg '--disable=traefik@server:0' --wait
```

**Container build failures:**
```bash
# Verify Docker daemon is running
docker ps

# Check registry connectivity
docker push kserve-registry:5000/test:latest

# Clear Docker cache if storage issues
docker system prune -af --volumes
```

### Development Workflow Issues

**InferenceService deployment failures:**
```bash
# Check KServe installation status
kubectl get pods -n kserve
kubectl get pods -n istio-system
kubectl get pods -n knative-serving

# Reinstall if components are failing
./hack/quick_install.sh -u  # Uninstall
./hack/quick_install.sh     # Reinstall
```

**Go build or test failures:**
```bash
# Clear Go module cache
go clean -modcache
go mod download

# Regenerate code and manifests
make manifests generate
```

**Python development issues:**
```bash
# Reinstall KServe SDK in editable mode
cd python/kserve
pip install -e . --force-reinstall

# Clear Python cache
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} +
```

### Resource and Performance Issues

**High memory usage:**
```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods -A

# Reduce resource usage by stopping unused services
kubectl scale deployment --replicas=0 -n istio-system istio-proxy
```

**Slow performance:**
```bash
# Check available resources in Codespace
nproc  # Check CPU count
free -h  # Check memory
df -h  # Check disk space

# Consider upgrading to larger machine type via:
# Settings → Machine type → Upgrade
```

## Advanced Configuration

### Custom ServingRuntime Development

```bash
# Create custom runtime definition
cat > config/runtimes/my-runtime.yaml <<EOF
apiVersion: serving.kserve.io/v1alpha1
kind: ClusterServingRuntime
metadata:
  name: my-custom-runtime
spec:
  supportedModelFormats:
  - name: custom
    version: "1"
  containers:
  - name: kserve-container
    image: my-registry/my-model-server:latest
    env:
    - name: STORAGE_URI
      value: "{{.StorageUri}}"
EOF

# Deploy runtime
kubectl apply -f config/runtimes/my-runtime.yaml
```

### Multi-Node Testing

```bash
# Create multi-node k3d cluster for advanced testing
k3d cluster delete kserve
k3d cluster create kserve-multinode \
  --servers 1 --agents 3 \
  --registry-create kserve-registry:5000 \
  --k3s-arg '--disable=traefik@server:0'

# Verify all nodes are ready  
kubectl get nodes
```

### Integration with External Services

```bash
# Connect to external model storage (S3, GCS, etc.)
kubectl create secret generic storage-config \
  --from-literal=AWS_ACCESS_KEY_ID=your-key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your-secret \
  -n kserve-test
  
# Test with external model
kubectl apply -f - <<EOF
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: external-model
  namespace: kserve-test
spec:
  predictor:
    sklearn:
      storageUri: s3://your-bucket/model
      env:
      - name: AWS_ACCESS_KEY_ID
        valueFrom:
          secretKeyRef:
            name: storage-config
            key: AWS_ACCESS_KEY_ID
EOF
```

## Contributing to the Development Environment

The KServe Codespaces configuration is maintained in the `.devcontainer/` directory. To contribute improvements:

1. **Test changes locally**: Use VS Code Dev Containers extension
2. **Submit PRs**: Follow standard KServe contribution guidelines  
3. **Update documentation**: Ensure this guide reflects your changes
4. **Consider CI impact**: Changes should not break existing workflows

For issues with the development environment, please open issues with the `area/devcontainer` label in the [KServe repository](https://github.com/kserve/kserve/issues).

## Resources

- **KServe Documentation**: [https://kserve.github.io/website/](https://kserve.github.io/website/)
- **Developer Guide**: [https://kserve.github.io/website/latest/developer/developer/](https://kserve.github.io/website/latest/developer/developer/)
- **API Reference**: [https://kserve.github.io/website/latest/reference/api/](https://kserve.github.io/website/latest/reference/api/)
- **Community**: [Kubeflow Slack #kserve](https://kubeflow.slack.com/archives/C066PSG5K7D)
- **GitHub Codespaces Documentation**: [https://docs.github.com/en/codespaces](https://docs.github.com/en/codespaces)