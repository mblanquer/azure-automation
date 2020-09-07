data "azurerm_resource_group" "workspace" {
  name = var.rg_name
}

locals {
  location             = var.wk_location == "" ? data.azurerm_resource_group.workspace.location : var.wk_location
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name =     var.wk_name
  location = local.location
  tags =     var.wk_tags
  resource_group_name = var.rg_name
  sku                 = var.wk_sku
  retention_in_days   = var.wk_retention
}
