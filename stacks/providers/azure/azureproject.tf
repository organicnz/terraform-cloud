# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix}-rg"
  location = var.location

  tags = {
    environment = "production"
    project     = var.resource_prefix
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "production"
    project     = var.resource_prefix
  }
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP address
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.resource_prefix}-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = replace(var.resource_prefix, "_", "-")

  tags = {
    environment = "production"
    project     = var.resource_prefix
  }
}

# Create a network interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.resource_prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.resource_prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

  tags = {
    environment = "production"
    project     = var.resource_prefix
  }
}

# # Create a network security group
# resource "azurerm_network_security_group" "nsg" {
#   name                = "${var.resource_prefix}-nsg"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   security_rule {
#     name                       = "SSH"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   tags = {
#     environment = "production"
#     project     = var.resource_prefix
#   }
# }

# # Associate the NSG with the subnet
# resource "azurerm_subnet_network_security_group_association" "nsg_association" {
#   subnet_id                 = azurerm_subnet.subnet.id
#   network_security_group_id = azurerm_network_security_group.nsg.id
# }

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.instance_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = var.vm_size

  os_disk {
    name                 = "${var.resource_prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    # Ubuntu 24.04 LTS
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"

    # Ubuntu 22.04 LTS
    # publisher = "Canonical"
    # offer     = "0001-com-ubuntu-server-jammy"
    # sku       = "22_04-lts"
    # version   = "latest"

    # Debian 12 
    # publisher = "Debian"
    # offer     = "debian-12"
    # sku       = "12"
    # version   = "latest"
  }

  computer_name  = replace(var.instance_name, "_", "-")
  admin_username = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.key_data
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo apt update",
  #     "sudo apt full-upgrade -y",
  #     "sudo apt autoremove -y",
  #     "apt-get install -y ufw",
  #     "ufw default deny incoming",
  #     "ufw default allow outgoing",
  #     "ufw allow 22/tcp",
  #     "ufw allow 80/tcp",
  #     "ufw allow 443/tcp",
  #     "ufw allow 2053/tcp",
  #     "ufw allow 2053/udp",
  #     "ufw --force enable",
  #     "sudo reboot"
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = var.admin_username
  #     host        = azurerm_public_ip.public_ip.ip_address
  #     private_key = file("~/.ssh/azure_id_rsa.pem")  # Ensure this key is not passphrase protected
  #   }
  # }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get full-upgrade -y
    apt-get autoremove -y
    apt-get install -y ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 2053/tcp
    ufw allow 2053/udp
    ufw --force enable
    reboot
    EOF
  )

  tags = {
    environment = "production"
    project     = var.resource_prefix
  }
}

# Output the public IP address
output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

# Output the VM name
output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

# Output the resource group name
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}