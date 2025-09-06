#!/bin/bash
# Validation script for KServe devcontainer setup

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════════════"
echo "         KServe DevContainer Validation Script"
echo "════════════════════════════════════════════════════════════════"
echo ""

ERRORS=0
WARNINGS=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# Check Go installation
echo "Checking Go environment..."
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    check_pass "Go installed: version $GO_VERSION"
    
    if [ -n "$GOPATH" ]; then
        check_pass "GOPATH set: $GOPATH"
    else
        check_fail "GOPATH not set"
    fi
else
    check_fail "Go not installed"
fi

# Check Python installation
echo ""
echo "Checking Python environment..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    check_pass "Python installed: version $PYTHON_VERSION"
    
    # Check for kserve package
    if python3 -c "import kserve" 2>/dev/null; then
        check_pass "KServe Python SDK installed"
    else
        check_warn "KServe Python SDK not installed"
    fi
else
    check_fail "Python not installed"
fi

# Check Docker
echo ""
echo "Checking Docker..."
if docker info &> /dev/null; then
    check_pass "Docker daemon is running"
    
    if docker images | grep -q "registry:2"; then
        check_pass "Local Docker registry available"
    else
        check_warn "Local Docker registry not running"
    fi
else
    check_fail "Docker daemon not running"
fi

# Check Kubernetes tools
echo ""
echo "Checking Kubernetes tools..."
for tool in kubectl helm kustomize k3d kind ko; do
    if command -v $tool &> /dev/null; then
        check_pass "$tool installed"
    else
        check_fail "$tool not installed"
    fi
done

# Check Kubernetes cluster
echo ""
echo "Checking Kubernetes cluster..."
if kubectl cluster-info &> /dev/null; then
    check_pass "Kubernetes cluster is running"
    
    NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$NODES" -gt 0 ]; then
        check_pass "Cluster has $NODES node(s)"
    else
        check_fail "No nodes found in cluster"
    fi
else
    check_warn "Kubernetes cluster not running"
fi

# Check KServe installation
echo ""
echo "Checking KServe installation..."
if kubectl get ns kserve &> /dev/null; then
    check_pass "KServe namespace exists"
    
    if kubectl get deployment -n kserve kserve-controller-manager &> /dev/null; then
        check_pass "KServe controller is deployed"
        
        READY=$(kubectl get deployment -n kserve kserve-controller-manager -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        if [ "$READY" -gt 0 ]; then
            check_pass "KServe controller is running ($READY replica(s))"
        else
            check_warn "KServe controller not ready"
        fi
    else
        check_warn "KServe controller not deployed"
    fi
else
    check_warn "KServe not installed"
fi

# Check cert-manager
echo ""
echo "Checking cert-manager..."
if kubectl get ns cert-manager &> /dev/null; then
    if kubectl get deployment -n cert-manager cert-manager &> /dev/null; then
        check_pass "cert-manager installed"
    else
        check_warn "cert-manager namespace exists but not deployed"
    fi
else
    check_warn "cert-manager not installed"
fi

# Check development tools
echo ""
echo "Checking development tools..."
for tool in golangci-lint controller-gen pre-commit black flake8; do
    if command -v $tool &> /dev/null; then
        check_pass "$tool installed"
    else
        check_warn "$tool not installed"
    fi
done

# Check environment variables
echo ""
echo "Checking environment variables..."
if [ -n "$KO_DOCKER_REPO" ]; then
    check_pass "KO_DOCKER_REPO set: $KO_DOCKER_REPO"
else
    check_warn "KO_DOCKER_REPO not set"
fi

if [ -n "$KSERVE_NAMESPACE" ]; then
    check_pass "KSERVE_NAMESPACE set: $KSERVE_NAMESPACE"
else
    check_warn "KSERVE_NAMESPACE not set"
fi

# Check Git configuration
echo ""
echo "Checking Git configuration..."
if git config user.name &> /dev/null; then
    USER_NAME=$(git config user.name)
    check_pass "Git user.name configured: $USER_NAME"
else
    check_warn "Git user.name not configured"
fi

if git config user.email &> /dev/null; then
    USER_EMAIL=$(git config user.email)
    check_pass "Git user.email configured: $USER_EMAIL"
else
    check_warn "Git user.email not configured"
fi

# Check pre-commit hooks
echo ""
echo "Checking pre-commit hooks..."
if [ -f ".git/hooks/pre-commit" ]; then
    check_pass "Pre-commit hooks installed"
else
    check_warn "Pre-commit hooks not installed"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                         SUMMARY"
echo "════════════════════════════════════════════════════════════════"

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}All checks passed! Your development environment is ready.${NC}"
    else
        echo -e "${GREEN}Environment is functional with $WARNINGS warning(s).${NC}"
        echo "Run '.devcontainer/setup.sh' to fix warnings."
    fi
else
    echo -e "${RED}Found $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo "Please run '.devcontainer/setup.sh' to complete setup."
fi

echo ""
echo "For detailed setup instructions, see: .devcontainer/DEVCONTAINER_GUIDE.md"
echo ""

exit $ERRORS