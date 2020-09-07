data "azurerm_client_config" "current" {}

# Variables locales
locals {
  tags = merge(var.tags, {
    project = "dojoazure"
    user = "us10"
    exercice = "ex03"
    deployment  = "terraform"
  })
  prefix = "dojo"
  subject = "azure"
  rg_name = "${local.prefix}${local.subject}"
  suffixSA = "sa"
  suffixRG = "rg"
  suffixWK = "wk"
  suffixSQL = "sql"
  suffixBastion = "bst"
  suffixVNET = "vnet"
  suffixPublicIp = "pip"
  index = "03"
  userid = "us10"
}

# Ressource Group
module "Create-AzureRmResourceGroup" {
  source      = "../../modules/Create-AzureRmResourceGroup"
  rg_name     = "${local.rg_name}-${local.userid}-ex${local.index}"
  rg_location = var.location
  rg_tags     = local.tags
}

# Storage account - Diagnostic logs
module "Create-AzureRmStorageAccount" {
  source                      = "../../modules/Create-AzureRmStorageAccount"
  rg_name                     = "${module.Create-AzureRmResourceGroup.rg_name}"
  sa_name                     = "${local.prefix}${local.subject}${local.suffixSA}${local.index}"
  sa_location                 = var.location
  sa_account_replication_type = "LRS"
  sa_account_tier             = "Standard"
  sa_tags                     = local.tags
}

# Virtual Network
module "Create-AzureRmVirtualNetwork" {
  source        = "../../modules/Create-AzureRmVirtualNetwork"
  rg_name       = "${module.Create-AzureRmResourceGroup.rg_name}"
  vnet_name   = "${local.prefix}${local.subject}${local.suffixVNET}${local.index}"
  vnet_location = var.location
  vnet_tags     = local.tags
  nsg_security_rules = var.nsg_security_rules
}

# Workspace Log Analytics
# module "Create-AzureRmLogAnalyticsWorkspace" {
#   depends_on = [module.Create-AzureRmResourceGroup]
#   source        = "../../modules/Create-AzureRmLogAnalyticsWorkspace"
#   rg_name       = "${module.Create-AzureRmResourceGroup.rg_name}"
#   wk_name       = "${local.prefix}${local.subject}${local.userid}${local.suffixWK}${local.index}"
#   wk_tags       = local.tags
#   wk_sku        = "PerGB2018"
#   wk_retention  = 30
# }

# Virtual Machine
module "Create-AzureRmVirtualMachine" {
  # depends_on = [module.Create-AzureRmLogAnalyticsWorkspace]
  source                            = "../../modules/Create-AzureRmVirtualMachine"
  rg_name                           = "${module.Create-AzureRmResourceGroup.rg_name}"
  sa_bootdiag_storage_uri           = "${module.Create-AzureRmStorageAccount.sa_primary_blob_endpoints[0]}"
  windows_vms                       = var.windows_vms
  vm_prefix                         = "${local.prefix}${local.subject}"
  admin_username                    = "adminvm"
  admin_password                    = var.admin_password
  vm_tags                           = local.tags
  subnet_id                         = "${module.Create-AzureRmVirtualNetwork.subnet_VMs_Id}"
  enable_log_analytics_dependencies = false
  # workspace_name                    = "${module.Create-AzureRmLogAnalyticsWorkspace.wk_name}"
}

# Azure Bastion
# module "Create-AzureRmBastion" {
#   depends_on = [module.Create-AzureRmResourceGroup]
#   source                      = "../../modules/Create-AzureRmBastion"
#   rg_name                     = "${module.Create-AzureRmResourceGroup.rg_name}"
#   bastion_name = "${local.prefix}${local.subject}${local.suffixBastion}${local.index}"
#   bastion_vnet_name = "${module.Create-AzureRmVirtualNetwork.vnet_name}"
#   bastion_vnet_rg_name = "${module.Create-AzureRmVirtualNetwork.vnet_rg_name}"
#   bastion_subnetAddressSpace = var.bastion_subnetAddressSpace
#   bastion_tags                     = local.tags
# }