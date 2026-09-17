# Azure Cleanup Module Variables

variable "scan_resources" {
  description = "Set to true to scan Azure resources (discovery phase)"
  type        = bool
  default     = false
}

variable "plan_cleanup" {
  description = "Set to true to generate a cleanup plan (planning phase)"
  type        = bool
  default     = false
}

variable "execute_cleanup" {
  description = "Set to true to execute the cleanup plan (execution phase)"
  type        = bool
  default     = false
}

variable "confirm_each_deletion" {
  description = "Set to true to confirm each deletion step during execution"
  type        = bool
  default     = true
}

variable "exclude_resource_groups" {
  description = "List of resource groups to exclude from deletion"
  type        = list(string)
  default     = ["NetworkWatcherRG", "cloud-shell-storage-westeurope", "AzureBackupRG_polandcentral_1"]
}

variable "target_resource_groups" {
  description = "List of specific resource groups to target for cleanup (if empty, all non-excluded groups will be targeted)"
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