# Locals - Computed Values

locals {
  # Compartment resolution
  compartment_id = coalesce(var.compartment_ocid, var.tenancy_ocid)

  # Resource naming
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags
  common_tags = {
    Environment = var.environment
  }

  # Network configuration
  network_config = {
    vcn_cidr    = var.vcn_cidr_block
    subnet_cidr = var.subnet_cidr_block
    dns_label   = replace(var.project_name, "-", "")
  }

  # Instance configuration
  instance_config = {
    name        = var.instance_name
    shape       = var.instance_shape
    ocpus       = var.instance_ocpus
    memory_gb   = var.instance_memory_in_gbs
    boot_vol_gb = var.boot_volume_size_in_gbs
  }

  # Always Free tier validation
  is_always_free = (
    var.instance_shape == "VM.Standard.A1.Flex" &&
    var.instance_ocpus <= 4 &&
    var.instance_memory_in_gbs <= 24 &&
    var.boot_volume_size_in_gbs <= 200
  )
}
