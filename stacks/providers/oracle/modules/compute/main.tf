# Compute Module - Main Configuration

# Get latest image
data "oci_core_images" "os_image" {
  compartment_id           = var.compartment_id
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = [contains(split(".", var.instance_shape), "A1") ? "^Canonical-Ubuntu-${var.image_operating_system_version}-aarch64.*" : "^Canonical-Ubuntu-${var.image_operating_system_version}-[0-9].*"]
    regex  = true
  }
}

locals {
  image_id = data.oci_core_images.os_image.images[0].id

  cloud_init_content = var.cloud_init_template != "" ? templatefile(var.cloud_init_template, {
    hostname = var.instance_name
  }) : ""
}

# Compute Instance
resource "oci_core_instance" "main" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = var.instance_name
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = local.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.instance_name}-vnic"
    assign_public_ip = true
    hostname_label   = replace(var.instance_name, "_", "-")
    nsg_ids          = [var.nsg_id]
  }

  metadata = merge(
    {
      ssh_authorized_keys = join("\n", concat([trimspace(var.ssh_public_key)], var.additional_ssh_keys))
    },
    local.cloud_init_content != "" ? {
      user_data = base64encode(local.cloud_init_content)
    } : {}
  )

  freeform_tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )

  lifecycle {
    ignore_changes = [
      source_details[0].source_id,
      metadata["user_data"]
    ]
  }

  timeouts {
    create = "30m"
  }
}

# Wait for instance to be fully running
resource "time_sleep" "wait_for_instance" {
  depends_on = [oci_core_instance.main]

  create_duration = "30s"
}
