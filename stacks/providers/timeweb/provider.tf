variable "timeweb_token" {
  description = "Timeweb API token"
  type        = string
  sensitive   = true
}

variable "pub_key" {
  description = "Public SSH key"
  type        = string
}

variable "pvt_key" {
  description = "Private SSH key path"
  type        = string
  sensitive   = true
}

variable "ssh_fingerprint" {
  description = "SSH key fingerprint"
  type        = string
  sensitive   = true
}

variable "instance_name" {
  description = "Name of the Timeweb instance"
  type        = string
  default     = "web"
}

provider "twc" {
  token = var.timeweb_token
}