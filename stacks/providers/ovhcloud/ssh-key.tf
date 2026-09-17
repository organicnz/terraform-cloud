# SSH Key Management
# Note: SSH keys for VPS are typically configured post-deployment
# or during the initial setup through OVHcloud control panel

locals {
  # SSH key will be configured via cloud-init or manual setup
  ssh_key_configured = var.ssh_public_key != "" ? true : false
}

# Store SSH key for reference
resource "local_file" "ssh_key_info" {
  count    = var.ssh_public_key != "" ? 1 : 0
  filename = "${path.module}/.terraform/ssh_key.txt"
  content  = <<-EOT
    SSH Public Key configured for VPS: ${ovh_vps.vps.display_name}
    
    Key: ${var.ssh_public_key}
    
    Note: Configure this key manually in OVHcloud control panel or via API
  EOT

  lifecycle {
    ignore_changes = all
  }
}
