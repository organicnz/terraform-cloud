# Root Module Variables

# ============================================================================
# Oracle Cloud Authentication
# ============================================================================

variable "tenancy_ocid" {
  description = "Oracle Cloud Tenancy OCID"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ocid1\\.tenancy\\.oc1\\.\\..*", var.tenancy_ocid))
    error_message = "Tenancy OCID must be valid format"
  }
}

variable "user_ocid" {
  description = "Oracle Cloud User OCID"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ocid1\\.user\\.oc1\\.\\..*", var.user_ocid))
    error_message = "User OCID must be valid format"
  }
}

variable "fingerprint" {
  description = "Oracle Cloud API Key Fingerprint"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-f0-9]{2}(:[a-f0-9]{2}){15}$", var.fingerprint))
    error_message = "Fingerprint must be valid format (xx:xx:xx:...)"
  }
}

variable "private_key_path" {
  description = "Path to Oracle Cloud API private key"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "Oracle Cloud region"
  type        = string
  default     = "eu-stockholm-1"

  validation {
    condition = contains([
      "eu-stockholm-1",
      "eu-frankfurt-1",
      "eu-amsterdam-1",
      "eu-zurich-1",
      "eu-paris-1",
      "uk-london-1",
      "ap-sydney-1",
      "us-ashburn-1",
      "us-phoenix-1",
      "us-sanjose-1"
    ], var.region)
    error_message = "Region must be a valid OCI region"
  }
}

variable "compartment_ocid" {
  description = "Compartment OCID (defaults to tenancy root)"
  type        = string
  default     = ""
}

# ============================================================================
# Instance Configuration
# ============================================================================

variable "instance_name" {
  description = "Name for the compute instance"
  type        = string
  default     = "remnawave-node"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.instance_name))
    error_message = "Instance name must contain only alphanumeric characters, hyphens, and underscores"
  }
}

variable "instance_shape" {
  description = "Instance shape (Always Free: VM.Standard.A1.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs (Always Free max: 4)"
  type        = number
  default     = 4
}

variable "instance_memory_in_gbs" {
  description = "Memory in GB (Always Free max: 24)"
  type        = number
  default     = 24
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB (Always Free max: 200 GB)"
  type        = number
  default     = 200

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50 && var.boot_volume_size_in_gbs <= 200
    error_message = "Boot volume must be between 50 and 200 GB"
  }
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

# ============================================================================
# Network Configuration
# ============================================================================

variable "vcn_cidr_block" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr_block, 0))
    error_message = "VCN CIDR block must be valid"
  }
}

variable "subnet_cidr_block" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr_block, 0))
    error_message = "Subnet CIDR block must be valid"
  }
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH (restrict for security)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ============================================================================
# SSH Configuration
# ============================================================================

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

# ============================================================================
# Cloud-Init Configuration
# ============================================================================

variable "cloud_init_enabled" {
  description = "Enable cloud-init configuration"
  type        = bool
  default     = true
}

# ============================================================================
# Project Configuration
# ============================================================================

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "remnawave"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "additional_ssh_keys" {
  description = "Additional SSH public keys to authorize on the instance"
  type        = list(string)
  default     = []
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
