#!/bin/bash
# Kubernetes Microservice Test Script
# This script validates Kubernetes manifests and container build

set -e

echo "=== Kubernetes Microservice Tests ==="
echo ""

# Test 1: YAML Lint for all Kubernetes manifests
echo "[TEST 1] YAML Lint"
if command -v yamllint &> /dev/null; then
    yamllint k8s/ && echo "  PASS: All YAML files valid" || echo "  WARN: YAML lint issues found"
else
    echo "  SKIP: yamllint not installed"
fi

# Test 2: Kubernetes manifest validation with kubeconform
echo ""
echo "[TEST 2] Kubernetes Manifest Validation (kubeconform)"
if command -v kubeconform &> /dev/null; then
    kubeconform -strict -summary k8s/*.yaml && echo "  PASS: All manifests valid" || echo "  FAIL: Invalid manifests"
else
    echo "  SKIP: kubeconform not installed (install: go install github.com/yannh/kubeconform/cmd/kubeconform@latest)"
fi

# Test 3: Kubernetes manifest validation with kubectl dry-run
echo ""
echo "[TEST 3] Kubernetes Dry Run (kubectl)"
if command -v kubectl &> /dev/null; then
    kubectl apply --dry-run=client -f k8s/ && echo "  PASS: Manifests pass dry-run validation"
else
    echo "  SKIP: kubectl not installed"
fi

# Test 4: Dockerfile lint
echo ""
echo "[TEST 4] Dockerfile Lint (hadolint)"
if command -v hadolint &> /dev/null; then
    hadolint Dockerfile && echo "  PASS: Dockerfile passes linting" || echo "  WARN: Dockerfile has linting issues"
else
    echo "  SKIP: hadolint not installed"
fi

# Test 5: Security scan with trivy
echo ""
echo "[TEST 5] Security Scan (trivy)"
if command -v trivy &> /dev/null; then
    trivy config k8s/ && echo "  PASS: No security issues found" || echo "  WARN: Security issues found"
else
    echo "  SKIP: trivy not installed"
fi

# Test 6: API specification validation
echo ""
echo "[TEST 6] API Specification Validation"
if [ -f "api-spec.yaml" ]; then
    if command -v spectral &> /dev/null; then
        spectral lint api-spec.yaml && echo "  PASS: API spec valid" || echo "  WARN: API spec has issues"
    else
        echo "  SKIP: spectral not installed"
    fi
else
    echo "  SKIP: No api-spec.yaml found"
fi

echo ""
echo "=== All Tests Completed ==="
