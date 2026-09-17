# Example usage of the Azure Cleanup module
# This example demonstrates how to use the enhanced cleanup capabilities

provider "azurerm" {
  features {}
}

provider "azuread" {
}

module "azure_cleanup" {
  source = "../../modules/azure-cleanup"

  # Basic cleanup options
  scan_resources        = true
  plan_cleanup          = true
  execute_cleanup       = false # Set to true when ready to execute
  confirm_each_deletion = true  # Interactive mode

  # Resource groups to exclude from cleanup
  exclude_resource_groups = [
    "NetworkWatcherRG",
    "cloud-shell-storage-westeurope",
    "monitoring-resource-group-west-us"
  ]

  # Advanced cleanup options

  # Option 1: Target specific resource groups for cleanup
  target_resource_groups = [
    "web-resource-group",
    "WEB-RESOURCE-GROUP",
    "foodshare-resource-group"
  ]

  # Option 2: Target a specific vault for cleanup
  target_vault_name           = "vault473"
  target_vault_resource_group = "web-resource-group"

  # Option 3: Aggressive cleanup (force deletion)
  aggressive_cleanup = true

  # Option 4: Cancel pending operations
  cancel_operations = true
}

# Output the cleanup documentation
output "azure_cleanup_docs" {
  value = "Review the cleanup documentation in ./.azure-cleanup/README.md"
} 