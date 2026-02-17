.PHONY: help lint test test-unit test-golden test-policy test-integration test-all clean

CHART_DIR := helm/disentangle
NAMESPACE := disentangle-test
RELEASE := test-release

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# === Linting ===

lint: lint-helm lint-yaml lint-shell ## Run all linters

lint-helm: ## Lint Helm chart
	helm lint $(CHART_DIR)

lint-yaml: ## Lint YAML files (excluding Helm templates)
	@command -v yamllint >/dev/null 2>&1 || { echo "Install yamllint: pip install yamllint"; exit 1; }
	yamllint -d relaxed gitops/ $(CHART_DIR)/Chart.yaml $(CHART_DIR)/values.yaml

lint-shell: ## Lint shell scripts
	@command -v shellcheck >/dev/null 2>&1 || { echo "Install shellcheck: brew install shellcheck"; exit 1; }
	shellcheck tests/**/*.sh 2>/dev/null || true  # advisory — does not block CI

# === Template Validation ===

template: ## Render Helm templates (default values)
	helm template test $(CHART_DIR)

template-validate: ## Render and validate with kubeconform
	@command -v kubeconform >/dev/null 2>&1 || { echo "Install kubeconform"; exit 1; }
	helm template test $(CHART_DIR) | kubeconform -strict -summary -ignore-missing-schemas

# === Testing ===

test: test-unit test-golden test-policy ## Run all offline tests

test-unit: ## Run helm-unittest tests
	@helm plugin list 2>/dev/null | grep -q unittest || helm plugin install https://github.com/helm-unittest/helm-unittest
	helm unittest $(CHART_DIR)

test-golden: ## Run golden file regression tests
	./tests/golden/verify.sh

test-golden-update: ## Update golden files (after intentional template changes)
	./tests/golden/update.sh

test-policy: ## Run OPA Conftest policy tests
	@command -v conftest >/dev/null 2>&1 || { echo "Install conftest: brew install conftest"; exit 1; }
	./tests/policies/run-conftest.sh

test-integration: ## Run full integration test (requires K8s cluster)
	./tests/helm-integration.sh

test-helm: ## Run helm test hooks (requires deployed release)
	helm test $(RELEASE) -n $(NAMESPACE) --timeout=120s

test-all: lint test test-integration ## Run everything

# === Kustomize ===

kustomize-build: ## Build all kustomize overlays
	@for overlay in gitops/overlays/*/; do \
		echo "=== Building $$overlay ==="; \
		kubectl kustomize "$$overlay" > /dev/null && echo "OK" || echo "FAIL"; \
	done

# === Scoring (informational) ===

score: ## Score manifests with kube-score (informational)
	@command -v kube-score >/dev/null 2>&1 || { echo "Install kube-score"; exit 1; }
	helm template score $(CHART_DIR) | kube-score score - || true  # informational — failures don't block

kube-lint: ## Lint manifests with kube-linter
	@command -v kube-linter >/dev/null 2>&1 || { echo "Install kube-linter"; exit 1; }
	helm template lint $(CHART_DIR) | kube-linter lint -

# === Development ===

install-dev: ## Install chart in dev mode (3 nodes, low difficulty)
	helm install $(RELEASE) $(CHART_DIR) \
		--namespace $(NAMESPACE) --create-namespace \
		--set nodes.count=3 \
		--set pow.difficulty=8 \
		--set pow.mineIntervalSecs=5 \
		--set persistence.enabled=false \
		--wait --timeout=300s

uninstall: ## Uninstall chart
	helm uninstall $(RELEASE) -n $(NAMESPACE) 2>/dev/null || true
	kubectl delete namespace $(NAMESPACE) --wait=false 2>/dev/null || true

port-forward: ## Port-forward RPC service to localhost:8000
	kubectl port-forward svc/$(RELEASE)-disentangle-rpc 8000:8000 -n $(NAMESPACE)

status: ## Show cluster status
	@echo "=== Pods ==="
	@kubectl get pods -n $(NAMESPACE) -o wide 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Services ==="
	@kubectl get svc -n $(NAMESPACE) 2>/dev/null || echo "Namespace not found"

# === Pre-commit ===

pre-commit-install: ## Install pre-commit hooks
	@command -v pre-commit >/dev/null 2>&1 || { echo "Install pre-commit: pip install pre-commit"; exit 1; }
	pre-commit install

pre-commit-run: ## Run pre-commit on all files
	pre-commit run --all-files

# === Cleanup ===

clean: uninstall ## Clean up everything
	@echo "Cleanup complete"
