# VM Operations Module - Main Configuration

# Resource to stop/deallocate all VMs
resource "null_resource" "deallocate_vms" {
  count = var.deallocate_vms ? 1 : 0

  triggers = {
    # This ensures this resource is recreated when we want to deallocate VMs
    deallocate_trigger = var.deallocate_vms ? timestamp() : ""
  }

  provisioner "local-exec" {
    # Command to deallocate all VMs using Azure CLI
    command = <<-EOT
      echo "Starting shutdown of all Azure VMs..."
      
      # Get all VM IDs
      VM_IDS=$(az vm list --query "[].id" -o tsv)
      
      if [ -z "$VM_IDS" ]; then
        echo "No VMs found in your subscription."
        exit 0
      fi
      
      # Deallocate all VMs
      echo "Deallocating all VMs..."
      az vm deallocate --ids $VM_IDS
      
      echo "All VMs have been shut down successfully."
    EOT
  }
}

# Resource to prepare for infrastructure destruction
resource "null_resource" "prepare_destroy" {
  count = var.prepare_destroy ? 1 : 0

  triggers = {
    # This ensures this resource is recreated when we want to prepare for destruction
    prepare_destroy_trigger = var.prepare_destroy ? timestamp() : ""
  }

  provisioner "local-exec" {
    # Command to prepare for destruction
    command = <<-EOT
      echo "Preparing for infrastructure destruction..."
      
      # Show all resources that will be affected
      echo "The following resources will be affected:"
      az resource list --output table
      
      echo "Preparation complete. You can now run: terraform destroy"
    EOT
  }
}

# VM Operations Module
# This module provides operations for managing Azure VMs including shutdown and destruction

# Shutdown all VMs in a resource group
resource "null_resource" "shutdown_vms" {
  count = var.shutdown_vms ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      az vm deallocate --ids $(az vm list -g ${var.resource_group_name} --query "[].id" -o tsv) --no-wait
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

# Handle Recovery Services vault cleanup (needed for proper resource group deletion)
resource "null_resource" "cleanup_recovery_services_vaults" {
  count = var.destroy_resource_groups ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Cleaning up Recovery Services vaults..."
      
      # For each resource group, check for Recovery Services vaults
      for RG in ${join(" ", var.target_resource_groups)}; do
        echo "Checking for Recovery Services vaults in resource group: $RG"
        
        # Get list of Recovery Services vaults in the resource group
        VAULTS=$(az resource list --resource-group "$RG" --resource-type Microsoft.RecoveryServices/vaults --query "[].name" -o tsv 2>/dev/null) || true
        
        if [ -n "$VAULTS" ]; then
          for VAULT in $VAULTS; do
            echo "Found Recovery Services vault: $VAULT in resource group: $RG"
            
            # Disable soft delete to allow for complete deletion
            echo "Disabling soft delete for vault: $VAULT"
            az backup vault backup-properties set --resource-group "$RG" --name "$VAULT" --soft-delete-feature-state Disable || true
            
            # Get all protected VMs
            CONTAINERS=$(az backup container list --resource-group "$RG" --vault-name "$VAULT" --backup-management-type AzureIaasVM --output tsv --query "[].name" 2>/dev/null) || true
            
            if [ -n "$CONTAINERS" ]; then
              for CONTAINER in $CONTAINERS; do
                # Get container name without the IaasVMContainer; prefix
                CONTAINER_NAME=$(echo "$CONTAINER" | sed 's/IaasVMContainer;//')
                
                # Get items in the container
                ITEMS=$(az backup item list --resource-group "$RG" --vault-name "$VAULT" --backup-management-type AzureIaasVM --query "[?contains(name, '$CONTAINER_NAME')].name" -o tsv 2>/dev/null) || true
                
                for ITEM in $ITEMS; do
                  echo "Disabling protection for item: $ITEM"
                  az backup protection disable --resource-group "$RG" --vault-name "$VAULT" --container-name "$CONTAINER" --item-name "$ITEM" --backup-management-type AzureIaasVM --delete-backup-data true --yes || true
                done
              done
            fi
            
            # Try to delete the vault after clearing protected items
            echo "Attempting to delete vault: $VAULT"
            az resource delete --resource-group "$RG" --resource-type Microsoft.RecoveryServices/vaults --name "$VAULT" || true
          done
        fi
      done
      
      echo "Recovery Services vault cleanup completed."
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

# Remove all resource locks before attempting to destroy resource groups
resource "null_resource" "remove_resource_locks" {
  count = var.destroy_resource_groups ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Removing resource locks..."
      
      # Get all locks
      LOCKS=$(az lock list --output tsv --query "[].id")
      
      # Remove each lock
      for LOCK_ID in $LOCKS; do
        echo "Removing lock: $LOCK_ID"
        az lock delete --ids "$LOCK_ID" || true
      done
      
      # Check for any VM-level locks that might have been missed
      for RG in ${join(" ", var.target_resource_groups)}; do
        echo "Checking for VM-level locks in resource group: $RG"
        VMS=$(az vm list --resource-group "$RG" --query "[].name" -o tsv 2>/dev/null) || true
        
        for VM in $VMS; do
          echo "Removing any locks on VM: $VM in resource group: $RG"
          VM_LOCKS=$(az lock list --resource-group "$RG" --resource-type Microsoft.Compute/virtualMachines --resource "$VM" --query "[].name" -o tsv 2>/dev/null) || true
          
          for VM_LOCK in $VM_LOCKS; do
            echo "Removing VM-level lock: $VM_LOCK"
            az lock delete --name "$VM_LOCK" --resource-group "$RG" --resource-type Microsoft.Compute/virtualMachines --resource "$VM" || true
          done
        done
      done
      
      echo "Resource lock removal completed."
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

# Destroy specific resource groups
resource "null_resource" "destroy_resource_groups" {
  count = var.destroy_resource_groups ? 1 : 0

  # This ensures lock removal and vault cleanup happens first
  depends_on = [
    null_resource.remove_resource_locks,
    null_resource.cleanup_recovery_services_vaults
  ]

  provisioner "local-exec" {
    command = <<-EOT
      for rg in ${join(" ", var.target_resource_groups)}; do
        echo "Destroying resource group: $rg"
        az group delete --name $rg --yes --no-wait
      done
      
      # Wait for deletions to complete and show remaining resource groups
      echo "Waiting for resource group deletions to complete..."
      sleep 30
      
      MAX_RETRIES=20
      RETRY_COUNT=0
      
      while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        PENDING_DELETES=$(az group list --query "[?provisioningState=='Deleting'].name" -o tsv | wc -l | tr -d ' ')
        
        if [ "$PENDING_DELETES" -eq "0" ]; then
          echo "All resource group deletions completed!"
          break
        else
          echo "$PENDING_DELETES resource groups still being deleted. Waiting 30 seconds..."
          sleep 30
          RETRY_COUNT=$((RETRY_COUNT + 1))
        fi
      done
      
      echo "Remaining resource groups:"
      az group list -o table
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
} 