output "sa_names" {
  value = "${azurerm_storage_account.storageaccount.*.name}"
}

output "sa_rgs" {
  value = "${azurerm_storage_account.storageaccount.*.resource_group_name}"
}

output "sa_ids" {
  value = "${azurerm_storage_account.storageaccount.*.id}"
}

output "sa_primary_blob_endpoints" {
  value = "${azurerm_storage_account.storageaccount.*.primary_blob_endpoint}"
}
