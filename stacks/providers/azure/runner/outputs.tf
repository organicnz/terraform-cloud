# Runner instance details
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.runner.name
}

output "private_ip_address" {
  value = azurerm_network_interface.nic.private_ip_address
}

# There is no public IP by design — the runner polls GitHub outbound.
# To reach the box, add a public IP to the NIC or use a Bastion/jump host.
output "public_ip_address" {
  value = "none - runner is outbound-only by design"
}
