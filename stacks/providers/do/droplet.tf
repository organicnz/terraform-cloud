resource "digitalocean_droplet" "vps" {
  name       = var.droplet_name
  image      = "ubuntu-24-04-x64"
  size       = var.droplet_size # s-1vcpu-1gb: $6/mo, 1GB RAM, 1 CPU, 25GB SSD, 1TB transfer
  region     = var.region
  ssh_keys   = [var.ssh_fingerprint]
  backups    = false
  monitoring = true
  ipv6       = true

  tags = [
    "environment:production",
    "service:vps",
    "managed-by:terraform"
  ]

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file(var.pvt_key)
      timeout     = "2m"
    }

    inline = [
      # Configure firewall
      "ufw allow 22/tcp",
      "ufw allow 80/tcp",
      "ufw allow 80/udp",
      "ufw allow 443/tcp",
      "ufw allow 443/udp",
      "ufw --force enable",

      # Update system
      "apt-get update -y",
      "apt-get upgrade -y",

      # Install Docker
      "apt-get -y install docker.io docker-compose",

      # Create directory for Docker applications
      "mkdir -p /root/docker-apps",

      # System setup is complete
      "echo 'Provisioning complete!'"
    ]
  }
}

# Output variables for easier access to server details
output "droplet_ip" {
  description = "Public IP address of the VPS droplet"
  value       = digitalocean_droplet.vps.ipv4_address
}

output "droplet_id" {
  description = "ID of the VPS droplet"
  value       = digitalocean_droplet.vps.id
}

output "server_url" {
  description = "URL to access the web server"
  value       = "http://${digitalocean_droplet.vps.ipv4_address}/"
}




