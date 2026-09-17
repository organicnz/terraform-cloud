# VM Operations Module - Variables

variable "deallocate_vms" {
  description = "Whether to deallocate all VMs"
  type        = bool
  default     = false
}

variable "prepare_destroy" {
  description = "Whether to prepare for infrastructure destruction"
  type        = bool
  default     = false
}

variable "shutdown_vms" {
  description = "Whether to shutdown all VMs in the resource group"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "The name of the resource group containing the VMs to shut down"
  type        = string
  default     = ""
}

variable "destroy_resource_groups" {
  description = "Whether to destroy the specified resource groups"
  type        = bool
  default     = false
}

variable "target_resource_groups" {
  description = "List of resource groups to destroy"
  type        = list(string)
  default     = []
} 