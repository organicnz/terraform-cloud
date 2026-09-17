# Configure the Contabo Provider
provider "contabo" {
  oauth2_client_id     = var.contabo_client_id
  oauth2_client_secret = var.contabo_client_secret
  oauth2_user          = var.contabo_user
  oauth2_pass          = var.contabo_password
}

# Data source to get available images
data "contabo_image" "ubuntu" {
  id = "afecbb85-e2fc-46f0-9684-b46b1faf00bb" # Ubuntu 22.04 LTS (Jammy Jellyfish) image ID
  # Note: Ubuntu 24.04 LTS may not be available yet on Contabo
}

# Create a VPS instance
resource "contabo_instance" "main" {
  display_name = var.instance_name

  # Image configuration
  image_id = data.contabo_image.ubuntu.id

  # Instance specifications
  product_id = var.product_id
  region     = var.region

  # SSH key configuration
  ssh_keys = var.ssh_keys

  # User data for initial setup
  user_data = base64encode(templatefile("${path.module}/scripts/user-data.sh", {
    admin_user = var.admin_user
  }))

  # Lifecycle management
  lifecycle {
    create_before_destroy = true
  }
}

# Create additional storage if needed
resource "contabo_object_storage" "backup" {
  count                    = var.enable_object_storage ? 1 : 0
  display_name             = "${var.instance_name}-backup"
  region                   = var.region
  total_purchased_space_tb = var.storage_size_limit_tb
}

# Create a private network if needed
resource "contabo_private_network" "main" {
  count       = var.enable_private_network ? 1 : 0
  name        = "${var.instance_name}-network"
  description = "Private network for ${var.instance_name}"
  region      = var.region

  # Assign instances to the network
  instance_ids = [contabo_instance.main.id]
}

# Note: Security groups and snapshots are not directly supported by the Contabo provider
# Firewall rules are managed through the server's operating system (UFW is configured in user-data.sh)
# Manual snapshots can be created through the Contabo customer control panel 