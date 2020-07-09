output "deployment_id" {
  value = restapi_object.cam_deployment.id
}

output "connector_name" {
  value = local.connector_name
}

output "cac_token" {
  value = restapi_object.cam_connector.id
}
