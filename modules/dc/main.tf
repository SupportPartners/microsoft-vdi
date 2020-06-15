/*
 * Copyright (c) 2019 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

data "template_file" "setup-script" {
  template = file("${path.module}/setup.ps1")

  vars = {
    account_name              = var.ad_admin_username
    domain_name               = var.active_directory_domain_name
    safe_mode_admin_password  = var.safe_mode_admin_password
    application_id            = var.application_id
    aad_client_secret         = var.aad_client_secret
    tenant_id                 = var.tenant_id
    safe_admin_pass_secret_id = var.safe_admin_pass_secret_id
    virtual_machine_name      = local.virtual_machine_name
  }
}

data "template_file" "new-domain-users-script" {
  template = file("${path.module}/new_domain_users.ps1")

  vars = {
    domain_name = var.active_directory_domain_name
    csv_file    = local.domain_users_list_file
  }
}

resource "azurerm_windows_virtual_machine" "domain-controller" {
  name                = local.virtual_machine_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.dc_machine_type
  admin_username      = var.ad_admin_username
  admin_password      = local.use_secret_or_not.ad_admin_password
  custom_data         = local.custom_data

  network_interface_ids = [
    var.nic_id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  additional_unattend_content {
    content = local.auto_logon_data
    setting = "AutoLogon"
  }

  additional_unattend_content {
    content = local.first_logon_data
    setting = "FirstLogonCommands"
  }
}

resource "azurerm_virtual_machine_extension" "run-sysprep-script" {
  name                 = "create-active-directory-forest"
  virtual_machine_id   = azurerm_windows_virtual_machine.domain-controller.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings           = <<SETTINGS
  {
    "fileUris": ["${var._artifactsLocation}${local.sysprep_filename}"]
  }
SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
  {
    "commandToExecute": "\"${local.powershell_command}\""
  }
PROTECTED_SETTINGS
}

resource "null_resource" "upload-scripts" {
  depends_on = [azurerm_virtual_machine_extension.run-sysprep-script]
  triggers = {
    instance_id = azurerm_windows_virtual_machine.domain-controller.id
  }

  connection {
    type     = "winrm"
    user     = var.ad_admin_username
    password = local.use_secret_or_not.ad_admin_password
    host     = azurerm_windows_virtual_machine.domain-controller.public_ip_address
    port     = "5986"
    https    = true
    insecure = true
  }

  provisioner "file" {
    content     = data.template_file.setup-script.rendered
    destination = local.setup_file
  }

  provisioner "file" {
    content     = data.template_file.new-domain-users-script.rendered
    destination = local.new_domain_users_file
  }
}

resource "null_resource" "upload-domain-users-list" {
  count = local.new_domain_users

  depends_on = [azurerm_virtual_machine_extension.run-sysprep-script]
  triggers = {
    instance_id = azurerm_windows_virtual_machine.domain-controller.id
  }

  connection {
    type     = "winrm"
    user     = var.ad_admin_username
    password = local.use_secret_or_not.ad_admin_password
    host     = azurerm_windows_virtual_machine.domain-controller.public_ip_address
    port     = "5986"
    https    = true
    insecure = true
  }

  provisioner "file" {
    source      = "domain_users_list.csv"
    destination = local.domain_users_list_file
  }
}

resource "null_resource" "run-setup-script" {
  depends_on = [null_resource.upload-scripts]
  triggers = {
    instance_id = azurerm_windows_virtual_machine.domain-controller.id
  }

  connection {
    type     = "winrm"
    user     = var.ad_admin_username
    password = local.use_secret_or_not.ad_admin_password
    host     = azurerm_windows_virtual_machine.domain-controller.public_ip_address
    port     = "5986"
    https    = true
    insecure = true
  }

  provisioner "remote-exec" {
    inline = [
      "powershell -file ${local.setup_file}",
      "del ${replace(local.setup_file, "/", "\\")}",
    ]
  }
}

resource "null_resource" "wait-for-reboot" {
  depends_on = [null_resource.run-setup-script]
  triggers = {
    instance_id = azurerm_windows_virtual_machine.domain-controller.id
  }

  provisioner "local-exec" {
    # This command is written this way to make it work regardless of whether the
    # user runs Terraform in Windows (where local-exec is the command prompt) or
    # Linux (where the local-exec is e.g. bash shell).
    command = "sleep 15 || powershell sleep 15"
  }
}

resource "null_resource" "new-domain-user" {
  count = local.new_domain_users

  # Waits for new-domain-admin-user because that script waits for ADWS to be up
  depends_on = [null_resource.upload-domain-users-list]

  triggers = {
    instance_id = azurerm_windows_virtual_machine.domain-controller.id
  }

  connection {
    type     = "winrm"
    user     = var.ad_admin_username
    password = local.use_secret_or_not.ad_admin_password
    host     = azurerm_windows_virtual_machine.domain-controller.public_ip_address
    port     = "5986"
    https    = true
    insecure = true
  }

  provisioner "remote-exec" {
    # wait in case csv file is newly uploaded
    inline = [
      "powershell sleep 2",
      "powershell -file ${local.new_domain_users_file}",
      "del ${replace(local.new_domain_users_file, "/", "\\")}",
      "del ${replace(local.domain_users_list_file, "/", "\\")}",
    ]
  }
}

resource "azurerm_template_deployment" "shutdown_schedule_template" {
  name                = "${azurerm_windows_virtual_machine.domain-controller.name}-shutdown-schedule-template"
  resource_group_name = "${var.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    "location"                       = var.location
    "virtualMachineName"             = azurerm_windows_virtual_machine.domain-controller.name
    "autoShutdownStatus"             = "Enabled"
    "autoShutdownTime"               = "18:00"
    "autoShutdownTimeZone"           = "Pacific Standard Time"
    "autoShutdownNotificationStatus" = "Disabled"
    "autoShutdownNotificationLocale" = "en"
  }

  template_body = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
      "parameters": {
          "location": {
              "type": "string"
          },
          "virtualMachineName": {
              "type": "string"
          },
          "autoShutdownStatus": {
              "type": "string"
          },
          "autoShutdownTime": {
              "type": "string"
          },
          "autoShutdownTimeZone": {
              "type": "string"
          },
          "autoShutdownNotificationStatus": {
              "type": "string"
          },
          "autoShutdownNotificationLocale": {
              "type": "string"
          }
      },
      "resources": [
        {
            "name": "[concat('shutdown-computevm-', parameters('virtualMachineName'))]",
            "type": "Microsoft.DevTestLab/schedules",
            "apiVersion": "2018-09-15",
            "location": "[parameters('location')]",
            "properties": {
                "status": "[parameters('autoShutdownStatus')]",
                "taskType": "ComputeVmShutdownTask",
                "dailyRecurrence": {
                    "time": "[parameters('autoShutdownTime')]"
                },
                "timeZoneId": "[parameters('autoShutdownTimeZone')]",
                "targetResourceId": "[resourceId('Microsoft.Compute/virtualMachines', parameters('virtualMachineName'))]",
                "notificationSettings": {
                    "status": "[parameters('autoShutdownNotificationStatus')]",
                    "notificationLocale": "[parameters('autoShutdownNotificationLocale')]",
                    "timeInMinutes": "30"
                }
            }
        }
    ]
  }
  DEPLOY
}