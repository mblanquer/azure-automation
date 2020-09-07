locals {
  suffixNSG = "nsg"
}

resource "azurerm_virtual_network" "virtualnetwork" {
  name =     var.vnet_name
  location = var.vnet_location
  tags =     var.vnet_tags
  resource_group_name = var.rg_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnetVMs" {
  name                 = "VMs"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.virtualnetwork.name
  address_prefixes       = ["10.0.0.0/26"]
}

module "Create-AzureRmNetworkSecurityGroup" {
  source        = "../Create-AzureRmNetworkSecurityGroup"
  rg_name       = var.rg_name
  nsg_name   = lower("${var.vnet_name}${azurerm_subnet.subnetVMs.name}${local.suffixNSG}")
  nsg_location = var.vnet_location
  nsg_tags     = var.vnet_tags
  nsg_security_rules = var.nsg_security_rules
}

resource "azurerm_subnet_network_security_group_association" "subnetVMs-nsg" {
  subnet_id                 = azurerm_subnet.subnetVMs.id
  network_security_group_id = module.Create-AzureRmNetworkSecurityGroup.nsg_id
}