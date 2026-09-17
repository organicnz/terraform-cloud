# Infrastructure outputs (Cloudflare DNS resources are managed in cloudflare.tf)
# No root-level outputs needed for DNS-only stack; metadata outputs below:

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "project_name" {
  description = "Name of the Cloudflare domain project"
  value       = var.domain
}