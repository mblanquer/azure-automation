data "azurerm_resource_group" "vm" {
  name = var.rg_name
}

data "azurerm_log_analytics_workspace" "log" {
  count               = var.workspace_name == "" ? 0 : 1
  name                = var.workspace_name
  resource_group_name = var.workspace_rgname == "" ? var.rg_name : var.workspace_rgname
}

locals {
  tags                 = var.vm_tags
  location             = var.vm_location == "" ? data.azurerm_resource_group.vm.location : var.vm_location
}

resource "azurerm_log_analytics_solution" "ServiceMap" {
  count                 = var.workspace_name == "" ? 0 : 1
  solution_name         = "ServiceMap"
  location              = element(data.azurerm_log_analytics_workspace.log.*.location, 0)
  resource_group_name   = element(data.azurerm_log_analytics_workspace.log.*.resource_group_name, 0)
  workspace_resource_id = element(data.azurerm_log_analytics_workspace.log.*.id, 0)
  workspace_name        = element(data.azurerm_log_analytics_workspace.log.*.name, 0)
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ServiceMap"
  }
}

locals {
  linux_vms_with_log_analytics_dependencies_keys   = [for x in var.linux_vms : "${x.suffix_name}${x.id}" if var.enable_log_analytics_dependencies == true]
  linux_vms_with_log_analytics_dependencies_values = [for x in var.linux_vms : { enable_log_analytics_dependencies = var.enable_log_analytics_dependencies } if var.enable_log_analytics_dependencies == true]
  linux_vms_with_log_analytics_dependencies        = zipmap(local.linux_vms_with_log_analytics_dependencies_keys, local.linux_vms_with_log_analytics_dependencies_values)
}

resource "azurerm_virtual_machine_extension" "OmsAgentForLinux" {
  depends_on                 = [azurerm_log_analytics_solution.ServiceMap]
  for_each                   = local.linux_vms_with_log_analytics_dependencies
  name                       = "OmsAgentForLinux"
  virtual_machine_id         = [for x in azurerm_virtual_machine.linux_vms : x.id if x.name == "${var.vm_prefix}${each.key}"][0]
  publisher                  = var.OmsAgentForLinux["publisher"]
  type                       = var.OmsAgentForLinux["type"]
  type_handler_version       = var.OmsAgentForLinux["type_handler_version"]
  auto_upgrade_minor_version = var.OmsAgentForLinux["auto_upgrade_minor_version"]
  tags                       = local.tags
  settings                   = <<-BASE_SETTINGS
 {
   "workspaceId" : "${element(data.azurerm_log_analytics_workspace.log.*.workspace_id, 0)}"
 }
BASE_SETTINGS
  protected_settings         = <<-PROTECTED_SETTINGS
 {
   "workspaceKey" : "${element(data.azurerm_log_analytics_workspace.log.*.primary_shared_key, 0)}"
 }
PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine_extension" "DependencyAgentLinux" {
  depends_on                 = [azurerm_virtual_machine_extension.OmsAgentForLinux]
  for_each                   = local.linux_vms_with_log_analytics_dependencies
  name                       = "DependencyAgent"
  virtual_machine_id         = [for x in azurerm_virtual_machine.linux_vms : x.id if x.name == "${var.vm_prefix}${each.key}"][0]
  publisher                  = var.DependencyAgentLinux["publisher"]
  type                       = var.DependencyAgentLinux["type"]
  type_handler_version       = var.DependencyAgentLinux["type_handler_version"]
  auto_upgrade_minor_version = var.DependencyAgentLinux["auto_upgrade_minor_version"]
  tags                       = local.tags
}

resource "azurerm_network_interface" "linux_nics" {
  for_each                      = var.linux_vms
  name                          = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}nic1"
  location                     = local.location
  resource_group_name           = var.rg_name
  internal_dns_name_label       = lookup(each.value, "internal_dns_name_label", null)
  enable_ip_forwarding          = lookup(each.value, "enable_ip_forwarding", null)
  enable_accelerated_networking = lookup(each.value, "enable_accelerated_networking", null)
  dns_servers                   = lookup(each.value, "dns_servers", null)

  ip_configuration {
    name                          = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}nic1-CFG"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = lookup(each.value, "static_ip", null) == null ? "dynamic" : "static"
    private_ip_address            = lookup(each.value, "static_ip", null)
    public_ip_address_id          = lookup(each.value, "public_ip_key", null) == null ? null : lookup(var.public_ips, each.value["public_ip_key"], null)["id"]
  }

  tags = local.tags
}

