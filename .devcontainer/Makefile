# Makefile for KServe DevContainer operations

.PHONY: help build push run stop clean setup test

# Variables
REGISTRY ?= ghcr.io
REPO ?= kserve
IMAGE_NAME ?= kserve-devcontainer
TAG ?= latest
FULL_IMAGE = $(REGISTRY)/$(REPO)/$(IMAGE_NAME):$(TAG)

help: ## Show this help message
	@echo "KServe DevContainer Makefile"
	@echo "============================"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  REGISTRY=$(REGISTRY)"
	@echo "  REPO=$(REPO)"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)"
	@echo "  TAG=$(TAG)"

build: ## Build the devcontainer image
	@echo "Building devcontainer image..."
	docker build -t $(FULL_IMAGE) \
		--build-arg GO_VERSION=1.24.1 \
		--build-arg PYTHON_VERSION=3.12 \
		--build-arg NODE_VERSION=20 \
		-f Dockerfile ..

build-multiarch: ## Build multi-architecture image
	@echo "Building multi-architecture devcontainer image..."
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		-t $(FULL_IMAGE) \
		--build-arg GO_VERSION=1.24.1 \
		--build-arg PYTHON_VERSION=3.12 \
		--build-arg NODE_VERSION=20 \
		-f Dockerfile ..

push: ## Push the devcontainer image to registry
	@echo "Pushing devcontainer image..."
	docker push $(FULL_IMAGE)

pull: ## Pull the devcontainer image from registry
	@echo "Pulling devcontainer image..."
	docker pull $(FULL_IMAGE)

run: ## Run the devcontainer locally
	@echo "Running devcontainer..."
	docker run -it --rm \
		--privileged \
		-v $(PWD)/..:/workspaces/kserve \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-p 8080:8080 \
		-p 8443:8443 \
		-p 5000:5000 \
		--name kserve-dev \
		$(FULL_IMAGE) \
		/bin/zsh

compose-up: ## Start devcontainer with docker-compose
	@echo "Starting devcontainer with docker-compose..."
	docker-compose up -d

compose-down: ## Stop devcontainer with docker-compose
	@echo "Stopping devcontainer..."
	docker-compose down

compose-logs: ## Show docker-compose logs
	docker-compose logs -f

shell: ## Open shell in running devcontainer
	@echo "Opening shell in devcontainer..."
	docker exec -it kserve-dev /bin/zsh

stop: ## Stop the devcontainer
	@echo "Stopping devcontainer..."
	docker stop kserve-dev || true

clean: ## Clean up docker resources
	@echo "Cleaning up..."
	docker rm -f kserve-dev || true
	docker volume prune -f
	docker image prune -f

setup: ## Run setup script
	@echo "Running setup script..."
	chmod +x setup.sh
	./setup.sh

test-container: ## Test the devcontainer image
	@echo "Testing devcontainer..."
	docker run --rm $(FULL_IMAGE) bash -c "\
		go version && \
		python3 --version && \
		kubectl version --client && \
		docker --version && \
		k3d version && \
		helm version --short && \
		ko version"

prebuild: ## Simulate GitHub Codespaces prebuild
	@echo "Running prebuild..."
	chmod +x scripts/prebuild.sh
	docker run --rm \
		-v $(PWD)/..:/workspaces/kserve \
		$(FULL_IMAGE) \
		/workspaces/kserve/.devcontainer/scripts/prebuild.sh

validate: ## Validate devcontainer.json
	@echo "Validating devcontainer.json..."
	@python3 -m json.tool devcontainer.json > /dev/null && echo "✓ devcontainer.json is valid JSON" || echo "✗ devcontainer.json is invalid"
	@if [ -f ../.github/codespaces/devcontainer.json ]; then \
		python3 -m json.tool ../.github/codespaces/devcontainer.json > /dev/null && echo "✓ codespaces/devcontainer.json is valid JSON" || echo "✗ codespaces/devcontainer.json is invalid"; \
	fi

install-hooks: ## Install git hooks for devcontainer
	@echo "Installing git hooks..."
	@cat > ../.git/hooks/pre-push <<-EOF
	#!/bin/bash
	# Validate devcontainer files before push
	make -C .devcontainer validate
	EOF
	@chmod +x ../.git/hooks/pre-push
	@echo "Git hooks installed"

# Development helpers
dev-go: ## Run Go development environment
	docker run -it --rm \
		-v $(PWD)/..:/workspaces/kserve \
		-w /workspaces/kserve \
		golang:1.24 \
		bash

dev-python: ## Run Python development environment
	docker run -it --rm \
		-v $(PWD)/..:/workspaces/kserve \
		-w /workspaces/kserve/python \
		python:3.12 \
		bash

.DEFAULT_GOAL := help