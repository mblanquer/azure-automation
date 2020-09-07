variable "wk_name" {}
variable "wk_location" {
  type        = string
  default     = ""
}
variable "rg_name" {}
variable "wk_tags" {
  type = map
}
variable "wk_sku" {}
variable "wk_retention" {}
