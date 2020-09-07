variable "bastion_name" {}
variable "bastion_location" {
  type        = string
  default     = ""
}
variable "rg_name" {}
variable "bastion_tags" {
  type = map
}
variable "bastion_vnet_name" {}
variable "bastion_vnet_rg_name" {}
variable "bastion_subnetAddressSpace" {}
