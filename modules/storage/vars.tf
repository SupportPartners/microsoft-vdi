variable "resource_group_name" {
  description = "Basename of the Resource Group to deploy the workstation"
}

variable "deployment_index" {
  description = "Number (index) of the deployment"
}

variable "location" {
  description = "Zone to deploy storages"
}

variable "storage_name" {
  description = "Base name for Standard/Premium storage. Will be prefixed with 'ss'"
}

variable "is_premium_storage" {
  description = "Type (account tier) of storage"
  default = false
}

variable "diag_storage_name" {
  description = "Base name for diagnostic storage. Will be prefixed with 'stdiag'"
}

variable "file_share_quota" {
  description = "Provisioned capacity of file share in GiB. Possible values 100-102400"
}

variable "tags" {
  description = "Common tags for storage resource"
}