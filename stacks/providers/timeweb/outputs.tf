output "instance_name" {
  description = "Name of the Timeweb instance"
  value       = var.instance_name
}

output "server_id" {
  description = "ID of the Timeweb server"
  value       = twc_server.my-timeweb-server.id
}

# Metadata outputs (normalized pattern)
output "environment" {
  description = "Deployment environment"
  value       = "production"
}

output "project_name" {
  description = "Name of the project"
  value       = var.instance_name
}