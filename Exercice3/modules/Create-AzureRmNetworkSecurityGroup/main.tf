resource "azurerm_network_security_group" "nsg" {
  name =     var.nsg_name
  location = var.nsg_location
  tags =     var.nsg_tags
  resource_group_name = var.rg_name
}

resource "azurerm_network_security_rule" "nsg_sr" {
  for_each = var.nsg_security_rules
  name                      = each.key
  priority                  = each.value.priority
  direction                 = each.value.direction
  access                    = each.value.access
  protocol                  = each.value.protocol
  source_port_range         = lookup(each.value, "source_port_range", null)
  source_port_ranges        = lookup(each.value, "source_port_ranges", null)
  destination_port_range    = lookup(each.value, "destination_port_range", null)
  destination_port_ranges    = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes   = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes   = lookup(each.value, "destination_address_prefixes", null)
  resource_group_name    = var.rg_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}