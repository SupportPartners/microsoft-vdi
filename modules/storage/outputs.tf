output "storage_account" {
  value = local.storage[0].name
}

output "storage_container" {
  value = azurerm_storage_share.file-share.name
}

output "storage_access_key" {
  value = local.storage[0].primary_access_key
}

output "diag_storage_blob_endpoint" {
  value = azurerm_storage_account.diagnostic-storage-account.primary_blob_endpoint
}