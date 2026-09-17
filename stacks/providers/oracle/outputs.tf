# Root Module Outputs

# ============================================================================
# Instance Information
# ============================================================================

output "instance_id" {
  description = "OCID of the compute instance"
  value       = module.compute.instance_id
}

output "instance_name" {
  description = "Name of the compute instance"
  value       = module.compute.instance_name
}

output "instance_state" {
  description = "Current state of the instance"
  value       = module.compute.instance_state
}

output "instance_shape" {
  description = "Shape of the instance"
  value       = module.compute.instance_shape
}

output "instance_ocpus" {
  description = "Number of OCPUs allocated"
  value       = module.compute.instance_ocpus
}

output "instance_memory_in_gbs" {
  description = "Memory allocated in GB"
  value       = module.compute.instance_memory_in_gbs
}

# ============================================================================
# Network Information
# ============================================================================

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = module.compute.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = module.compute.instance_private_ip
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.network.vcn_id
}

output "subnet_id" {
  description = "OCID of the public subnet"
  value       = module.network.subnet_id
}

output "nsg_id" {
  description = "OCID of the Network Security Group"
  value       = module.network.nsg_id
}

# ============================================================================
# Connection Information
# ============================================================================

output "ssh_user" {
  description = "Default SSH user"
  value       = "ubuntu"
}

output "ssh_host" {
  description = "Public IP for SSH"
  value       = module.compute.instance_public_ip
}

output "ssh_command" {
  description = "Full SSH command"
  value       = "ssh -i ~/.ssh/id_ed25519 ubuntu@${module.compute.instance_public_ip}"
}

# ============================================================================
# Resource Summary
# ============================================================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region               = var.region
    environment          = var.environment
    instance_name        = module.compute.instance_name
    public_ip            = module.compute.instance_public_ip
    shape                = "${module.compute.instance_ocpus} OCPU, ${module.compute.instance_memory_in_gbs} GB RAM"
    vcn_cidr             = module.network.vcn_cidr
    always_free_eligible = var.instance_shape == "VM.Standard.A1.Flex" && var.instance_ocpus <= 4 && var.instance_memory_in_gbs <= 24
  }
}
