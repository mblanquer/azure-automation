output "rg_name" {
  value = "${azurerm_resource_group.resourcegroup.name}"
}

output "rg_location" {
  value = "${azurerm_resource_group.resourcegroup.location}"
}

output "rg_tags_out" {
  value = "${azurerm_resource_group.resourcegroup.tags}"
}