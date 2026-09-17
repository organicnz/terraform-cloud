# Contabo Authentication Variables
variable "contabo_client_id" {
  description = "Contabo OAuth2 Client ID"
  type        = string
  sensitive   = true
}

variable "contabo_client_secret" {
  description = "Contabo OAuth2 Client Secret"
  type        = string
  sensitive   = true
}

variable "contabo_user" {
  description = "Contabo API User"
  type        = string
  sensitive   = true
}

variable "contabo_password" {
  description = "Contabo API Password"
  type        = string
  sensitive   = true
}

# Instance Configuration Variables
variable "instance_name" {
  description = "Display name for the Contabo instance"
  type        = string
  default     = "vps"

  validation {
    condition     = length(var.instance_name) > 0 && length(var.instance_name) <= 255
    error_message = "Instance name must be between 1 and 255 characters."
  }
}

variable "hostname" {
  description = "Hostname for the instance"
  type        = string
  default     = "terraform-contabo"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.hostname))
    error_message = "Hostname must contain only alphanumeric characters, dots, and hyphens."
  }
}

variable "product_id" {
  description = "Contabo product ID for the instance type"
  type        = string
  default     = "VPS-1-SSD-10"

  validation {
    condition = contains([
      "VPS-1-SSD-10", "VPS-2-SSD-20", "VPS-3-SSD-40",
      "VPS-4-SSD-60", "VPS-5-SSD-100", "VPS-6-SSD-200",
      "V92" # VPS 10 SSD - 3 vCPU, 8GB RAM, 150GB SSD
    ], var.product_id)
    error_message = "Product ID must be a valid Contabo VPS product ID."
  }
}

variable "region" {
  description = "Region where the instance will be deployed"
  type        = string
  default     = "EU"

  validation {
    condition = contains([
      "EU", "US-central", "US-east", "US-west", "SIN"
    ], var.region)
    error_message = "Region must be one of: EU, US-central, US-east, US-west, SIN."
  }
}

variable "ssh_keys" {
  description = "List of SSH key IDs to associate with the instance"
  type        = list(number)
  default     = []
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key file for connecting to the instance"
  type        = string
  default     = "~/.ssh/azure_id_rsa.pem"

  validation {
    condition     = can(regex("^[~./].*\\.(pem|key|rsa)$", var.ssh_private_key_path))
    error_message = "SSH private key path must be a valid path ending with .pem, .key, or .rsa"
  }
}

variable "admin_user" {
  description = "Admin username for the instance"
  type        = string
  default     = "admin"

  validation {
    condition     = can(regex("^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\\$)$", var.admin_user))
    error_message = "Admin user must be a valid Linux username."
  }
}

variable "add_ons" {
  description = "List of add-ons for the instance"
  type        = list(string)
  default     = []
}

# Object Storage Configuration
variable "enable_object_storage" {
  description = "Enable object storage for backup"
  type        = bool
  default     = false
}

variable "storage_size_limit_tb" {
  description = "Storage size limit in TB for object storage"
  type        = number
  default     = 1

  validation {
    condition     = var.storage_size_limit_tb > 0 && var.storage_size_limit_tb <= 100
    error_message = "Storage size limit must be between 1 and 100 TB."
  }
}

# Private Network Configuration
variable "enable_private_network" {
  description = "Enable private network for the instance"
  type        = bool
  default     = false
}

variable "private_network_cidr" {
  description = "CIDR block for the private network"
  type        = string
  default     = "10.0.0.0/24"

  validation {
    condition     = can(cidrhost(var.private_network_cidr, 0))
    error_message = "Private network CIDR must be a valid IPv4 CIDR block."
  }
}

# Security Group Configuration
variable "enable_security_group" {
  description = "Enable security group for firewall rules"
  type        = bool
  default     = true
}

variable "ssh_allowed_ips" {
  description = "IP range allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.ssh_allowed_ips, 0))
    error_message = "SSH allowed IPs must be a valid IPv4 CIDR block."
  }
}

variable "custom_ports" {
  description = "List of custom ports to open in the security group"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    ip_range  = string
  }))
  default = []

  validation {
    condition = alltrue([
      for port in var.custom_ports :
      contains(["tcp", "udp", "icmp"], port.protocol) &&
      port.from_port >= 1 && port.from_port <= 65535 &&
      port.to_port >= 1 && port.to_port <= 65535 &&
      port.from_port <= port.to_port &&
      can(cidrhost(port.ip_range, 0))
    ])
    error_message = "Custom ports must have valid protocol (tcp/udp/icmp), port range (1-65535), and valid CIDR."
  }
}

# Snapshot Configuration
variable "enable_snapshots" {
  description = "Enable automatic snapshots for backup"
  type        = bool
  default     = false
}

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
} 