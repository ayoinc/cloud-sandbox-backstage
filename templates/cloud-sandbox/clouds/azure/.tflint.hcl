config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# The pipeline must be able to destroy what it created, and `prevent_destroy`
# cannot be made conditional; data is protected by purge protection, soft
# delete and versioning instead.
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
