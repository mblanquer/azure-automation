output "vnet_name" {
  value = "${azurerm_virtual_network.virtualnetwork.name}"
}

output "vnet_rg_name" {
  value = "${azurerm_virtual_network.virtualnetwork.resource_group_name}"
}

output "subnet_VMs_Id" {
  value = "${azurerm_subnet.subnetVMs.id}"
}

output "subnet" {
  value = "${azurerm_subnet.subnetVMs}"
}
