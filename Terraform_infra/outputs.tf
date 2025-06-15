output "services" {
  value = [
    {
      name        = module.web_server.service_name
      environment = module.web_server.environment
    },
    {
      name        = module.db_server.service_name
      environment = module.db_server.environment
    }
  ]
}

output "log_group_names" {
  value = [
    module.web_server.log_group_name,
    module.db_server.log_group_name
  ]
}
