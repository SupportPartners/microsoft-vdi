variable "subscription_id" {
  description = "Subscription id of deployment"
}

variable "client_id" {
  description = "Service principal client id for authorizing in Azure"
}

variable "client_secret" {
  description = "Service principal client secret for authorizing in Azure"
}

variable "sp_tenant_id" {
  description = "Service principal tenant id for authorizing in Azure"
}

variable "base_name" {
  description = "Base name for all resources of all deployments"
}

variable "resource_group_name" {
  description = "Resource group name. User input, overwriting name convention"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
}

variable "deployment_index" {
  description = "Number (index) of the deployment"
}

variable "storage_name" {
  description = "Base name for Standard/Premium storage. Will be prefixed with 'ss'"
}

variable "diag_storage_name" {
  description = "Base name for diagnostic storage. Will be prefixed with 'stdiag'"
}

variable "file_share_quota" {
  default = 5120
  description = "Provisioned capacity of file share in GiB. Possible values 100-102400. Default is 5120 Gib"
}

variable "cam_url" {
  description = "Cloud Access Manager URL"
}

variable "pcoip_registration_code" {
  description = "PCoIP Registration code"
  type        = string
}

variable "pcoip_agent_location" {
  description = "URL of Teradici PCoIP Standard Agent"
}

variable "cac_token" {
  description = "Connector Token from CAM Service"
  type        = string
}

variable "domain_group" {
  description = "Active Directory Distinguished Name for the User Group to log into the CAM Management Interface. Default is 'Domain Admins'. (eg, 'CN=CAM Admins,CN=Users,DC=example,DC=com')"
}

variable "instance_count" {
  description = "Number of Cloud Access Connectors to deploy"
}

variable "cac_host_name" {
  description = "Name to give the host"
}

variable "cac_machine_type" {
  description = "Machine type for the Cloud Access Connector"
}

variable "cac_disk_size_gb" {
  description = "Disk size (GB) of the Cloud Access Connector"
}

variable "cac_admin_username" {
  description = "Username of the Cloud Access Connector Administrator"
  type        = string
}

variable "cac_admin_password" {
  description = "Password for the Administrator of the Cloud Access Connector VM"
  type        = string
}

variable "cac_installer_url" {
  description = "Location of the Cloud Access Connector installer"
}

variable "ssl_key" {
  description = "SSL private key for the Connector"
}

variable "ssl_cert" {
  description = "SSL certificate for the Connector"
}

variable "active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
}

variable "ad_admin_username" {
  description = "Username for the Domain Administrator user"
}

variable "ad_admin_password" {
  description = "Password for the Adminstrator user"
}

variable "dc_private_ip" {
  description = "Static internal IP address for the Domain Controller"
}

variable "cac_private_ip" {
  description = "Static internal IP address for the Cloud Access Controller"
}

variable "dc_subnet_cidr" {
  description = "CIDR for subnet containing the Domain Controller"
}

variable "ws_subnet_cidr" {
  description = "CIDR for subnet containing the Workstations"
}

variable "cac_subnet_cidr" {
  description = "CIDR for subnet containing the Domain Controller"
}

variable "allowed_client_cidrs" {
  description = "Open VPC firewall to allow PCoIP connections from these IP Addresses or CIDR ranges. e.g. 'a.b.c.d', 'e.f.g.0/24'"
}

variable "dc_machine_type" {
  description = "Machine type for Domain Controller"
}

variable "ad_pass_secret_name" {
  description = "The name of the Active Directory secret password"
  type        = string
}

variable "windows_std_hostname" {
  description = "Basename of hostname of the workstation. Hostname will be <prefix>-<name>-<count>. Lower case only."
  type        = string
}

variable "windows_std_admin_username" {
  description = "Name for the Administrator of the Workstation"
  type        = string
}

variable "windows_std_admin_password" {
  description = "Password for the Administrator of the Workstation"
  type        = string
}

variable "windows_std_vm_size" {
  description = "Size of the VM to deploy"
  type        = string
}

variable "windows_std_persona" {
  description = "Persona type of deploying VM"
}

variable "windows_std_count" {
  description = "Number of windows standard agents to deploy"
}

variable "key_vault_id" {
  description = "The key vault resource ID"
  type        = string
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "tenant_id" {
  description = "The directory (tenant) ID of your app registration in AAD"
  type        = string
}

variable "pcoip_secret_id" {
  description = "The secret identifier in your azure key vault, follow this format https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>"
  type        = string
}

variable "ad_pass_secret_id" {
  description = "The secret identifier in your azure key vault, follow this format https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>"
  type        = string
}

variable "safe_admin_pass_secret_id" {
  description = "The secret identifier in your azure key vault, follow this format https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>"
  type        = string
}

variable "cac_token_secret_id" {
  description = "The secret identifier in your azure key vault, follow this format https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<secret-version>"
  type        = string
}

variable "safe_mode_admin_password" {
  description = "Safe Mode Admin Password (Directory Service Restore Mode - DSRM)"
  type        = string
}

variable "golden_image_id" {
  description = "Id of the golden image in shared image gallery"
  type        = string
}

variable "client_name" {
  description = "Client name for tags. User entry"
  type        = string
}

variable "environment" {
  description = "Environment for tags"
  type        = string
}

variable "_artifactsLocation" {
  description = "The base URI where artifacts required by this template are located including a trailing '/'"
}

variable "_artifactsLocationSasToken" {
  description = "Sas Token of the URL is optional, only if required for security reasons"
  type        = string
}

locals {
  dc_virtual_machine_name  = "vm-vdi-dc${var.deployment_index}"
  cac_virtual_machine_name = "vm-vdi-cac${var.deployment_index}"
  common_tags              = "${map(
    "Created Date", "${formatdate("MMM DD, YYYY", timestamp())}",
    "Environment", "${var.environment}",
    "Client Name", "${var.client_name}",
    "Createdby", "Supportpartners"
  )}"
}