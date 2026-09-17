# Compute Module Variables

variable "compartment_id" {
  description = "Compartment OCID"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID"
  type        = string
}

variable "nsg_id" {
  description = "Network Security Group OCID"
  type        = string
}

variable "instance_name" {
  description = "Instance display name"
  type        = string
}

variable "instance_shape" {
  description = "Instance shape"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_ocpus >= 1 && var.instance_ocpus <= 4
    error_message = "OCPUs must be between 1 and 4 for Always Free tier"
  }
}

variable "instance_memory_in_gbs" {
  description = "Memory in GB"
  type        = number
  default     = 6

  validation {
    condition     = var.instance_memory_in_gbs >= 1 && var.instance_memory_in_gbs <= 24
    error_message = "Memory must be between 1 and 24 GB for Always Free tier"
  }
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50 && var.boot_volume_size_in_gbs <= 200
    error_message = "Boot volume must be between 50 and 200 GB for Always Free tier"
  }
}

variable "ssh_public_key" {
  description = "Primary SSH public key content"
  type        = string
}

variable "additional_ssh_keys" {
  description = "Additional SSH public keys to authorize"
  type        = list(string)
  default     = []
}

variable "cloud_init_template" {
  description = "Cloud-init template file path"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "image_operating_system" {
  description = "Operating system for the image"
  type        = string
  default     = "Canonical Ubuntu"
}

variable "image_operating_system_version" {
  description = "Operating system version"
  type        = string
  default     = "24.04"
}
