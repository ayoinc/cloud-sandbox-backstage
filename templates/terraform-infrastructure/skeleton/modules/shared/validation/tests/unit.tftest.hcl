# Unit tests for validation module
# Uses mock_provider - no credentials needed

variables {
  validations = {
    project = {
      value       = "myproject"
      required    = true
      pattern     = "^[a-z][a-z0-9-]*$"
      min_length  = 3
      max_length  = 20
    }
    environment = {
      value        = "dev"
      required     = true
      allowed_values = ["dev", "staging", "prod", "test"]
    }
    region = {
      value       = "us-east-1"
      required    = false
      pattern     = "^[a-z]+-[a-z]+-[0-9]+$"
    }
  }
}

run "valid_inputs_pass" {
  command = plan
  
  assert {
    condition     = output.is_valid == true
    error_message = "Valid inputs should pass validation"
  }
  
  assert {
    condition     = length(output.errors) == 0
    error_message = "No errors should be present for valid inputs"
  }
}

run "required_variable_missing" {
  command = plan
  
  variables {
    validations = {
      project = {
        value       = ""
        required    = true
      }
    }
  }
  
  assert {
    condition     = output.is_valid == false
    error_message = "Missing required variable should fail validation"
  }
  
  assert {
    condition     = length(output.errors) > 0
    error_message = "Error should be reported for missing required variable"
  }
}

run "pattern_validation_fails" {
  command = plan
  
  variables {
    validations = {
      project = {
        value       = "Invalid Project"
        required    = true
        pattern     = "^[a-z][a-z0-9-]*$"
      }
    }
  }
  
  assert {
    condition     = output.is_valid == false
    error_message = "Invalid pattern should fail validation"
  }
}

run "allowed_values_validation" {
  command = plan
  
  variables {
    validations = {
      environment = {
        value        = "invalid"
        required     = true
        allowed_values = ["dev", "staging", "prod", "test"]
      }
    }
  }
  
  assert {
    condition     = output.is_valid == false
    error_message = "Value not in allowed list should fail validation"
  }
}

run "length_validation" {
  command = plan
  
  variables {
    validations = {
      short_value = {
        value       = "ab"
        required    = true
        min_length  = 3
      }
      long_value = {
        value       = "this-is-a-very-long-value-that-exceeds-the-maximum-length-allowed"
        required    = true
        max_length  = 20
      }
    }
  }
  
  assert {
    condition     = output.is_valid == false
    error_message = "Length validation should fail for invalid lengths"
  }
}