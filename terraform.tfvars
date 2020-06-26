# Predefined variables
base_name                     = "vdidemo"
cam_url                       = "https://cam.teradici.com"
pcoip_agent_location          = "https://downloads.teradici.com/win/stable/"
active_directory_netbios_name = "tera"
domain_group                  = "Domain Admins"
instance_count                = 1
cac_host_name                 = "vm-cac"
cac_machine_type              = "Standard_D2s_v3"
cac_disk_size_gb              = "50"
cac_installer_url             = "https://teradici.bintray.com/cloud-access-connector/cloud-access-connector-0.1.1.tar.gz"
dc_private_ip                 = "10.0.1.4"
cac_private_ip                = "10.0.3.4"
dc_subnet_cidr                = "10.0.1.0/24"
ws_subnet_cidr                = "10.0.2.0/24"
cac_subnet_cidr               = "10.0.3.0/24"
allowed_client_cidrs          = "0.0.0.0/0"
dc_machine_type               = "Standard_F2"
domain_users_list             = ""
golden_image_id               = "/subscriptions/c28be9ee-97ed-4251-ab14-43090bbc3d4e/resourceGroups/SP-VDI-graph/providers/Microsoft.Compute/galleries/sig_vdi/images/image-definition-vdi/versions/0.0.3"
#_artifactsLocation            = "https://stteradicisa.blob.core.windows.net/teradicisacontainer/"
_artifactsLocation            = "https://teradicisa.blob.core.windows.net/teradicisacontainer/"
_artifactsLocationSasToken    = ""
environment                   = "VDI Demo"
windows_std_hostname          = "windows-std-workstation"

# Leave the following blank, they are only filled when using Azure Key Vault secrets
application_id                = ""
aad_client_secret             = ""
tenant_id                     = ""
pcoip_secret_id               = ""
ad_pass_secret_id             = ""
safe_admin_pass_secret_id     = ""
cac_token_secret_id           = ""
ad_pass_secret_name           = ""
key_vault_id                  = ""

# Optional if applying SSL certificate to the CAC deployment
ssl_key  = ""
ssl_cert = ""

# User input variables. Temporarily commented for fully-customizable script
# subscription_id = ""
# client_id       = ""
# client_secret   = ""
# sp_tenant_id    = ""

# deployment_index         = "001"
# location                 = ""
# storage_name             = ""
# diag_storage_name        = ""
# file_share_quota         = 2048
# pcoip_registration_code  = ""
# ad_admin_username        = ""
# ad_admin_password        = ""
# safe_mode_admin_password = ""

# cac_admin_username          = ""
# cac_admin_password          = ""
# windows_std_admin_username  = ""
# windows_std_admin_password  = ""
# windows_std_persona         = 1
# windows_std_count           = 1
