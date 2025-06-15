resource "null_resource" "mock_service" {
  triggers = {
    service_name = var.service_name
    environment  = var.environment
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/${var.environment}/${var.service_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "${var.service_name}-stream"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}