resource "azurerm_virtual_machine" "linux_vms" {
  for_each                         = var.linux_vms
  name                             = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}"
  location                         = local.location
  resource_group_name              = var.rg_name
  network_interface_ids            = [lookup(azurerm_network_interface.linux_nics, each.key)["id"]]
  zones                            = lookup(each.value, "zones", null)
  vm_size                          = each.value["vm_size"]
  delete_os_disk_on_termination    = lookup(each.value, "delete_os_disk_on_termination", true)
  delete_data_disks_on_termination = lookup(each.value, "delete_data_disks_on_termination", true)
 
  os_profile_linux_config {
    disable_password_authentication = lookup(each.value, "disable_password_authentication", false)

    ssh_keys {
      path     = "/home/${lookup(each.value, "admin_username", var.admin_username)}/.ssh/authorized_keys"
      key_data = var.ssh_key
    }
  }

  storage_os_disk {
    name              = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}osdk"
    caching           = lookup(each.value, "storage_os_disk_caching", "ReadWrite")
    create_option     = lookup(each.value, "storage_os_disk_create_option", "FromImage")
    managed_disk_type = each.value["managed_disk_type"]
  }


  storage_image_reference {
    id        = lookup(each.value, "storage_image_reference_id", lookup(var.linux_storage_image_reference, "id", null))
    offer     = lookup(each.value, "storage_image_reference_offer", lookup(var.linux_storage_image_reference, "offer", null))
    publisher = lookup(each.value, "storage_image_reference_publisher", lookup(var.linux_storage_image_reference, "publisher", null))
    sku       = lookup(each.value, "storage_image_reference_sku", lookup(var.linux_storage_image_reference, "sku", null))
    version   = lookup(each.value, "storage_image_reference_version", lookup(var.linux_storage_image_reference, "version", null))
  }

  dynamic "storage_data_disk" {
    for_each = lookup(each.value, "storage_data_disks", null)

    content {
      name                      = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}dd${lookup(storage_data_disk.value, "id", "null")}"
      caching                   = lookup(storage_data_disk.value, "caching", null)
      create_option             = lookup(storage_data_disk.value, "create_option", null)
      disk_size_gb              = lookup(storage_data_disk.value, "disk_size_gb", null)
      lun                       = lookup(storage_data_disk.value, "lun", lookup(var.linux_storage_image_reference, "lun", lookup(storage_data_disk.value, "id", "null")))
      write_accelerator_enabled = lookup(storage_data_disk.value, "write_accelerator_enabled", null)
      managed_disk_type         = lookup(storage_data_disk.value, "managed_disk_type", null)
      managed_disk_id           = lookup(storage_data_disk.value, "managed_disk_id", null)
    }
  }

  os_profile {
    computer_name  = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}"
    admin_username = lookup(each.value, "admin_username", var.admin_username)
    admin_password = lookup(each.value, "admin_password", var.admin_password)
  }

  tags = local.tags
}

locals {
  windows_vms_with_log_analytics_dependencies_keys   = [for x in var.windows_vms : "${x.suffix_name}${x.id}" if var.enable_log_analytics_dependencies == true]
  windows_vms_with_log_analytics_dependencies_values = [for x in var.windows_vms : { enable_log_analytics_dependencies = var.enable_log_analytics_dependencies } if var.enable_log_analytics_dependencies == true]
  windows_vms_with_log_analytics_dependencies        = zipmap(local.windows_vms_with_log_analytics_dependencies_keys, local.windows_vms_with_log_analytics_dependencies_values)
}

resource "azurerm_virtual_machine_extension" "OmsAgentForWindows" {
  depends_on                 = [azurerm_log_analytics_solution.ServiceMap]
  for_each                   = local.windows_vms_with_log_analytics_dependencies
  name                       = "OmsAgentForWindows"
  virtual_machine_id         = [for x in azurerm_virtual_machine.windows_vms : x.id if x.name == "${var.vm_prefix}${each.key}"][0]
  publisher                  = var.OmsAgentForWindows["publisher"]
  type                       = var.OmsAgentForWindows["type"]
  type_handler_version       = var.OmsAgentForWindows["type_handler_version"]
  auto_upgrade_minor_version = var.OmsAgentForWindows["auto_upgrade_minor_version"]
  tags                       = local.tags
  settings                   = <<-BASE_SETTINGS
 {
   "workspaceId" : "${element(data.azurerm_log_analytics_workspace.log.*.workspace_id, 0)}"
 }
BASE_SETTINGS
  protected_settings         = <<-PROTECTED_SETTINGS
 {
   "workspaceKey" : "${element(data.azurerm_log_analytics_workspace.log.*.primary_shared_key, 0)}"
 }
PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine_extension" "DependencyAgentWindows" {
  depends_on                 = [azurerm_virtual_machine_extension.OmsAgentForWindows]
  for_each                   = local.windows_vms_with_log_analytics_dependencies
  name                       = "DependencyAgent"
  virtual_machine_id         = [for x in azurerm_virtual_machine.windows_vms : x.id if x.name == "${var.vm_prefix}${each.key}"][0]
  publisher                  = var.DependencyAgentWindows["publisher"]
  type                       = var.DependencyAgentWindows["type"]
  type_handler_version       = var.DependencyAgentWindows["type_handler_version"]
  auto_upgrade_minor_version = var.DependencyAgentWindows["auto_upgrade_minor_version"]
  tags                       = local.tags
}

