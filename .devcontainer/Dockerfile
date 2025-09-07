# Use Microsoft's universal devcontainer image which includes essential tools
# This image has coreutils and other essential utilities pre-installed
FROM mcr.microsoft.com/devcontainers/universal:2-linux

# Build arguments - Using Go version from go.mod and CI
ARG GO_VERSION=1.24.1
ARG PYTHON_VERSION=3.12
ARG KUBECTL_VERSION=v1.31.0
ARG HELM_VERSION=v3.16.0
ARG KO_VERSION=v0.17.0
ARG KUSTOMIZE_VERSION=v5.5.0
ARG KIND_VERSION=v0.25.0
ARG K3D_VERSION=v5.7.5

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set Go environment variables
ENV GOPATH=/go
ENV PATH=/go/bin:/usr/local/go/bin:${PATH}

# First ensure essential utilities are available for Docker-in-Docker feature
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Essential utilities that Docker-in-Docker needs
        coreutils \
        procps \
        util-linux \
        # Basic tools
        curl wget git vim nano jq unzip \
        # Build tools
        build-essential make gcc g++ pkg-config \
        # Python development
        python3-pip python3-dev python3-venv \
        # Network tools
        net-tools iputils-ping dnsutils netcat-openbsd \
        # Archive tools
        zip tar gzip \
        # SSL/TLS tools
        ca-certificates openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Go - using version matching go.mod and CI
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz && \
    mkdir -p /go/bin /go/pkg /go/src && \
    chmod -R 777 /go

# Install essential Go tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.62.2 && \
    go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.16.2 && \
    go install github.com/google/ko@${KO_VERSION}

# Install Python packages for KServe development
RUN pip3 install --no-cache-dir \
    pytest pytest-asyncio pytest-cov \
    black==24.3.0 flake8==7.1.0 \
    pre-commit \
    uv

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Helm
RUN curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -xz && \
    mv linux-amd64/helm /usr/local/bin/ && \
    rm -rf linux-amd64

# Install Kustomize
RUN curl -LO "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz && \
    mv kustomize /usr/local/bin/ && \
    rm kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz

# Install k3d for lightweight Kubernetes
RUN curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=${K3D_VERSION} bash

# Install kind as an alternative
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64 && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin/kind

# Install k9s for Kubernetes CLI management
RUN curl -Lo k9s.tar.gz https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_Linux_amd64.tar.gz && \
    tar -xzf k9s.tar.gz && \
    mv k9s /usr/local/bin/ && \
    rm -f k9s.tar.gz LICENSE README.md || true

# Create directories for development
RUN mkdir -p /go/src /go/bin /go/pkg /home/codespace/.cache

# Set up the user (codespace for universal image, vscode for others)
ARG USERNAME=codespace
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# The codespace user already exists in the universal image, just ensure sudo access
RUN if ! id -u $USERNAME > /dev/null 2>&1; then \
        (groupadd --gid $USER_GID $USERNAME || true) && \
        (useradd --uid $USER_UID --gid $USER_GID -m $USERNAME || true); \
    fi && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Give vscode user access to Go directories (only if user exists)
RUN if id -u $USERNAME > /dev/null 2>&1; then \
        chown -R $USERNAME:$USERNAME /go || true; \
    fi

# Switch to vscode user
USER $USERNAME

# Set up user environment
ENV GOPATH=/home/codespace/go
ENV PATH=$PATH:/home/codespace/go/bin:/home/codespace/.local/bin

WORKDIR /workspaces/kserve

# Default command
CMD ["/bin/bash"]