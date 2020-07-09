output "client_id" {
  value = "${azuread_application.vdi-application.application_id}"
}

output "client_secret" {
  value = "${random_password.vdi-service-principal-password.result}"
}