#!/bin/bash

# Terraform Contabo VPS Initial Setup Script
# This script runs on first boot to configure the instance

set -e  # Exit on any error

# Variables passed from Terraform
ADMIN_USER="${admin_user}"

# Logging setup
LOG_FILE="/var/log/terraform-init.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Terraform Contabo Cloud VPS 10 Setup Started ==="
echo "Date: $(date)"
echo "Admin User: $ADMIN_USER"
echo "OS: Ubuntu 24.04 LTS"

# Update system packages
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    fail2ban \
    ufw \
    tree \
    jq \
    net-tools \
    dnsutils

# Configure UFW firewall
echo "Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw --force enable

# Configure fail2ban for SSH protection
echo "Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Create admin user if it doesn't exist
if [ "$ADMIN_USER" != "root" ] && ! id "$ADMIN_USER" &>/dev/null; then
    echo "Creating admin user: $ADMIN_USER"
    useradd -m -s /bin/bash "$ADMIN_USER"
    usermod -aG sudo "$ADMIN_USER"
    
    # Allow sudo without password for convenience (you may want to disable this in production)
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$ADMIN_USER"
    
    # Create .ssh directory for the user
    mkdir -p "/home/$ADMIN_USER/.ssh"
    chown "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
    chmod 700 "/home/$ADMIN_USER/.ssh"
fi

# Add SSH public key for key-based authentication
echo "Adding SSH public key for $ADMIN_USER..."
mkdir -p "/home/$ADMIN_USER/.ssh"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCb7T6hz3sH+wynfqhiTo8D3FzW0UR+aBpQna8u72b/vX4T0PV6Aii0/r4YlNGCf+l8wECs1kn2Z+OxsBHL2t5RS8H5l6YXNPDg5ciurwp4JlKbstxA90DMF8JKG7pbiNYpoqbIOP944rWzHeUNYTREdqWy8ghjPb7AKh+cDQPRGrgRUkoAg/Oy3fOI45WkT5hHoUARLEDEcYWto3ImSgts7OaJm8FmkZWKnoxGp5SqKeiIdvOGDEvJEJzK+fmRFYaytbNDesYZaVGhcnc30xl33OzyCp4OU738mKCea0KY0Vcos/tJjG+I8yT6n3KQl4KyETGY3T8wmmYJfejBJioMOqaCRuG6X4Rn5/SMdQ7fOECkvRzMrb8BbxzJYLUHKWb+Vk8WW5AWorbXdyrvV5yYTySthhhsuaj12fLp+SFTqbP8A5+xe2ijAcrgWi8VLhrx7aU/Wq2XTNJEm4lOq3W9OEIL5ncqfcYZOlb2MQa3c7axBcDF3JWs+irmk3ymi1E=" >> "/home/$ADMIN_USER/.ssh/authorized_keys"
chown "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh/authorized_keys"
chmod 600 "/home/$ADMIN_USER/.ssh/authorized_keys"

# Install Docker (optional but commonly needed)
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add admin user to docker group
if [ "$ADMIN_USER" != "root" ]; then
    usermod -aG docker "$ADMIN_USER"
fi

# Start and enable Docker
systemctl enable docker
systemctl start docker

# Install Docker Compose (standalone)
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js (LTS)
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# Install additional useful tools
echo "Installing additional tools..."
# Install Terraform CLI
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com releases main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws

# Configure timezone
echo "Configuring timezone..."
timedatectl set-timezone UTC

# Create useful directories
echo "Creating useful directories..."
mkdir -p /opt/applications
mkdir -p /var/log/applications
chown -R "$ADMIN_USER:$ADMIN_USER" /opt/applications /var/log/applications

# Set up automatic security updates
echo "Configuring automatic security updates..."
apt-get install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades

# Create a welcome message
cat > /etc/motd << 'EOF'
=====================================
 Welcome to Terraform-managed Contabo VPS
=====================================
This server was provisioned and configured using Terraform.

Quick commands:
- Check system status: systemctl status
- View logs: journalctl -f
- Check Docker: docker ps
- Monitor resources: htop

Documentation and support:
- Terraform: https://terraform.io/docs
- Contabo: https://contabo.com/support
=====================================
EOF

# Clean up
echo "Cleaning up..."
apt-get autoremove -y
apt-get autoclean

# Create a status file to indicate initialization is complete
echo "SUCCESS: $(date)" > /var/log/terraform-init-status
chown "$ADMIN_USER:$ADMIN_USER" /var/log/terraform-init-status

echo "=== Terraform Contabo VPS Setup Completed Successfully ==="
echo "Date: $(date)"
echo "Log file: $LOG_FILE"

# Reboot to ensure all changes take effect (optional)
# echo "Rebooting system in 1 minute..."
# shutdown -r +1 "System will reboot in 1 minute to complete initialization" 