# The tagging module uses no provider, so these tests apply it for real.

variables {
  component_name = "billing-storage"
  component_type = "application"
  project        = "billing"
  environment    = "development"
  business_unit  = "engineering"
  cost_center    = "application-development"
  application_id = "app-1234"
  owner          = "group:default/platform-team"
}

run "standard_tags" {
  assert {
    condition     = output.tags["Component"] == "billing-storage" && output.tags["CostCenter"] == "application-development" && output.tags["ManagedBy"] == "terraform"
    error_message = "The standard tags must be present."
  }

  assert {
    condition     = output.tags["ApplicationId"] == "app-1234"
    error_message = "The application ID is tagged when given."
  }
}

run "no_application_id" {
  variables {
    application_id = ""
  }

  assert {
    condition     = !contains(keys(output.tags), "ApplicationId")
    error_message = "No ApplicationId tag without an application ID."
  }
}

run "standard_tags_win_over_additional_tags" {
  variables {
    additional_tags = {
      ManagedBy = "hand"
      Team      = "payments"
    }
  }

  assert {
    condition     = output.tags["ManagedBy"] == "terraform" && output.tags["Team"] == "payments"
    error_message = "Additional tags are added but cannot replace standard tags."
  }
}

run "labels_are_valid_for_google_cloud" {
  assert {
    condition     = output.labels["cost-center"] == "application-development" && output.labels["owner"] == "group-default-platform-team"
    error_message = "Labels use lowercase hyphenated keys and sanitised values."
  }

  assert {
    condition     = alltrue([for key, value in output.labels : can(regex("^[a-z0-9_-]{1,63}$", key)) && can(regex("^[a-z0-9_-]{0,63}$", value))])
    error_message = "Every label key and value must be valid for Google Cloud."
  }
}