resource "azurerm_network_interface" "windows_nics" {
  for_each                      = var.windows_vms
  name                          = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}nic1"
  location                      = local.location
  resource_group_name           = var.rg_name
  internal_dns_name_label       = lookup(each.value, "internal_dns_name_label", null)
  enable_ip_forwarding          = lookup(each.value, "enable_ip_forwarding", null)
  enable_accelerated_networking = lookup(each.value, "enable_accelerated_networking", null)
  dns_servers                   = lookup(each.value, "dns_servers", null)

  ip_configuration {
    name                          = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}nic1-CFG"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = lookup(each.value, "static_ip", null) == null ? "dynamic" : "static"
    private_ip_address            = lookup(each.value, "static_ip", null)
    public_ip_address_id          = lookup(each.value, "public_ip_key", null) == null ? null : lookup(var.public_ips, each.value["public_ip_key"], null)["id"]
  }

  tags = local.tags
}

resource "azurerm_virtual_machine" "windows_vms" {
  for_each                         = var.windows_vms
  name                             = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}"
  location                         = local.location
  resource_group_name              = var.rg_name
  network_interface_ids            = [lookup(azurerm_network_interface.windows_nics, each.key)["id"]]
  zones                            = lookup(each.value, "zones", null)
  vm_size                          = each.value["vm_size"]
  license_type                     = lookup(each.value, "license_type", null) # (Optional) Specifies the BYOL Type for this Virtual Machine. This is only applicable to Windows Virtual Machines. Possible values are Windows_Client and Windows_Server.
  delete_os_disk_on_termination    = lookup(each.value, "delete_os_disk_on_termination", true)
  delete_data_disks_on_termination = lookup(each.value, "delete_data_disks_on_termination", true)

  os_profile_windows_config {
    provision_vm_agent        = lookup(each.value, "provision_vm_agent", true)
    enable_automatic_upgrades = lookup(each.value, "enable_automatic_upgrades", true)
  }

  storage_os_disk {
    name              = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}osdk"
    caching           = lookup(each.value, "storage_os_disk_caching", "ReadWrite")
    create_option     = lookup(each.value, "storage_os_disk_create_option", "FromImage")
    managed_disk_type = each.value["managed_disk_type"]
  }

  storage_image_reference {
    id        = lookup(each.value, "storage_image_reference_id", lookup(var.windows_storage_image_reference, "id", null))
    offer     = lookup(each.value, "storage_image_reference_offer", lookup(var.windows_storage_image_reference, "offer", null))
    publisher = lookup(each.value, "storage_image_reference_publisher", lookup(var.windows_storage_image_reference, "publisher", null))
    sku       = lookup(each.value, "storage_image_reference_sku", lookup(var.windows_storage_image_reference, "sku", null))
    version   = lookup(each.value, "storage_image_reference_version", lookup(var.windows_storage_image_reference, "version", null))
  }

  dynamic "storage_data_disk" {
    for_each = lookup(each.value, "storage_data_disks", null)

    content {
      name                      = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}dd${lookup(storage_data_disk.value, "lun", "null")}"
      caching                   = lookup(storage_data_disk.value, "caching", null)
      create_option             = lookup(storage_data_disk.value, "create_option", null)
      disk_size_gb              = lookup(storage_data_disk.value, "disk_size_gb", null)
      lun                       = lookup(storage_data_disk.value, "lun", lookup(var.windows_storage_image_reference, "lun", lookup(storage_data_disk.value, "id", "null")))
      write_accelerator_enabled = lookup(storage_data_disk.value, "write_accelerator_enabled", null)
      managed_disk_type         = lookup(storage_data_disk.value, "managed_disk_type", null)
      managed_disk_id           = lookup(storage_data_disk.value, "managed_disk_id", null)
    }
  }

  os_profile {
    computer_name  = "${var.vm_prefix}${each.value["suffix_name"]}${each.value["id"]}"
    admin_username = lookup(each.value, "admin_username", var.admin_username)
    admin_password = lookup(each.value, "admin_password", var.admin_password)
  }

  tags = local.tags
}