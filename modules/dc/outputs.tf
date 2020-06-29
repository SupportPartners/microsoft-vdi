output "domain_users_created" {
    value      = {}
    depends_on = [null_resource.new-domain-user]
}