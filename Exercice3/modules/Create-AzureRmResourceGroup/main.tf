resource "azurerm_resource_group" "resourcegroup" {
  name =     var.rg_name
  location = var.rg_location
  tags =     var.rg_tags
}
