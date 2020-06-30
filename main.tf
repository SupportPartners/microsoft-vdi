resource "azurerm_resource_group" "vdi_resource_group" {
  location = var.location
  name     = var.resource_group_name != "" ? var.resource_group_name : "rg-${var.base_name}-infra-${var.deployment_index}"
}

module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  deployment_index    = var.deployment_index
  location            = var.location
  storage_name        = var.storage_name
  is_premium_storage  = var.windows_std_persona > 1
  diag_storage_name   = var.diag_storage_name
  file_share_quota    = var.file_share_quota
  tags                = local.common_tags
}

data "http" "myip" {
  url = "https://ipinfo.io/ip"
}

resource "azurerm_virtual_network" "vdi_virtual_network" {
  name                = "vnet-${var.base_name}-${var.deployment_index}"
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  dns_servers         = ["10.0.1.4", "168.63.129.16"]
}

resource "azurerm_subnet" "dc" {
  name                 = "snet-${var.base_name}-dc-${var.deployment_index}"
  address_prefix       = var.dc_subnet_cidr
  resource_group_name  = azurerm_resource_group.vdi_resource_group.name
  virtual_network_name = azurerm_virtual_network.vdi_virtual_network.name
}

resource "azurerm_subnet" "cac" {
  name                 = "snet-${var.base_name}-cac-${var.deployment_index}"
  address_prefix       = var.cac_subnet_cidr
  resource_group_name  = azurerm_resource_group.vdi_resource_group.name
  virtual_network_name = azurerm_virtual_network.vdi_virtual_network.name
  depends_on           = ["azurerm_subnet.dc"]
}

resource "azurerm_subnet" "workstation" {
  name                 = "snet-${var.base_name}-workstation-${var.deployment_index}"
  address_prefix       = var.ws_subnet_cidr
  resource_group_name  = azurerm_resource_group.vdi_resource_group.name
  virtual_network_name = azurerm_virtual_network.vdi_virtual_network.name
  depends_on           = ["azurerm_subnet.cac"]
}

resource "azurerm_public_ip" "dc_ip" {
  name                    = "pip-${local.dc_virtual_machine_name}-${var.deployment_index}"
  location                = var.location
  resource_group_name     = azurerm_resource_group.vdi_resource_group.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_public_ip" "cac" {
  name                    = "pip-${local.cac_virtual_machine_name}-${var.deployment_index}"
  location                = var.location
  resource_group_name     = azurerm_resource_group.vdi_resource_group.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_public_ip" "nat" {
  name                    = "pip-nat-${var.deployment_index}"
  location                = var.location
  resource_group_name     = azurerm_resource_group.vdi_resource_group.name
  allocation_method       = "Static"
  sku                     = "Standard"
  zones                   = ["1"]
  idle_timeout_in_minutes = 30
}

resource "azurerm_public_ip_prefix" "nat" {
  name                = "nat-gateway-PIPP"
  location            = var.location
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  prefix_length       = 30
  zones               = ["1"]
}

resource "azurerm_nat_gateway" "nat" {
  name                    = "nat-gateway"
  location                = var.location
  resource_group_name     = azurerm_resource_group.vdi_resource_group.name
  public_ip_address_ids   = [azurerm_public_ip.nat.id]
  public_ip_prefix_ids    = [azurerm_public_ip_prefix.nat.id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

resource "null_resource" "delay_nat_gateway_association" {
  provisioner "local-exec" {
    command = "Start-Sleep 1"
    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    "before" = "${azurerm_nat_gateway.nat.id}"
  }
}

resource "azurerm_subnet_nat_gateway_association" "nat" {
  subnet_id      = azurerm_subnet.workstation.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
  depends_on     = ["null_resource.delay_nat_gateway_association"]
}

resource "azurerm_network_interface" "dc_nic" {
  name                = "nic-${var.deployment_index}-${local.dc_virtual_machine_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  ip_configuration {
    name                          = "primary"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.dc_private_ip
    public_ip_address_id          = azurerm_public_ip.dc_ip.id
    subnet_id                     = azurerm_subnet.dc.id
  }
}

resource "null_resource" "delay_nic_dc" {
  provisioner "local-exec" {
    command = "Start-Sleep 1"
    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    "before" = "${azurerm_network_interface.dc_nic.id}"
  }
}

resource "azurerm_network_interface" "cac" {
  name                = "nic-${var.deployment_index}-${local.cac_virtual_machine_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  ip_configuration {
    name                          = "primary"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.cac_private_ip
    public_ip_address_id          = azurerm_public_ip.cac.id
    subnet_id                     = azurerm_subnet.cac.id
  }
  depends_on = ["null_resource.delay_nic_dc"]
}

resource "azurerm_private_dns_zone" "dns" {
  name                = "dns.internal"
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cac" {
  name                  = "dns-vnet-link"
  resource_group_name   = azurerm_resource_group.vdi_resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = azurerm_virtual_network.vdi_virtual_network.id
}

