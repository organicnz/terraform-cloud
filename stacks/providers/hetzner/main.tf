resource "hcloud_server" "web" {
  name        = var.server_name
  server_type = "cx22"
  image       = var.image
  location    = var.location

  # Skip SSH keys entirely - we'll add them manually later if needed
  # ssh_keys    = [data.hcloud_ssh_key.existing_key.id]

  labels = {
    environment = var.environment
  }

  # Commented out as we're using Ansible for configuration instead
  # user_data = file("${path.module}/user_data.sh")

  # Enable backups if specified
  backups = var.enable_backups
}

# We're not using this data source anymore
# data "hcloud_ssh_key" "existing_key" {
#   fingerprint = var.existing_key_fingerprint
# }

resource "hcloud_firewall" "web" {
  name = "${var.server_name}-firewall"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.allowed_ssh_ips
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # ICMP (ping)
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall_attachment" "web" {
  firewall_id = hcloud_firewall.web.id
  server_ids  = [hcloud_server.web.id]
} 