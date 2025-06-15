output "service_name" {
  value = var.service_name
}

output "environment" {
  value = var.environment
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.log_group.name
}
