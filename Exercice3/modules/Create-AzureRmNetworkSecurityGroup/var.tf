variable "rg_name" {}
variable "nsg_name" {}
variable "nsg_location" {}
variable "nsg_tags" {
  type = map
}
variable "nsg_security_rules" {
  type = any
}