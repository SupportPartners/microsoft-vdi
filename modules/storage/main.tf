resource "azurerm_storage_account" "standard-storage-account" {
  name                     = "ss${var.storage_name}${var.deployment_index}"
  count                    = var.is_premium_storage == true ? 0 : 1
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
}

resource "azurerm_storage_account" "premium-storage-account" {
  name                     = "ss${var.storage_name}${var.deployment_index}"
  count                    = var.is_premium_storage == true ? 1 : 0
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
}

locals {
  storage = var.is_premium_storage ? azurerm_storage_account.premium-storage-account : azurerm_storage_account.standard-storage-account
}

resource "azurerm_storage_share" "file-share" {
  name                 = "file-share"
  storage_account_name = local.storage[0].name

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
