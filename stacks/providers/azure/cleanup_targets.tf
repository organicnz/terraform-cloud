# Resource Group Cleanup Configuration
# This file defines the resource groups that are targeted for cleanup

locals {
  # List of resource groups that are targets for deletion
  target_resource_groups = [
    # Original targets
    "vpswest-resource-group",
    "newvps-resource-group",
    "vpngermany-resource-group",
    "THE_LATEST_RESOURCE_GROUP",
    "vpsgermany-rg",
    "azure-rg",

    # Additional resource groups for complete cleanup
    "foodshare-resource-group",
    "FOODSHARE-RESOURCE-GROUP",
    "web-resource-group",
    "WEB-RESOURCE-GROUP",
    "monitoring-resource-group-west-us",
    "monitoring_resource_group",
    "monitoring_resource_group-westus",
    "ResourceMoverRG-uksouth-westus-eus2",
    "azureapp-auto-alerts-432dd4-tamerlanium_gmail_com",
    "azureapp-auto-alerts-a866fe-tamerlanium_gmail_com",
    "DefaultResourceGroup-EUS"
  ]

  # Resource groups to exclude from deletion (critical infrastructure)
  exclude_resource_groups = [
    "NetworkWatcherRG",
    "cloud-shell-storage-*",
    "AzureBackupRG_*",
    "DefaultResourceGroup-*"
  ]
}

# The Terraform destroy operation for resource groups
# Activate this only when you need to delete resources
# by setting destroy_infrastructure = true in terraform.tfvars
resource "null_resource" "destroy_resource_groups" {
  count = var.destroy_infrastructure ? length(local.target_resource_groups) : 0

  # This ensures the resource is always recreated when activated
  triggers = {
    resource_group_name = local.target_resource_groups[count.index]
    timestamp           = timestamp()
  }

  # Azure CLI command to delete the resource group
  provisioner "local-exec" {
    command = <<-EOT
      echo "Destroying resource group: ${local.target_resource_groups[count.index]}"
      az group delete --name "${local.target_resource_groups[count.index]}" --yes
    EOT
  }
} 