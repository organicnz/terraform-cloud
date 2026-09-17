output "server_id" {
  description = "ID of the created server"
  value       = hcloud_server.web.id
}

output "server_name" {
  description = "Name of the created server"
  value       = hcloud_server.web.name
}

output "server_ipv4" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.web.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address of the server"
  value       = hcloud_server.web.ipv6_address
}

output "server_status" {
  description = "Status of the server"
  value       = hcloud_server.web.status
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${hcloud_server.web.ipv4_address}"
}

# Metadata outputs (normalized pattern)
output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "project_name" {
  description = "Name of the project"
  value       = var.server_name
} 