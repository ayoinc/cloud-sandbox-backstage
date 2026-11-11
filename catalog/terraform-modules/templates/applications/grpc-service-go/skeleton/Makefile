SERVICE := ${{ values.serviceName }}
MODULE := ${{ values.modulePath }}
VERSION ?= ${{ values.serviceVersion }}
IMAGE ?= $(SERVICE):$(VERSION)

BUF ?= buf
GOLANGCI_LINT ?= golangci-lint
KUBECONFORM ?= go run github.com/yannh/kubeconform/cmd/kubeconform@v0.8.0
# JSON schemas of custom resources such as Istio's, which the Kubernetes
# schemas do not cover.
CRD_SCHEMAS := https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json

.DEFAULT_GOAL := help

.PHONY: help
help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "%-12s %s\n", $$1, $$2}'

.PHONY: generate
generate: ## Generate the Go code of the proto files into gen/
	$(BUF) generate

.PHONY: lint
lint: generate ## Lint the proto files and the Go code
	$(BUF) lint
	$(BUF) format --diff --exit-code
	$(GOLANGCI_LINT) run

.PHONY: test
test: generate ## Run the tests with the race detector
	go test -race -cover ./...

.PHONY: build
build: generate ## Build the server into bin/server
	go build -trimpath -ldflags "-X $(MODULE)/internal/version.Version=$(VERSION)" -o bin/server ./cmd/server

.PHONY: run
run: generate ## Run the server on :50051
	go run ./cmd/server
{% if values.enableAuth %}

.PHONY: certs
certs: ## Write development certificates to certs/
	bash scripts/gen-certs.sh certs

.PHONY: run-tls
run-tls: generate certs ## Run the server with the development certificates
	TLS_CERT_FILE=certs/server.crt TLS_KEY_FILE=certs/server.key${{ ' TLS_CLIENT_CA_FILE=certs/ca.crt' if values.enableMTLS }} go run ./cmd/server
{% endif %}

.PHONY: image
image: ## Build the container image
	docker build --build-arg VERSION=$(VERSION) --tag $(IMAGE) .

.PHONY: smoke
smoke: image ## Start the image and call it over gRPC
	bash scripts/smoke-test.sh $(IMAGE)

.PHONY: manifests
manifests: ## Validate the Kubernetes manifests
	kubectl kustomize deploy/k8s | $(KUBECONFORM) -strict -summary -schema-location default -schema-location '$(CRD_SCHEMAS)'
