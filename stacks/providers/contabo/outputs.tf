# Instance Outputs
output "instance_id" {
  description = "ID of the created Contabo instance"
  value       = contabo_instance.main.id
}

output "instance_name" {
  description = "Display name of the created instance"
  value       = contabo_instance.main.display_name
}

output "instance_status" {
  description = "Current status of the instance"
  value       = contabo_instance.main.status
}

output "instance_ip_config" {
  description = "IP configuration of the instance"
  value       = contabo_instance.main.ip_config
  sensitive   = false
}

output "instance_public_ips" {
  description = "Public IP addresses of the instance"
  value = flatten([
    for ip in contabo_instance.main.ip_config : [
      for v4 in ip.v4 : v4.ip
    ]
    if ip.v4 != null
  ])
}

output "instance_ipv6_addresses" {
  description = "IPv6 addresses of the instance"
  value = flatten([
    for ip in contabo_instance.main.ip_config : [
      for v6 in ip.v6 : v6.ip
    ]
    if ip.v6 != null
  ])
}

# Note: Security groups are not supported by the Contabo provider
# Firewall rules are managed at the OS level through UFW

# Storage Outputs
output "object_storage_id" {
  description = "ID of the object storage (if created)"
  value       = var.enable_object_storage ? contabo_object_storage.backup[0].id : null
}

output "object_storage_s3_url" {
  description = "S3 URL of the object storage (if created)"
  value       = var.enable_object_storage ? contabo_object_storage.backup[0].s3_url : null
  sensitive   = true
}

# Note: Automated snapshots are not supported by the Contabo provider
# Manual snapshots can be created through the Contabo customer control panel

# Data Source Outputs
output "ubuntu_image_info" {
  description = "Information about the Ubuntu image being used"
  value = {
    image_id    = data.contabo_image.ubuntu.id
    name        = data.contabo_image.ubuntu.name
    description = data.contabo_image.ubuntu.description
  }
}

# Resource Summary
output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    instance = {
      id         = contabo_instance.main.id
      name       = contabo_instance.main.display_name
      product_id = contabo_instance.main.product_id
      region     = contabo_instance.main.region
      status     = contabo_instance.main.status
    }
    private_network = var.enable_private_network ? {
      id   = contabo_private_network.main[0].id
      cidr = contabo_private_network.main[0].cidr
    } : null
    object_storage = var.enable_object_storage ? {
      id = contabo_object_storage.backup[0].id
    } : null
  }
}

# Connection Information
output "ssh_connection_commands" {
  description = "SSH connection commands for the instance"
  value = flatten([
    for ip in contabo_instance.main.ip_config : [
      for v4 in ip.v4 : "ssh -i ${var.ssh_private_key_path} ${var.admin_user}@${v4.ip}"
    ]
    if ip.v4 != null
  ])
}

output "ssh_key_path" {
  description = "Path to the SSH private key used for authentication"
  value       = var.ssh_private_key_path
}

# Metadata outputs (normalized pattern)
output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "project_name" {
  description = "Name of the project"
  value       = var.instance_name
}