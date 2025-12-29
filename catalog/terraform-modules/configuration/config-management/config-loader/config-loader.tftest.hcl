# Config Loader Module Test Suite
# Tests YAML configuration loading, merging, validation, and environment-specific configs

# Test 1: Load complete configuration file
run "test_load_complete_config" {
  command = plan

  variables {
    config_paths = ["./test-fixtures/complete-config.yaml"]
    environment  = "dev"
  }

  module {
    source = "./"
  }

  assert {
    condition     = output.is_valid == true
    error_message = "Complete configuration should be valid"
  }

  assert {
    condition     = output.config["app_name"] == "myapp"
    error_message = "Should load app_name from complete config"
  }

  assert {
    condition     = contains(output.all_keys, "app_name")
    error_message = "Should include app_name key in all_keys"
  }
}

# Test 2: Environment-specific configuration
run "test_environment_config" {
  command = plan

  variables {
    config_paths = ["./test-fixtures/env-config.yaml"]
    environment  = "prod"
  }

  module {
    source = "./"
  }

  assert {
    condition     = output.is_valid == true
    error_message = "Environment config should be valid"
  }

  assert {
    condition     = output.config["environment_name"] == "production"
    error_message = "Should load production environment config"
  }

  assert {
    condition     = output.config["logging_level"] == "error"
    error_message = "Should use production logging level"
  }
}

# Test 3: Configuration merging with overrides
run "test_config_merge" {
  command = plan

  variables {
    config_paths = [
      "./test-fixtures/base-config.yaml",
      "./test-fixtures/override-config.yaml"
    ]
    environment = "dev"
  }

  module {
    source = "./"
  }

  assert {
    condition     = output.is_valid == true
    error_message = "Merged configuration should be valid"
  }

  assert {
    condition     = output.config["app_name"] == "override-app"
    error_message = "Override config should take precedence"
  }

  assert {
    condition     = output.config["cache_enabled"] == "true"
    error_message = "Should add new keys from override config"
  }

  assert {
    condition     = output.config["api_port"] == "8080"
    error_message = "Should use override value for api_port"
  }

  assert {
    condition     = output.config["max_connections"] == "50"
    error_message = "Should add new key max_connections from override"
  }
}

# Test 4: Required keys validation
run "test_required_keys" {
  command = plan

  variables {
    config_paths  = ["./test-fixtures/partial-config.yaml"]
    environment   = "dev"
    required_keys = ["app_name", "database_host", "api_key"]
  }

  module {
    source = "./"
  }

  assert {
    condition     = output.is_valid == false
    error_message = "Configuration with missing required keys should be invalid"
  }

  assert {
    condition     = contains(output.missing_keys, "api_key")
    error_message = "Should identify missing api_key in missing_keys"
  }

  assert {
    condition     = length(output.validation_errors) > 0
    error_message = "Should generate validation errors for missing keys"
  }

  assert {
    condition     = length(output.config) == 0
    error_message = "Config should be empty when validation fails"
  }
}

# Test 5: Nested configuration values
run "test_nested_config" {
  command = plan

  variables {
    config_paths = ["./test-fixtures/nested-config.yaml"]
    environment  = "dev"
  }

  module {
    source = "./"
  }

  assert {
    condition     = output.is_valid == true
    error_message = "Nested configuration should be valid"
  }

  assert {
    condition     = can(output.config["database"])
    error_message = "Should have database key with nested values"
  }

  assert {
    condition     = output.config["database"]["host"] == "localhost"
    error_message = "Should access nested database host value"
  }

  assert {
    condition     = output.config["database"]["port"] == 5432
    error_message = "Should access nested database port value"
  }

  assert {
    condition     = contains(output.all_keys, "database")
    error_message = "Should include database in all_keys"
  }
}

# Test 6: Empty configuration handling
run "test_empty_config" {
  command = plan

  variables {
    config_paths = ["./test-fixtures/empty-config.yaml"]
    environment  = "dev"
  }

  module {
    source = "./"
  }

  assert {
    condition     = output.is_valid == true
    error_message = "Empty configuration should be valid (no required keys)"
  }

  assert {
    condition     = length(output.config) == 0
    error_message = "Empty config should result in empty config output"
  }

  assert {
    condition     = length(output.all_keys) == 0
    error_message = "Empty config should have no keys in all_keys"
  }
}

# Test 7: Environment wildcard configuration
run "test_wildcard_environment" {
  command = plan

  variables {
    config_paths = ["./test-fixtures/override-env-config.yaml"]
    environment  = "prod"
  }

  module {
    source = "./"
  }

  assert {
    condition     = output.is_valid == true
    error_message = "Wildcard environment config should be valid"
  }

  assert {
    condition     = output.config["api_port"] == "8080"
    error_message = "Should apply wildcard environment settings (api_port)"
  }

  assert {
    condition     = output.config["database_host"] == "prod-db.example.com"
    error_message = "Should load specific environment override for prod"
  }

  assert {
    condition     = output.config["logging_level"] == "error"
    error_message = "Should load prod-specific logging level"
  }
}
