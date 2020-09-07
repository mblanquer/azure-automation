variable "location" {
  description = "RG and resources location"
  type = string
  default = "francecentral"
}
variable "tags" {
  description = "Tags to apply on RG and Resources"
  type = map
}
variable "windows_vms" {
  description = "Linux VMs list and configuration"
  type        = any
}
variable "bastion_subnetAddressSpace" {
  description = "Azure bastion subnet address space"
  type = list(string)
}
variable "nsg_security_rules" {
  type = any
}
variable "admin_password" {
  type = string
}