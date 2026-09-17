# Resource Groups
resource "azurerm_resource_group" "vpsgermany_rg" {
  name     = "vpsgermany-rg"
  location = "germanywestcentral"
}

resource "azurerm_resource_group" "xuigermany_rg" {
  name     = "xuigermany-rg"
  location = "germanywestcentral"
}

resource "azurerm_resource_group" "vpn_service_rg" {
  name     = "vpn_service-rg"
  location = "germanywestcentral"
}

resource "azurerm_resource_group" "foodshare_rg" {
  name     = "foodshare-resource-group"
  location = "polandcentral"
}

resource "azurerm_resource_group" "web_rg" {
  name     = "web-resource-group"
  location = "polandcentral"
}

resource "azurerm_resource_group" "monitoring_rg" {
  name     = "monitoring-resource-group-west-us"
  location = "westus"
}

resource "azurerm_resource_group" "vpswest_rg" {
  name     = "vpswest_resource_group"
  location = "westus"
}

resource "azurerm_resource_group" "newvps_rg" {
  name     = "newvps_resource_group"
  location = "westus"
}

resource "azurerm_resource_group" "vpngermany_rg" {
  name     = "vpngermany_resource_group"
  location = "germanywestcentral"
}

resource "azurerm_resource_group" "the_latest_rg" {
  name     = "THE_LATEST_RESOURCE_GROUP"
  location = "eastus"
}

# Virtual Networks
resource "azurerm_virtual_network" "vpsgermany_vnet" {
  name                = "vpsgermany-vnet"
  address_space       = ["10.0.0.0/16"] # Default, will be updated with actual value during import
  location            = azurerm_resource_group.vpsgermany_rg.location
  resource_group_name = azurerm_resource_group.vpsgermany_rg.name
}

resource "azurerm_virtual_network" "xuigermany_vnet" {
  name                = "xuigermany-vnet"
  address_space       = ["10.0.0.0/16"] # Default, will be updated with actual value during import
  location            = azurerm_resource_group.xuigermany_rg.location
  resource_group_name = azurerm_resource_group.xuigermany_rg.name
}

resource "azurerm_virtual_network" "vpn_service_vnet" {
  name                = "vpn_service-vnet"
  address_space       = ["10.0.0.0/16"] # Default, will be updated with actual value during import
  location            = azurerm_resource_group.vpn_service_rg.location
  resource_group_name = azurerm_resource_group.vpn_service_rg.name
}

resource "azurerm_virtual_network" "foodshare_network" {
  name                = "foodshare-network"
  address_space       = ["10.0.0.0/16"] # Default, will be updated with actual value during import
  location            = azurerm_resource_group.foodshare_rg.location
  resource_group_name = azurerm_resource_group.foodshare_rg.name
}

resource "azurerm_virtual_network" "web_network" {
  name                = "web-network"
  address_space       = ["10.0.0.0/16"] # Default, will be updated with actual value during import
  location            = azurerm_resource_group.web_rg.location
  resource_group_name = azurerm_resource_group.web_rg.name
}

# Public IPs
resource "azurerm_public_ip" "vpsgermany_public_ip" {
  name                = "vpsgermany-public-ip"
  location            = azurerm_resource_group.vpsgermany_rg.location
  resource_group_name = azurerm_resource_group.vpsgermany_rg.name
  allocation_method   = "Static" # Default, will be updated with actual value during import
}

resource "azurerm_public_ip" "xuigermany_public_ip" {
  name                = "xuigermany-public-ip"
  location            = azurerm_resource_group.xuigermany_rg.location
  resource_group_name = azurerm_resource_group.xuigermany_rg.name
  allocation_method   = "Static" # Default, will be updated with actual value during import
}

resource "azurerm_public_ip" "vpn_service_public_ip" {
  name                = "vpn_service-public-ip"
  location            = azurerm_resource_group.vpn_service_rg.location
  resource_group_name = azurerm_resource_group.vpn_service_rg.name
  allocation_method   = "Static" # Default, will be updated with actual value during import
}

# Network Interfaces
resource "azurerm_network_interface" "vpsgermany_nic" {
  name                = "vpsgermany-nic"
  location            = azurerm_resource_group.vpsgermany_rg.location
  resource_group_name = azurerm_resource_group.vpsgermany_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_virtual_network.vpsgermany_vnet.id}/subnets/default" # Will be updated during import
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpsgermany_public_ip.id
  }
}

