variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "domain" {
  description = "Cloudflare domain name"
  type        = string
  default     = "example.com"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}