resource "azurerm_private_dns_a_record" "dns" {
  name                = var.active_directory_netbios_name
  zone_name           = azurerm_private_dns_zone.dns.name
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  ttl                 = 300
  records             = ["10.0.1.4"]
}

resource "azurerm_private_dns_srv_record" "dns-cac" {
  name                = "_ldap._tcp.${var.active_directory_netbios_name}"
  zone_name           = azurerm_private_dns_zone.dns.name
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  ttl                 = 300

  record {
    priority = 1
    weight   = 1
    port     = 389
    target   = "${var.active_directory_netbios_name}.dns.internal"
  }
}

resource "azurerm_private_dns_srv_record" "dns-ldaps" {
  name                = "_ldap._tcp.vm-vdi-dc${var.deployment_index}.${var.active_directory_netbios_name}"
  zone_name           = azurerm_private_dns_zone.dns.name
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  ttl                 = 300

  record {
    priority = 3
    weight   = 3
    port     = 389
    target   = "${var.active_directory_netbios_name}.dns.internal"
  }
}

resource "azurerm_private_dns_srv_record" "dns-win" {
  name                = "_ldap._tcp.dc._msdcs.${var.active_directory_netbios_name}"
  zone_name           = azurerm_private_dns_zone.dns.name
  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  ttl                 = 300

  record {
    priority = 2
    weight   = 2
    port     = 389
    target   = "${var.active_directory_netbios_name}.dns.internal"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.base_name}-${var.deployment_index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.vdi_resource_group.name

  security_rule {
    name                       = "AllowAllVnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["1-65525"]
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWinRM"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = chomp(data.http.myip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = chomp(data.http.myip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = chomp(data.http.myip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowPCoIP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "4172"]
    source_address_prefix      = var.allowed_client_cidrs
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "cac" {
  subnet_id                 = azurerm_subnet.cac.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "null_resource" "delay_nsg_association_dc" {
  provisioner "local-exec" {
    command = "Start-Sleep 1"
    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    "before" = "${azurerm_subnet_network_security_group_association.cac.id}"
  }
}

resource "azurerm_subnet_network_security_group_association" "dc" {
  subnet_id                 = azurerm_subnet.dc.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                = ["null_resource.delay_nsg_association_dc"]
}

resource "null_resource" "delay_nsg_association_workstation" {
  provisioner "local-exec" {
    command = "Start-Sleep 1"
    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    "before" = "${azurerm_subnet_network_security_group_association.dc.id}"
  }
}

resource "azurerm_subnet_network_security_group_association" "workstation" {
  subnet_id                 = azurerm_subnet.workstation.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                = ["null_resource.delay_nsg_association_workstation"]
}

module "active-directory-domain" {
  source = "./modules/dc"

  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  location            = azurerm_resource_group.vdi_resource_group.location
  deployment_index    = var.deployment_index

  virtual_machine_name          = local.dc_virtual_machine_name
  active_directory_domain_name  = "${var.active_directory_netbios_name}.dns.internal"
  active_directory_netbios_name = var.active_directory_netbios_name
  ad_admin_username             = var.ad_admin_username
  ad_admin_password             = var.ad_admin_password
  dc_machine_type               = var.dc_machine_type
  nic_id                        = azurerm_network_interface.dc_nic.id
  ad_pass_secret_name           = var.ad_pass_secret_name
  key_vault_id                  = var.key_vault_id
  application_id                = var.application_id
  aad_client_secret             = var.aad_client_secret
  tenant_id                     = var.tenant_id
  safe_admin_pass_secret_id     = var.safe_admin_pass_secret_id
  safe_mode_admin_password      = var.safe_mode_admin_password
  _artifactsLocation            = var._artifactsLocation
}

module "cac" {
  source = "./modules/cac"

  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  location            = azurerm_resource_group.vdi_resource_group.location
  deployment_index    = var.deployment_index

  virtual_machine_name        = local.cac_virtual_machine_name
  cam_url                     = var.cam_url
  pcoip_registration_code     = var.pcoip_registration_code
  cac_token                   = var.cac_token
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  domain_controller_ip        = azurerm_network_interface.dc_nic.private_ip_address
  domain_group                = var.domain_group
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  nic_id                      = azurerm_network_interface.cac.id
  instance_count              = var.instance_count
  host_name                   = var.cac_host_name
  machine_type                = var.cac_machine_type
  disk_size_gb                = var.cac_disk_size_gb
  cac_admin_user              = var.cac_admin_username
  cac_admin_password          = var.cac_admin_password
  cac_installer_url           = var.cac_installer_url
  ssl_key                     = var.ssl_key
  ssl_cert                    = var.ssl_cert
  dns_zone_id                 = azurerm_private_dns_zone.dns.id
  cac_ip                      = azurerm_public_ip.cac.ip_address
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  tenant_id                   = var.tenant_id
  pcoip_secret_id             = var.pcoip_secret_id
  ad_pass_secret_id           = var.ad_pass_secret_id
  cac_token_secret_id         = var.cac_token_secret_id
  _artifactsLocation          = var._artifactsLocation
}

module "persona-1" {
  source = "./modules/persona"

  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  azure_region        = azurerm_resource_group.vdi_resource_group.location

  vm_name                     = "Win10Nv6SSD"
  base_name                   = var.base_name
  image_id                    = var.golden_image_id
  pcoip_registration_code     = var.pcoip_registration_code
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  admin_name                  = var.windows_std_admin_username
  admin_password              = var.windows_std_admin_password
  host_name                   = var.windows_std_hostname
  instance_count              = var.windows_std_persona == 1 ? var.windows_std_count : 0
  pcoip_agent_location        = var.pcoip_agent_location
  storage_account             = module.storage.storage_account
  storage_container           = module.storage.storage_container
  storage_access_key          = module.storage.storage_access_key
  vnet_name                   = azurerm_virtual_network.vdi_virtual_network.name
  nsgID                       = azurerm_network_security_group.nsg.id
  subnetID                    = azurerm_subnet.workstation.id
  subnet_name                 = azurerm_subnet.workstation.name
  vm_size                     = "Standard_NV6"
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  tenant_id                   = var.tenant_id
  pcoip_secret_id             = var.pcoip_secret_id
  ad_pass_secret_id           = var.ad_pass_secret_id
  _artifactsLocation          = var._artifactsLocation
  _artifactsLocationSasToken  = var._artifactsLocationSasToken
  tags                        = local.common_tags
  vm_depends_on               = module.active-directory-domain.domain_users_created
}

module "persona-2" {
  source = "./modules/persona"

  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  azure_region        = azurerm_resource_group.vdi_resource_group.location

  vm_name                     = "Win10Nv12SSD"
  base_name                   = var.base_name
  image_id                    = var.golden_image_id
  pcoip_registration_code     = var.pcoip_registration_code
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  admin_name                  = var.windows_std_admin_username
  admin_password              = var.windows_std_admin_password
  host_name                   = var.windows_std_hostname
  instance_count              = var.windows_std_persona == 2 ? var.windows_std_count : 0
  pcoip_agent_location        = var.pcoip_agent_location
  storage_account             = module.storage.storage_account
  storage_container           = module.storage.storage_container
  storage_access_key          = module.storage.storage_access_key
  vnet_name                   = azurerm_virtual_network.vdi_virtual_network.name
  nsgID                       = azurerm_network_security_group.nsg.id
  subnetID                    = azurerm_subnet.workstation.id
  subnet_name                 = azurerm_subnet.workstation.name
  vm_size                     = "Standard_NV12s_v3"
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  tenant_id                   = var.tenant_id
  pcoip_secret_id             = var.pcoip_secret_id
  ad_pass_secret_id           = var.ad_pass_secret_id
  _artifactsLocation          = var._artifactsLocation
  _artifactsLocationSasToken  = var._artifactsLocationSasToken
  tags                        = local.common_tags
  vm_depends_on               = module.active-directory-domain.domain_users_created
}

module "persona-3" {
  source = "./modules/persona"

  resource_group_name = azurerm_resource_group.vdi_resource_group.name
  azure_region        = azurerm_resource_group.vdi_resource_group.location

  vm_name                     = "Win10Nv24SSD"
  base_name                   = var.base_name
  image_id                    = var.golden_image_id
  pcoip_registration_code     = var.pcoip_registration_code
  domain_name                 = "${var.active_directory_netbios_name}.dns.internal"
  ad_service_account_username = var.ad_admin_username
  ad_service_account_password = var.ad_admin_password
  admin_name                  = var.windows_std_admin_username
  admin_password              = var.windows_std_admin_password
  host_name                   = var.windows_std_hostname
  instance_count              = var.windows_std_persona == 3 ? var.windows_std_count : 0
  pcoip_agent_location        = var.pcoip_agent_location
  storage_account             = module.storage.storage_account
  storage_container           = module.storage.storage_container
  storage_access_key          = module.storage.storage_access_key
  vnet_name                   = azurerm_virtual_network.vdi_virtual_network.name
  nsgID                       = azurerm_network_security_group.nsg.id
  subnetID                    = azurerm_subnet.workstation.id
  subnet_name                 = azurerm_subnet.workstation.name
  vm_size                     = "Standard_NV24s_v3"
  application_id              = var.application_id
  aad_client_secret           = var.aad_client_secret
  tenant_id                   = var.tenant_id
  pcoip_secret_id             = var.pcoip_secret_id
  ad_pass_secret_id           = var.ad_pass_secret_id
  _artifactsLocation          = var._artifactsLocation
  _artifactsLocationSasToken  = var._artifactsLocationSasToken
  tags                        = local.common_tags
  vm_depends_on               = module.active-directory-domain.domain_users_created
}
