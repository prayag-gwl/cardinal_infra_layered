resource "aws_cloudwatch_log_group" "lg" {
  for_each          = toset(var.log_groups)
  name              = each.value
  retention_in_days = var.retention_in_days
  tags              = var.tags
}
