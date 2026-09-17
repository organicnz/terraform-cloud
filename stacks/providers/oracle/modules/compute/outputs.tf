output "instance_id" {
  description = "Instance OCID"
  value       = oci_core_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = oci_core_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address"
  value       = oci_core_instance.main.private_ip
}

output "instance_state" {
  description = "Instance state"
  value       = oci_core_instance.main.state
}

output "instance_name" {
  description = "Instance display name"
  value       = oci_core_instance.main.display_name
}

output "instance_shape" {
  description = "Instance shape"
  value       = oci_core_instance.main.shape
}

output "instance_ocpus" {
  description = "Number of OCPUs"
  value       = oci_core_instance.main.shape_config[0].ocpus
}

output "instance_memory_in_gbs" {
  description = "Memory in GB"
  value       = oci_core_instance.main.shape_config[0].memory_in_gbs
}
