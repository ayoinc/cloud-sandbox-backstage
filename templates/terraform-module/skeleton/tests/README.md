# Terraform Tests

This directory contains tests for the Terraform module.

## Directory Structure

```
tests/
├── unit/                    # Unit tests (no real resources)
│   └── module.tftest.hcl    # Module validation tests
└── integration/             # Integration tests (creates real resources)
    └── full_stack.tftest.hcl # Full stack deployment tests
```

## Running Tests

### Unit Tests

Unit tests validate the module configuration without creating real resources:

```bash
terraform init
terraform test -filter=tests/unit/
```

### Integration Tests

Integration tests create real infrastructure to validate the module works correctly.

**WARNING:** Integration tests will incur cloud costs. Make sure you have appropriate credentials configured.

```bash
terraform init
terraform test -filter=tests/integration/
```

### Running All Tests

```bash
terraform init
terraform test
```

## Test Coverage

### Unit Tests

- `validate_variables` - Ensures variables have valid defaults
- `validate_environment_values` - Tests environment variable validation
- `validate_feature_flags` - Tests feature flag default values

### Integration Tests

- `integration_network` - Tests network module creates expected resources
- `integration_full_stack` - Tests full stack deployment

## Writing New Tests

1. Create a new `.tftest.hcl` file in the appropriate directory
2. Use `command = plan` for tests that don't need to create resources
3. Use `command = apply` for tests that need to create and validate real resources
4. Use `assert` blocks to validate expected conditions

Example:

```hcl
run "my_test" {
  command = plan

  variables {
    environment = "test"
  }

  assert {
    condition     = var.environment == "test"
    error_message = "Environment should be 'test'"
  }
}
```
