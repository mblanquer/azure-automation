variable "rg_name" {}
variable "vnet_name" {}
variable "vnet_location" {}
variable "vnet_tags" {
  type = map
}
variable "nsg_security_rules" {
  type = any
}