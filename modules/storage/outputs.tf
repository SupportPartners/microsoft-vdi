output "storage_account" {
  value = azurerm_storage_account.storage-account.name
}

output "storage_container" {
  value = azurerm_storage_share.file-share.name
}

output "storage_access_key" {
  value = azurerm_storage_account.storage-account.primary_access_key
}

output "diag_storage_blob_endpoint" {
  value = azurerm_storage_account.diagnostic-storage-account.primary_blob_endpoint
}

output "storage_created" {
    value      = {}
    depends_on = [azurerm_storage_share.file-share]
}