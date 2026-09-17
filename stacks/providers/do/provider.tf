variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.do_token) > 0
    error_message = "The DigitalOcean API token cannot be empty."
  }
}

variable "pub_key" {
  description = "Public SSH key path"
  type        = string

  validation {
    condition     = fileexists(pathexpand(var.pub_key))
    error_message = "The specified public key file does not exist."
  }
}

variable "pvt_key" {
  description = "Private SSH key path"
  type        = string
  sensitive   = true

  validation {
    condition     = fileexists(pathexpand(var.pvt_key))
    error_message = "The specified private key file does not exist."
  }
}

variable "ssh_fingerprint" {
  description = "SSH key fingerprint"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.ssh_fingerprint) > 0
    error_message = "SSH fingerprint cannot be empty."
  }
}

variable "droplet_name" {
  description = "Name of the DigitalOcean droplet"
  type        = string
  default     = "vps"

  validation {
    condition     = length(var.droplet_name) >= 3 && length(var.droplet_name) <= 63
    error_message = "Droplet name must be between 3 and 63 characters."
  }
}

variable "region" {
  description = "DigitalOcean region for deployment"
  type        = string
  default     = "fra1"
}

variable "droplet_size" {
  description = "Size of the DigitalOcean droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}

provider "digitalocean" {
  token          = var.do_token
  http_retry_max = 10
}