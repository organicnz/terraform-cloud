# Azure Resource Cleanup Module
# This module discovers, plans, and selectively deletes Azure resources

# Resource to scan all Azure resources
resource "null_resource" "resource_discovery" {
  count = var.scan_resources ? 1 : 0

  triggers = {
    scan_trigger = var.scan_resources ? timestamp() : ""
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Scanning Azure resources..."
      mkdir -p ./.azure-cleanup
      
      # Get all resource groups
      echo "Discovering resource groups..."
      az group list --query "[].{Name:name, Location:location, Status:properties.provisioningState}" -o json > ./.azure-cleanup/resource_groups.json
      
      # Get all resources
      echo "Discovering all resources..."
      az resource list --query "[].{Name:name, ResourceGroup:resourceGroup, Type:type, Location:location}" -o json > ./.azure-cleanup/resources.json
      
      # Get all VMs
      echo "Discovering virtual machines..."
      az vm list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, PowerState:powerState}" -o json > ./.azure-cleanup/vms.json
      
      # Get all recovery services vaults
      echo "Discovering recovery services vaults..."
      az resource list --resource-type Microsoft.RecoveryServices/vaults --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o json > ./.azure-cleanup/vaults.json
      
      # Get all resource locks
      echo "Discovering resource locks..."
      az lock list --query "[].{Name:name, ResourceGroup:resourceGroup, Level:level, Notes:notes}" -o json > ./.azure-cleanup/locks.json
      
      echo "Resource discovery completed. Results stored in ./.azure-cleanup/"
      echo "To review discovered resources, examine the JSON files in ./.azure-cleanup/"
    EOT
  }
}

