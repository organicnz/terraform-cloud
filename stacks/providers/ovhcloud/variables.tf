variable "ovh_endpoint" {
  description = "OVHcloud API endpoint"
  type        = string
  default     = "ovh-us"
  validation {
    condition     = contains(["ovh-eu", "ovh-us", "ovh-ca"], var.ovh_endpoint)
    error_message = "Endpoint must be one of: ovh-eu, ovh-us, ovh-ca"
  }
}

variable "ovh_subsidiary" {
  description = "OVHcloud subsidiary (US, CA, EU, etc.)"
  type        = string
  default     = "US"
}

variable "ovh_application_key" {
  description = "OVHcloud Application Key"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.ovh_application_key) > 0
    error_message = "Application key cannot be empty"
  }
}

variable "ovh_application_secret" {
  description = "OVHcloud Application Secret"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.ovh_application_secret) > 0
    error_message = "Application secret cannot be empty"
  }
}

variable "ovh_consumer_key" {
  description = "OVHcloud Consumer Key"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.ovh_consumer_key) > 0
    error_message = "Consumer key cannot be empty"
  }
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development"
  }
}

variable "project_name" {
  description = "Name of the OVHcloud project"
  type        = string
  default     = "my-ovh-project"
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters"
  }
}

variable "vps_name" {
  description = "Name of the VPS instance"
  type        = string
  default     = "vps-warsaw-1"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vps_name))
    error_message = "VPS name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "vps_plan_code" {
  description = "VPS plan code (e.g., vps-value-1-2-40, vps-essential-2-4-80, vps-comfort-4-8-160)"
  type        = string
  default     = "vps-comfort-4-8-160"
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs to add to the VPS"
  type        = list(string)
  default     = []
}

variable "ssh_public_key" {
  description = "SSH public key content (optional, will be uploaded to OVHcloud)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_backup" {
  description = "Enable automated backup for the VPS"
  type        = bool
  default     = false
}

variable "backup_cron" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "0 2 * * *"
  validation {
    condition     = can(regex("^[0-9*/ ,-]+$", var.backup_cron))
    error_message = "Backup cron must be a valid cron expression"
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses/CIDR blocks allowed to SSH (empty = all)"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for ip in var.allowed_ssh_ips : can(cidrhost(ip, 0))
    ])
    error_message = "All entries must be valid IP addresses or CIDR blocks"
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "auto_recovery" {
  description = "Enable automatic recovery on instance failure"
  type        = bool
  default     = true
}

variable "region" {
  description = "OVHcloud region for VPS deployment (for tagging purposes)"
  type        = string
  default     = "WAW1"
}
