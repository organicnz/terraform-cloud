# Infrastructure Outputs
output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "project_name" {
  description = "Name of the Azure project"
  value       = var.project_name
}

output "instance_name" {
  description = "Name of the VM instance"
  value       = var.instance_name
}

output "vm_size" {
  description = "Size of the virtual machine"
  value       = var.vm_size
}

output "disk_size_gb" {
  description = "Size of the OS disk in GB"
  value       = var.disk_size_gb
}