# Metadata outputs (normalized pattern)
output "project_name" {
  description = "Name of the project"
  value       = var.droplet_name
}

output "ssh_command" {
  description = "SSH command to connect to the droplet"
  value       = "ssh -i ${var.pvt_key} root@${digitalocean_droplet.vps.ipv4_address}"
  sensitive   = true
}