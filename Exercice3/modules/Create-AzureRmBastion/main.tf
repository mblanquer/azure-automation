data "azurerm_resource_group" "bastion" {
  name = var.rg_name
}

locals {
  location             = var.bastion_location == "" ? data.azurerm_resource_group.bastion.location : var.bastion_location
  suffixPublicIP = "pip"
}

resource "azurerm_subnet" "bastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.bastion_vnet_rg_name
  virtual_network_name = var.bastion_vnet_name
  address_prefixes       = var.bastion_subnetAddressSpace
}

resource "azurerm_public_ip" "bastionPublicIp" {
  name                = "${var.bastion_name}${local.suffixPublicIP}"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.bastion.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name =     var.bastion_name
  location = local.location
  tags =     var.bastion_tags
  resource_group_name = data.azurerm_resource_group.bastion.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastionPublicIp.id
  }
}
