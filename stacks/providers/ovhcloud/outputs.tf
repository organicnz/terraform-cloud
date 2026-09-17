# Infrastructure Outputs
output "vps_id" {
  description = "VPS service name/ID"
  value       = ovh_vps.vps.service_name
}

output "vps_name" {
  description = "VPS display name"
  value       = ovh_vps.vps.display_name
}

output "vps_plan" {
  description = "VPS plan code"
  value       = var.vps_plan_code
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "project_name" {
  description = "Name of the OVHcloud project"
  value       = var.project_name
}

# Cost tracking
output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD (varies by plan)"
  value = {
    plan = var.vps_plan_code
    note = "Check OVHcloud pricing for exact costs"
  }
}