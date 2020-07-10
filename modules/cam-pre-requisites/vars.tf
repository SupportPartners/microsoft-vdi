variable "subscription_id" {
  type        = string
}

variable "client_id" {
  type        = string
}

variable "client_secret" {
  type        = string
}

variable "tenant_id" {
  type        = string
}

variable "pcoip_registration_code" {
  type        = string
}

variable "dependency" {
}


locals {
  deployment_name = "vdi-automated-${lower(formatdate("MMMM-DD", timestamp()))}"
  connector_name  = "cac-${lower(formatdate("MMMM-DD", timestamp()))}"
}