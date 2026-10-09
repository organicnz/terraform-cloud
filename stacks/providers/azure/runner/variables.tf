variable "subscription_id" {
  type        = string
  description = "Azure subscription ID to deploy into. Defaults to the free Azure for Students subscription."
  default     = "97e7954d-922c-49e9-b244-68753e6b316c"
}

variable "github_token" {
  type        = string
  description = "GitHub Actions runner registration token (short-lived, ~1h). Generate right before apply."
  sensitive   = true
}

variable "github_repo" {
  type        = string
  description = "Repository in owner/repo format to register the runner against."
  default     = ""
}

variable "github_org" {
  type        = string
  description = "Organization to register an org-level runner against. Overrides github_repo when set."
  default     = ""
}

variable "location" {
  type    = string
  default = "eastasia"
}

variable "resource_prefix" {
  type    = string
  default = "ghrunner"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2ats_v2"
}

variable "admin_username" {
  type    = string
  default = "runneradmin"
}

variable "ssh_public_key" {
  type        = string
  description = "Optional SSH public key, for access after adding a jump box or public IP."
  default     = ""
}

variable "runner_name" {
  type        = string
  description = "Runner name. Defaults to <prefix>-<location>."
  default     = ""
}

variable "runner_labels" {
  type        = string
  description = "Comma-separated runner labels."
  default     = "self-hosted,linux,x64"
}
