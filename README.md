# VDI deployment script and templates

## Terraform scripts

### Initial run

Before the creating the first deployment, the storage account and container with files for deployments should be created. Terraform scripts in `init` folder will create all needed resources and upload the following files: CAC installation scripts, sysprep, wallpaper and PCoIP installation scripts for VMs.

To start the initial run, please fill/edit the following variables in `init/terraform.tfvars` and run `terraform apply` in the `init` folder:

 - resource group name
 - location of resource group
 - storage account name

### Deployment resources

All resources of the deployment are described in the following Terraform modules:

 - DC (Domain Controller)
 - CAC (Teradici Cloud Access Connector)
 - Persona (Workstation VM)
 - Storage (Azure storage accounts for file sharing and VM diagnostic)

## Deployment script `deploy.ps1`

The deployment starts with running this script which is performing the following steps:

 - Download Terraform templates
 - Generate `.tfvars` file with predefined default varables
 - Download `Terraform.exe`
 - Create users (you can enter 'y' and fill the following fields for each user: Username, Password, Firstname, Lastname, Is admin)
 - Execute `terraform init` and `terraform apply` with needed parameters

 Predefined variables can be set in script but all variables left without values are requested from user by Terraform during the applying.