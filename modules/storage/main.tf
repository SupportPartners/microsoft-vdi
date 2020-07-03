resource "azurerm_storage_account" "storage-account" {
  name                     = "ss${var.storage_name}${var.deployment_index}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.is_premium_storage == true ? "Premium": "Standard"
  account_replication_type = "LRS"
  account_kind             = var.is_premium_storage == true ? "FileStorage" : "StorageV2"
  access_tier              = "Hot"
  tags                     = "${merge(
    var.tags,
    map("Type", "Storage")
  )}"
}

resource "azurerm_storage_share" "file-share" {
  name                 = "demo-file-share"
  storage_account_name =  azurerm_storage_account.storage-account.name

  quota = var.file_share_quota
}

resource "azurerm_storage_account" "diagnostic-storage-account" {
  name                     = "stdiag${var.diag_storage_name}${var.deployment_index}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
}
