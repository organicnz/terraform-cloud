output "vcn_id" {
  description = "VCN OCID"
  value       = oci_core_vcn.main.id
}

output "subnet_id" {
  description = "Public subnet OCID"
  value       = oci_core_subnet.public.id
}

output "nsg_id" {
  description = "Network Security Group OCID"
  value       = oci_core_network_security_group.remnawave.id
}

output "vcn_cidr" {
  description = "VCN CIDR block"
  value       = oci_core_vcn.main.cidr_blocks[0]
}