# Resource to generate cleanup plan
resource "null_resource" "generate_cleanup_plan" {
  count = var.plan_cleanup ? 1 : 0

  # Ensure discovery runs first
  depends_on = [null_resource.resource_discovery]

  triggers = {
    plan_trigger = var.plan_cleanup ? timestamp() : ""
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Generating cleanup plan..."
      mkdir -p ./.azure-cleanup
      
      # Create plan file
      echo "# Azure Resources Cleanup Plan" > ./.azure-cleanup/cleanup_plan.md
      echo "Generated at: $(date)" >> ./.azure-cleanup/cleanup_plan.md
      echo "" >> ./.azure-cleanup/cleanup_plan.md
      
      # Add excluded resource groups
      echo "## Excluded Resource Groups" >> ./.azure-cleanup/cleanup_plan.md
      echo "The following resource groups will NOT be deleted:" >> ./.azure-cleanup/cleanup_plan.md
      echo "" >> ./.azure-cleanup/cleanup_plan.md
      
      for RG in $${join(" ", var.exclude_resource_groups)}; do
        echo "- $RG" >> ./.azure-cleanup/cleanup_plan.md
      done
      echo "" >> ./.azure-cleanup/cleanup_plan.md
      
      # Generate list of resource groups to delete
      echo "## Resource Groups to Delete" >> ./.azure-cleanup/cleanup_plan.md
      echo "The following resource groups will be deleted:" >> ./.azure-cleanup/cleanup_plan.md
      echo "" >> ./.azure-cleanup/cleanup_plan.md
      
      # Parse the JSON for resource groups and exclude the ones in var.exclude_resource_groups
      # Store target groups in a file for the execution phase
      rm -f ./.azure-cleanup/target_resource_groups.txt
      touch ./.azure-cleanup/target_resource_groups.txt
      
      cat ./.azure-cleanup/resource_groups.json | jq -r '.[] | .Name' | while read RG; do
        IS_EXCLUDED=false
        for EXCLUDED in $${join(" ", var.exclude_resource_groups)}; do
          if [ "$RG" == "$EXCLUDED" ]; then
            IS_EXCLUDED=true
            break
          fi
        done
        
        if [ "$IS_EXCLUDED" == "false" ]; then
          echo "- $RG" >> ./.azure-cleanup/cleanup_plan.md
          echo "$RG" >> ./.azure-cleanup/target_resource_groups.txt
        fi
      done
      echo "" >> ./.azure-cleanup/cleanup_plan.md
      
      # Add special resources section
      echo "## Special Resources Requiring Additional Handling" >> ./.azure-cleanup/cleanup_plan.md
      echo "The following resources require special handling during deletion:" >> ./.azure-cleanup/cleanup_plan.md
      echo "" >> ./.azure-cleanup/cleanup_plan.md
      
      # Recovery Services Vaults
      echo "### Recovery Services Vaults" >> ./.azure-cleanup/cleanup_plan.md
      if [ -s ./.azure-cleanup/vaults.json ] && [ "$(cat ./.azure-cleanup/vaults.json)" != "[]" ]; then
        cat ./.azure-cleanup/vaults.json | jq -r '.[] | "- " + .Name + " (Resource Group: " + .ResourceGroup + ")"' >> ./.azure-cleanup/cleanup_plan.md
      else
        echo "- None found" >> ./.azure-cleanup/cleanup_plan.md
      fi
      echo "" >> ./.azure-cleanup/cleanup_plan.md
      
      # Resource Locks
      echo "### Resource Locks" >> ./.azure-cleanup/cleanup_plan.md
      if [ -s ./.azure-cleanup/locks.json ] && [ "$(cat ./.azure-cleanup/locks.json)" != "[]" ]; then
        cat ./.azure-cleanup/locks.json | jq -r '.[] | "- " + .Name + " (Resource Group: " + (.ResourceGroup // "unknown") + ", Level: " + .Level + ")"' >> ./.azure-cleanup/cleanup_plan.md
      else
        echo "- None found" >> ./.azure-cleanup/cleanup_plan.md
      fi
      echo "" >> ./.azure-cleanup/cleanup_plan.md
      
      # Generate integrated cleanup script directly from terraform
      echo "#!/bin/bash" > ./.azure-cleanup/execute_cleanup.sh
      echo "# Azure Resource Cleanup Script" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Generated by Terraform Azure Cleanup Module" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Create logs directory" >> ./.azure-cleanup/execute_cleanup.sh
      echo "mkdir -p ./logs" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Log file" >> ./.azure-cleanup/execute_cleanup.sh
      echo "LOG_FILE=\"./logs/azure_cleanup_\$(date +%Y%m%d_%H%M%S).log\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Color codes for readability" >> ./.azure-cleanup/execute_cleanup.sh
      echo "GREEN='\033[0;32m'" >> ./.azure-cleanup/execute_cleanup.sh
      echo "YELLOW='\033[1;33m'" >> ./.azure-cleanup/execute_cleanup.sh
      echo "RED='\033[0;31m'" >> ./.azure-cleanup/execute_cleanup.sh
      echo "BLUE='\033[0;34m'" >> ./.azure-cleanup/execute_cleanup.sh
      echo "NC='\033[0m'" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Function to log messages" >> ./.azure-cleanup/execute_cleanup.sh
      echo "log() {" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  echo -e \"\$${BLUE}\$(date '+%Y-%m-%d %H:%M:%S')\$${NC} - \$1\" | tee -a \"\$LOG_FILE\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "}" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Parse arguments" >> ./.azure-cleanup/execute_cleanup.sh
      echo "AUTO_MODE=false" >> ./.azure-cleanup/execute_cleanup.sh
      echo "if [ \"\$1\" == \"--auto\" ]; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  AUTO_MODE=true" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  log \"Running in automatic mode - no confirmation prompts will be shown\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  log \"Running in interactive mode - confirmation will be required for each action\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Main cleanup logic" >> ./.azure-cleanup/execute_cleanup.sh
      echo "log \"Starting Azure resource cleanup...\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Load target resource groups" >> ./.azure-cleanup/execute_cleanup.sh
      echo "if [ -f \"./.azure-cleanup/target_resource_groups.txt\" ]; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  TARGET_RGS=\$(cat ./.azure-cleanup/target_resource_groups.txt)" >> ./.azure-cleanup/execute_cleanup.sh
      echo "else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  log \"\$${RED}Error: Target resource groups file not found. Run discovery and planning first.\$${NC}\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  exit 1" >> ./.azure-cleanup/execute_cleanup.sh
      echo "fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# 1. Remove resource locks" >> ./.azure-cleanup/execute_cleanup.sh
      echo "log \"Step 1: Removing resource locks...\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "LOCKS=\$(az lock list --query \"[].id\" -o tsv 2>/dev/null) || true" >> ./.azure-cleanup/execute_cleanup.sh
      echo "if [ -n \"\$LOCKS\" ]; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  for LOCK_ID in \$LOCKS; do" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    if [ \"\$AUTO_MODE\" == \"true\" ] || (log \"Remove lock: \$LOCK_ID?\" && read -p \"Proceed? (y/n): \" CONFIRM && [ \"\$CONFIRM\" == \"y\" ]); then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      az lock delete --ids \"\$LOCK_ID\" && log \"\$${GREEN}Lock deleted: \$LOCK_ID\$${NC}\" || log \"\$${RED}Failed to delete lock: \$LOCK_ID\$${NC}\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      log \"Skipping lock: \$LOCK_ID\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  done" >> ./.azure-cleanup/execute_cleanup.sh
      echo "else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  log \"No locks found.\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# 2. Clean up Recovery Services vaults" >> ./.azure-cleanup/execute_cleanup.sh
      echo "log \"Step 2: Cleaning up Recovery Services vaults...\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "for RG in \$TARGET_RGS; do" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  log \"Checking for Recovery Services vaults in resource group: \$RG\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  VAULTS=\$(az resource list --resource-group \"\$RG\" --resource-type Microsoft.RecoveryServices/vaults --query \"[].name\" -o tsv 2>/dev/null) || true" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  " >> ./.azure-cleanup/execute_cleanup.sh
      echo "  if [ -n \"\$VAULTS\" ]; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    for VAULT in \$VAULTS; do" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      log \"\$${YELLOW}Found Recovery Services vault: \$VAULT in resource group: \$RG\$${NC}\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      " >> ./.azure-cleanup/execute_cleanup.sh
      echo "      if [ \"\$AUTO_MODE\" == \"true\" ] || (log \"Clean up vault: \$VAULT?\" && read -p \"Proceed? (y/n): \" CONFIRM && [ \"\$CONFIRM\" == \"y\" ]); then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        # Step 1: Disable soft delete" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        log \"Disabling soft delete for vault: \$VAULT\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        az backup vault backup-properties set --resource-group \"\$RG\" --name \"\$VAULT\" --soft-delete-feature-state Disable 2>/dev/null || log \"Soft delete disable failed - continuing anyway\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        " >> ./.azure-cleanup/execute_cleanup.sh
      echo "        # Step 2: Find and remove all backup items" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        CONTAINERS=\$(az backup container list --resource-group \"\$RG\" --vault-name \"\$VAULT\" --backup-management-type AzureIaasVM --query \"[].name\" -o tsv 2>/dev/null) || true" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        " >> ./.azure-cleanup/execute_cleanup.sh
      echo "        if [ -n \"\$CONTAINERS\" ]; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "          for CONTAINER in \$CONTAINERS; do" >> ./.azure-cleanup/execute_cleanup.sh
      echo "            log \"Processing container: \$CONTAINER\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "            ITEMS=\$(az backup item list --resource-group \"\$RG\" --vault-name \"\$VAULT\" --backup-management-type AzureIaasVM --container-name \"\$CONTAINER\" --query \"[].name\" -o tsv 2>/dev/null) || true" >> ./.azure-cleanup/execute_cleanup.sh
      echo "            " >> ./.azure-cleanup/execute_cleanup.sh
      echo "            if [ -n \"\$ITEMS\" ]; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "              for ITEM in \$ITEMS; do" >> ./.azure-cleanup/execute_cleanup.sh
      echo "                log \"Disabling protection for item: \$ITEM\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "                az backup protection disable --resource-group \"\$RG\" --vault-name \"\$VAULT\" --container-name \"\$CONTAINER\" --item-name \"\$ITEM\" --backup-management-type AzureIaasVM --delete-backup-data true --yes --force 2>/dev/null || log \"Failed to disable protection for item: \$ITEM\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "                " >> ./.azure-cleanup/execute_cleanup.sh
      echo "                # Wait for operation to complete" >> ./.azure-cleanup/execute_cleanup.sh
      echo "                log \"Waiting for protection disable operation to complete...\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "                sleep 30" >> ./.azure-cleanup/execute_cleanup.sh
      echo "              done" >> ./.azure-cleanup/execute_cleanup.sh
      echo "            fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "          done" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        " >> ./.azure-cleanup/execute_cleanup.sh
      echo "        # Step 3: Delete vault" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        log \"Attempting to delete vault: \$VAULT\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        if az resource delete --resource-group \"\$RG\" --resource-type Microsoft.RecoveryServices/vaults --name \"\$VAULT\" 2>/dev/null; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "          log \"\$${GREEN}Successfully deleted vault: \$VAULT\$${NC}\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "          log \"\$${RED}Failed to delete vault: \$VAULT\$${NC}\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        log \"Skipping vault: \$VAULT\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    done" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    log \"No Recovery Services vaults found in resource group: \$RG\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "done" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# 3. Delete resource groups" >> ./.azure-cleanup/execute_cleanup.sh
      echo "log \"Step 3: Deleting resource groups...\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "for RG in \$TARGET_RGS; do" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  log \"Processing resource group: \$RG\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  " >> ./.azure-cleanup/execute_cleanup.sh
      echo "  # Check if RG exists" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  if [ \"\$(az group exists --name \"\$RG\")\" == \"true\" ]; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    if [ \"\$AUTO_MODE\" == \"true\" ] || (log \"Delete resource group: \$RG?\" && read -p \"Proceed? (y/n): \" CONFIRM && [ \"\$CONFIRM\" == \"y\" ]); then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      log \"Deleting resource group: \$RG\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      if az group delete --name \"\$RG\" --yes; then" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        log \"\$${GREEN}Successfully deleted resource group: \$RG\$${NC}\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "        log \"\$${RED}Failed to delete resource group: \$RG\$${NC}\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "      log \"Skipping resource group: \$RG\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  else" >> ./.azure-cleanup/execute_cleanup.sh
      echo "    log \"Resource group \$RG does not exist - skipping\"" >> ./.azure-cleanup/execute_cleanup.sh
      echo "  fi" >> ./.azure-cleanup/execute_cleanup.sh
      echo "done" >> ./.azure-cleanup/execute_cleanup.sh
      echo "" >> ./.azure-cleanup/execute_cleanup.sh
      echo "# Cleanup completed" >> ./.azure-cleanup/execute_cleanup.sh
      echo "log \"\$${GREEN}Azure resource cleanup completed. Check the log file for details: \$LOG_FILE\$${NC}\"" >> ./.azure-cleanup/execute_cleanup.sh
      
      chmod +x ./.azure-cleanup/execute_cleanup.sh
      
      echo "Cleanup plan generated."
      echo "To review the cleanup plan, see ./.azure-cleanup/cleanup_plan.md"
      echo "To execute the cleanup plan, run: ./.azure-cleanup/execute_cleanup.sh"
    EOT
  }
}

# Resource to execute cleanup
resource "null_resource" "execute_cleanup" {
  count = var.execute_cleanup ? 1 : 0

  # Ensure plan is generated first
  depends_on = [null_resource.generate_cleanup_plan]

  triggers = {
    execute_trigger = var.execute_cleanup ? timestamp() : ""
  }

  provisioner "local-exec" {
    command = <<-EOT
      if [ -f "./.azure-cleanup/execute_cleanup.sh" ]; then
        echo "Executing cleanup plan..."
        ./.azure-cleanup/execute_cleanup.sh $${var.confirm_each_deletion ? "--confirm" : "--auto"}
      else
        echo "Error: Cleanup script not found. Please run the plan step first."
        exit 1
      fi
    EOT
  }
}

# Resource to cancel pending Azure operations
resource "null_resource" "cancel_operations" {
  count = var.cancel_operations ? 1 : 0

  triggers = {
    cancel_trigger = var.cancel_operations ? timestamp() : ""
  }

  provisioner "local-exec" {
    # Use the script from local variable to avoid heredoc escaping issues
    command = local.cancel_operations_script
  }
}

# Resource to clean up Recovery Services vault
resource "null_resource" "vault_cleanup" {
  count = var.target_vault_name != "" && var.target_vault_resource_group != "" ? 1 : 0

  triggers = {
    vault_trigger = "${var.target_vault_name}-${var.target_vault_resource_group}"
  }

  provisioner "local-exec" {
    # Use the script from local variable to avoid heredoc escaping issues
    command = local.vault_cleanup_script
  }
}

# Resource for aggressive resource group cleanup
resource "null_resource" "aggressive_resource_group_cleanup" {
  count = var.aggressive_cleanup && length(var.target_resource_groups) > 0 ? 1 : 0

  triggers = {
    cleanup_trigger = join("-", var.target_resource_groups)
  }

  provisioner "local-exec" {
    # Use the script from local variable to avoid heredoc escaping issues
    command = local.aggressive_cleanup_script
  }
}

# Local file to store module documentation
resource "local_file" "azure_cleanup_readme" {
  count = var.scan_resources ? 1 : 0

  filename = "./.azure-cleanup/README.md"
  content  = <<-EOT
# Azure Resource Cleanup Module

This module helps you discover, plan, and selectively clean up Azure resources.

## Usage

The cleanup process is divided into three phases:

1. **Discovery Phase**: Scans your Azure subscription for all resources
2. **Planning Phase**: Creates a cleanup plan based on discovered resources
3. **Execution Phase**: Executes the cleanup plan with optional confirmation steps

## Files Created

- `resource_groups.json`: List of all resource groups
- `resources.json`: List of all resources
- `vms.json`: List of all virtual machines
- `vaults.json`: List of all recovery services vaults
- `locks.json`: List of all resource locks
- `cleanup_plan.md`: The cleanup plan in Markdown format
- `execute_cleanup.sh`: Script to execute the cleanup plan

## Manual Execution

You can run the cleanup script manually with:

```
./.azure-cleanup/execute_cleanup.sh --confirm
```

Use `--auto` instead of `--confirm` to skip confirmation prompts.

## Excluded Resource Groups

The following resource groups are excluded from deletion:

$${join("\n", formatlist("- %s", var.exclude_resource_groups))}

## Advanced Cleanup Options

- **Vault Cleanup**: Targets specific Recovery Services vaults
- **Aggressive Cleanup**: Forces deletion of resource groups and their resources
- **Operation Cancellation**: Attempts to cancel pending Azure operations

## Terraform Variables

- `scan_resources`: Set to true to scan resources (discovery phase)
- `plan_cleanup`: Set to true to generate a cleanup plan (planning phase)
- `execute_cleanup`: Set to true to execute the cleanup plan (execution phase)
- `confirm_each_deletion`: Set to true to confirm each deletion step
- `exclude_resource_groups`: List of resource groups to exclude from deletion
- `target_resource_groups`: List of specific resource groups to target for cleanup
- `target_vault_name`: Specific Recovery Services vault to target for cleanup
- `target_vault_resource_group`: Resource group containing the target vault
- `aggressive_cleanup`: Set to true for more aggressive cleanup operations
- `cancel_operations`: Set to true to attempt canceling pending Azure operations

EOT
} 