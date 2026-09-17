# Azure Authentication Template
# Using Azure CLI authentication - no need for credential variables

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., production, staging, development)"
  default     = "development"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

# Network related variables are commented out but kept for reference
# variable "network" {}
# variable "subnet" {}
# variable "public_ip" {}
# variable "network_interface" {}
# variable "ip_configuration" {}
# variable "virtual_machine" {}
# variable "storage_os_disk" {}

variable "instance_name" {
  type        = string
  description = "Name of the VM instance"
}

variable "key_data" {
  description = "SSH key data for VM authentication"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Location of the Azure resource group"
  type        = string
  default     = "Germany West Central"
}

variable "admin_username" {
  type        = string
  description = "The username for the virtual machine"
}

variable "disk_size_gb" {
  type        = number
  description = "The size of the OS disk in GB"
  default     = 30
}

variable "vm_size" {
  type        = string
  description = "The size of the virtual machine"
  default     = "Standard_D2s_v3"
}

variable "resource_group_name_prefix" {
  type        = string
  description = "Prefix for resource group name"
  default     = "terraform"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "terraform"
}

# VM Operations
variable "deallocate_vms" {
  type        = bool
  description = "Whether to deallocate (stop) all VMs as part of the Terraform execution"
  default     = false
}

variable "prepare_destroy" {
  type        = bool
  description = "Whether to prepare for infrastructure destruction"
  default     = false
}

# Infrastructure Destruction Variables
variable "destroy_infrastructure" {
  type        = bool
  description = "Set to true to destroy infrastructure using Terraform workflows"
  default     = false
}

variable "target_resource_group_names" {
  type        = list(string)
  description = "List of resource group names to destroy when destroy_infrastructure is true"
  default     = []
}

# Network settings
variable "address_space" {
  description = "VNet address space"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "Subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

# Azure Cleanup Module Variables
variable "scan_azure_resources" {
  description = "Set to true to scan Azure resources in preparation for cleanup"
  type        = bool
  default     = false
}

variable "plan_azure_cleanup" {
  description = "Set to true to create a cleanup plan for Azure resources"
  type        = bool
  default     = false
}

variable "execute_azure_cleanup" {
  description = "Set to true to execute the Azure cleanup plan"
  type        = bool
  default     = false
}

variable "confirm_each_deletion" {
  description = "Set to true to confirm each deletion step"
  type        = bool
  default     = true
}

# Enhanced Azure Cleanup Options
variable "target_cleanup_groups" {
  description = "List of specific resource groups to target for cleanup"
  type        = list(string)
  default     = []
}

variable "target_vault_name" {
  description = "Specific Recovery Services vault to target for cleanup"
  type        = string
  default     = ""
}

variable "target_vault_resource_group" {
  description = "Resource group containing the target Recovery Services vault"
  type        = string
  default     = ""
}

variable "aggressive_cleanup" {
  description = "Set to true for more aggressive cleanup operations (force deletion)"
  type        = bool
  default     = false
}

variable "cancel_operations" {
  description = "Set to true to attempt canceling pending Azure operations"
  type        = bool
  default     = false
}