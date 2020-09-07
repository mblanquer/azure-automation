location = "francecentral"
tags = {
    "env" = "dev"
}

windows_vms = {
      vm1 = {
        suffix_name          = "vm"           
        id                   = "1"            
        storage_data_disks   = []             
        Id_Subnet            = "0"
        nsg_key              = null
        static_ip            = "10.0.0.14"
        enable_accelerated_networking = false
        enable_ip_forwarding          = false
        vm_size              = "Standard_DS2_v2"
        managed_disk_type    = "Premium_LRS"
      }
  }

admin_password = "####"

bastion_subnetAddressSpace = ["10.0.1.0/26"]

nsg_security_rules = {
        RDP = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "3389"
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "VirtualNetwork"
        }
        DenyAll = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
}
