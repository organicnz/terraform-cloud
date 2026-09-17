variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Name of the server"
  type        = string
  default     = "hetzner-cx22"
}

variable "image" {
  description = "OS image to use (e.g., ubuntu-22.04, debian-11)"
  type        = string
  default     = "ubuntu-22.04"
}

variable "location" {
  description = "Datacenter location"
  type        = string
  default     = "nbg1" # Nuremberg, Germany
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa_gitlab.pub"
}

variable "ssh_key_name" {
  description = "Name of the existing SSH key in Hetzner Cloud"
  type        = string
  default     = "default" # Change this to match your existing SSH key name
}

variable "existing_key_fingerprint" {
  description = "Fingerprint of the existing SSH key in Hetzner Cloud"
  type        = string
  default     = "42:13:54:29:f8:3e:f5:09:23:b5:a8:1c:2c:1a:3b:17" # This is a placeholder, update with your key's fingerprint
}

variable "environment" {
  description = "Environment label (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

variable "enable_backups" {
  description = "Enable backups for the server"
  type        = bool
  default     = false
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to connect via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Allow from anywhere (change for production)
} 