resource "azurerm_network_interface" "xuigermany_nic" {
  name                = "xuigermany-nic"
  location            = azurerm_resource_group.xuigermany_rg.location
  resource_group_name = azurerm_resource_group.xuigermany_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_virtual_network.xuigermany_vnet.id}/subnets/default" # Will be updated during import
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.xuigermany_public_ip.id
  }
}

resource "azurerm_network_interface" "vpn_service_nic" {
  name                = "vpn_service-nic"
  location            = azurerm_resource_group.vpn_service_rg.location
  resource_group_name = azurerm_resource_group.vpn_service_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_virtual_network.vpn_service_vnet.id}/subnets/default" # Will be updated during import
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpn_service_public_ip.id
  }
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "vpsgermany_vm" {
  name                  = "vpsgermany"
  resource_group_name   = azurerm_resource_group.vpsgermany_rg.name
  location              = azurerm_resource_group.vpsgermany_rg.location
  size                  = "Standard_D2s_v3" # Will be updated during import
  admin_username        = "adminuser"       # Will be updated during import
  network_interface_ids = [azurerm_network_interface.vpsgermany_nic.id]

  # These will be populated during import
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Placeholder source_image_reference - will be updated during import
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "xuigermany_vm" {
  name                  = "xuigermany"
  resource_group_name   = azurerm_resource_group.xuigermany_rg.name
  location              = azurerm_resource_group.xuigermany_rg.location
  size                  = "Standard_D2s_v3" # Will be updated during import
  admin_username        = "adminuser"       # Will be updated during import
  network_interface_ids = [azurerm_network_interface.xuigermany_nic.id]

  # These will be populated during import
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Placeholder source_image_reference - will be updated during import
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "vpn_service_vm" {
  name                  = "vpn_service"
  resource_group_name   = azurerm_resource_group.vpn_service_rg.name
  location              = azurerm_resource_group.vpn_service_rg.location
  size                  = "Standard_D2s_v3" # Will be updated during import
  admin_username        = "adminuser"       # Will be updated during import
  network_interface_ids = [azurerm_network_interface.vpn_service_nic.id]

  # These will be populated during import
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Placeholder source_image_reference - will be updated during import
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Managed Disks
resource "azurerm_managed_disk" "vpsgermany_osdisk" {
  name                 = "vpsgermany-osdisk"
  location             = azurerm_resource_group.vpsgermany_rg.location
  resource_group_name  = "VPSGERMANY-RG" # Note: Resource group name may be different case
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30 # Will be updated during import
}

resource "azurerm_managed_disk" "xuigermany_osdisk" {
  name                 = "xuigermany-osdisk"
  location             = azurerm_resource_group.xuigermany_rg.location
  resource_group_name  = "XUIGERMANY-RG" # Note: Resource group name may be different case
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30 # Will be updated during import
}

resource "azurerm_managed_disk" "vpn_service_osdisk" {
  name                 = "vpn_service-osdisk"
  location             = azurerm_resource_group.vpn_service_rg.location
  resource_group_name  = "VPN_SERVICE-RG" # Note: Resource group name may be different case
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30 # Will be updated during import
}

# Bastion Hosts
resource "azurerm_bastion_host" "vpngermany_bastion" {
  name                = "vpngermany_network-bastion"
  location            = azurerm_resource_group.vpngermany_rg.location
  resource_group_name = azurerm_resource_group.vpngermany_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_virtual_network.vpsgermany_vnet.id}/subnets/AzureBastionSubnet" # Will be updated during import
    public_ip_address_id = azurerm_public_ip.vpsgermany_public_ip.id                                  # Will need to be updated to correct IP
  }
}

resource "azurerm_bastion_host" "web_bastion" {
  name                = "web-network-bastion"
  location            = azurerm_resource_group.web_rg.location
  resource_group_name = azurerm_resource_group.web_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_virtual_network.web_network.id}/subnets/AzureBastionSubnet" # Will be updated during import
    public_ip_address_id = azurerm_public_ip.vpsgermany_public_ip.id                              # Will need to be updated to correct IP
  }
}

resource "azurerm_bastion_host" "foodshare_bastion" {
  name                = "foodshare-network-bastion"
  location            = azurerm_resource_group.foodshare_rg.location
  resource_group_name = azurerm_resource_group.foodshare_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_virtual_network.foodshare_network.id}/subnets/AzureBastionSubnet" # Will be updated during import
    public_ip_address_id = azurerm_public_ip.vpsgermany_public_ip.id                                    # Will need to be updated to correct IP
  }
} 