variable "virtualizor_api_key" {
  description = "Virtualizor API Key from Cloudnium portal"
  type        = string
  sensitive   = true
}

variable "virtualizor_api_pass" {
  description = "Virtualizor API Password / Secret"
  type        = string
  sensitive   = true
}

variable "virtualizor_endpoint" {
  description = "Management URL (e.g., https://cl-ny.cloudnium.net:4085)"
  default     = "https://cl-ny.cloudnium.net:4085"
  type        = string
}

variable "node_count" {
  description = "Horizontal Scaling: Number of nodes to deploy"
  default     = 1
  type        = number
}

variable "plan_id" {
  description = "Vertical Scaling: Plan ID for NY-1 (typically 1 or as retrieved from provider)"
  default     = 1
  type        = number
}

# --- Surfy node configuration ---

variable "supabase_url" {
  description = "Supabase Project URL"
  type        = string
}

variable "supabase_key" {
  description = "Supabase Service Role/Anon Key"
  type        = string
  sensitive   = true
}

variable "surfy_reality_dest" {
  description = "Destination for Reality disguise"
  default     = "google.com"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key for provisioning"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "os_id" {
  description = "OS Image ID (Virtualizor ID for Ubuntu 22.04 or similar)"
  default     = 1000 # Placeholder: user should verify ID
  type        = number
}
