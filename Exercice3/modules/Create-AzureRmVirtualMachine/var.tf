variable "sa_bootdiag_storage_uri" {
  type        = string
  description = "Azure Storage Account Primary Queue Service Endpoint."
}

variable "linux_storage_image_reference" {
  type        = map(string)
  description = "Could containt an 'id' of a custom image or the following parameters for an Azure public 'image publisher','offer','sku', 'version'"
  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "Latest"
  }
}

variable "linux_vms" {
  description = "Linux VMs list."
  type        = any
  default = {}
}

variable "windows_vms" {
 description = "Windows VMs list."
 type        = any
 default = {}
}

variable "windows_storage_image_reference" {
  type        = map(string)
  description = "Could containt an 'id' of a custom image or the following parameters for an Azure public 'image publisher','offer','sku', 'version'"
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "Latest"
  }
}

variable "vm_location" {
  description = "VM's location if different that the resource group's location."
  type        = string
  default     = ""
}

variable "rg_name" {
  description = "VM's resource group name."
}

variable "vm_prefix" {
  description = "Prefix used for the VM, Disk and Nic names."
  default     = ""
}

variable "vm_tags" {
  description = "Tags pushed on the VM, Disk and Nic in addition to the resource group tags."
  type        = map(string)
}

variable "admin_username" {
  description = "Specifies the name of the local administrator account."
  default     = ""
}

variable "admin_password" {
  description = "The password associated with the local administrator account."
  default     = ""
}

variable "ssh_key" {
  description = "(Optional) One or more ssh_keys blocks. This field is required if disable_password_authentication is set to true."
  default     = "ssh-rsa XXXX rsa-key-20200516"
}

variable "enable_log_analytics_dependencies" {
  description = "Decide to disable log analytics dependencies"
  default     = false
}

variable "workspace_name" {
  description = "Log Analytics workspace name."
  default     = ""
}

variable "workspace_rgname" {
  description = "Log Analytics workspace resource group name, use the context's RG if not provided."
  default     = ""
}

variable "OmsAgentForLinux" {
  type = map(string)
  default = {
    publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
    type                       = "OmsAgentForLinux"
    type_handler_version       = "1.11" #https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/oms-linux
    auto_upgrade_minor_version = "true"
  }
}

variable "DependencyAgentLinux" {
  type = map(string)
  default = {
    publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
    type                       = "DependencyAgentLinux"
    type_handler_version       = "9.5"
    auto_upgrade_minor_version = "true"
  }
}

variable "DependencyAgentWindows" {
  type = map(string)
  default = {
    publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
    type                       = "DependencyAgentWindows"
    type_handler_version       = "9.5"
    auto_upgrade_minor_version = "true"
  }
}

variable "OmsAgentForWindows" {
  type = map(string)
  default = {
    publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
    type                       = "MicrosoftMonitoringAgent"
    type_handler_version       = "1.0" #https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/oms-windows
    auto_upgrade_minor_version = "true"
  }
}

variable "subnet_id" {}

variable "public_ips" {
  description = "A map of Public Ips containing their 'id'."
  type        = any
  default     = {}
}