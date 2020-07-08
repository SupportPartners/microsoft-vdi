terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  version = "=2.2.0"

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.sp_tenant_id

  features {}
}

provider "restapi" {
  version = "1.13.0-windows-amd64"
  uri                  = "https://cam.teradici.com/api/v1/"
  debug                = true
  write_returns_object = true
  headers              = {
    Content-Type       = "application/json"
    Authorization      = "${var.cam_service_token}"
  }
}