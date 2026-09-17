# Root Module - Oracle Cloud Remnawave Infrastructure

# Network Module
module "network" {
  source = "./modules/network"

  compartment_id    = local.compartment_id
  vcn_cidr_block    = local.network_config.vcn_cidr
  subnet_cidr_block = local.network_config.subnet_cidr
  project_name      = var.project_name
  environment       = var.environment
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  tags              = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  compartment_id                 = local.compartment_id
  availability_domain            = data.oci_identity_availability_domains.ads.availability_domains[0].name
  subnet_id                      = module.network.subnet_id
  nsg_id                         = module.network.nsg_id
  instance_name                  = local.instance_config.name
  instance_shape                 = local.instance_config.shape
  instance_ocpus                 = local.instance_config.ocpus
  instance_memory_in_gbs         = local.instance_config.memory_gb
  boot_volume_size_in_gbs        = local.instance_config.boot_vol_gb
  ssh_public_key                 = file(pathexpand(var.ssh_public_key_path))
  additional_ssh_keys            = var.additional_ssh_keys
  cloud_init_template            = var.cloud_init_enabled ? "${path.module}/cloud-init.yaml" : ""
  image_operating_system         = var.image_operating_system
  image_operating_system_version = var.image_operating_system_version
  tags                           = local.common_tags

  depends_on = [module.network]
}
