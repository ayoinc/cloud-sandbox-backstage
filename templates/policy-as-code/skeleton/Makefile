# The targets the pipeline runs; they need opa, conftest, jq, tflint and checkov.
CHECKOV_CHECKS := CKV2_CUSTOM_1,CKV2_CUSTOM_2
TFLINT_CONFIG  := $(CURDIR)/tflint/.tflint.hcl

.PHONY: all fmt fmt-check check test plans checkov tflint

all: fmt-check check test plans checkov tflint

fmt: ## Format the policies
	opa fmt --write policy

fmt-check: ## Fail if a policy is not formatted
	opa fmt --fail --list policy

check: ## Type-check the policies in strict mode
	opa check --strict policy

test: ## Unit tests of the policies
	conftest verify --policy policy --no-color

plans: ## The policies against the fixture plans
	bash tests/plans.sh

checkov: ## The custom Checkov checks against the fixture configurations
	checkov --directory tests/fixtures/terraform/compliant --config-file checkov/config.yaml \
		--external-checks-dir checkov/policies --check $(CHECKOV_CHECKS)
	@if checkov --directory tests/fixtures/terraform/violating --config-file checkov/config.yaml \
		--external-checks-dir checkov/policies --check $(CHECKOV_CHECKS) > /dev/null; then \
		echo "The custom checks should fail on tests/fixtures/terraform/violating" >&2; exit 1; \
	fi
	@echo "violating: failed the custom checks as expected"

tflint: ## The shared TFLint configuration against the fixture configurations
	tflint --chdir tests/fixtures/terraform/compliant --config $(TFLINT_CONFIG)
	@if tflint --chdir tests/fixtures/terraform/violating --config $(TFLINT_CONFIG) > /dev/null; then \
		echo "TFLint should fail on tests/fixtures/terraform/violating" >&2; exit 1; \
	fi
	@echo "violating: failed TFLint as expected"
