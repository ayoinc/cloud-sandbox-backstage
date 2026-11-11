# The naming module uses no provider, so these tests apply it for real.

variables {
  convention     = "enterprise"
  company        = "Example Org"
  team           = "platform"
  project        = "billing"
  environment    = "dev"
  unique_suffix  = "ab12cd34"
  resource_types = ["st", "vnet"]
}

run "enterprise_convention" {
  assert {
    condition     = output.standard["st"] == "example-org-billing-dev-st-001"
    error_message = "Enterprise names are company-project-env-type-instance."
  }

  assert {
    condition     = output.global["st"] == "example-org-billing-dev-st-001-ab12cd34"
    error_message = "Global names end with the unique suffix."
  }
}

run "team_convention" {
  variables {
    convention = "team"
  }

  assert {
    condition     = output.standard["vnet"] == "platform-billing-vnet-dev-001"
    error_message = "Team names are team-project-type-env-instance."
  }
}

run "project_convention" {
  variables {
    convention = "project"
  }

  assert {
    condition     = output.standard["st"] == "billing-st-dev-001"
    error_message = "Project names are project-type-env-instance."
  }

  assert {
    condition     = output.short["st"] == "billing-st-dev-001"
    error_message = "A name within the limit is not shortened."
  }

  assert {
    condition     = output.global_compact["st"] == "billingstdev001ab12cd34"
    error_message = "Compact names drop the hyphens."
  }
}

run "long_names_stay_within_limits" {
  variables {
    company = "a-very-long-company-name-that-goes-on"
    project = "an-equally-long-project-name-for-testing"
  }

  assert {
    condition     = alltrue([for name in values(output.standard) : length(name) <= 63])
    error_message = "Standard names must not exceed 63 characters."
  }

  assert {
    condition     = alltrue([for name in values(output.short) : length(name) <= 24 && !endswith(name, "-") && !strcontains(name, "--")])
    error_message = "Short names must not exceed 24 characters or contain empty segments."
  }

  assert {
    condition     = alltrue([for name in values(output.global) : length(name) <= 63 && endswith(name, "-ab12cd34")])
    error_message = "Global names must not exceed 63 characters and must keep the unique suffix."
  }

  assert {
    condition     = alltrue([for name in values(output.global_short) : length(name) <= 30 && endswith(name, "-ab12cd34") && !strcontains(name, "--")])
    error_message = "Short global names must not exceed 30 characters and must keep the unique suffix."
  }

  assert {
    condition     = alltrue([for name in values(output.global_compact) : length(name) <= 24 && can(regex("^[a-z0-9]+$", name))])
    error_message = "Compact names must be at most 24 lowercase letters and digits."
  }

  assert {
    condition     = output.short["st"] != output.short["vnet"]
    error_message = "Shortened names of different resource types must differ."
  }
}

run "rejects_unknown_convention" {
  command = plan

  variables {
    convention = "random"
  }

  expect_failures = [var.convention]
}
