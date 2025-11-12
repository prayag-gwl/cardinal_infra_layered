output "log_group_names" {
  value       = [for lg in aws_cloudwatch_log_group.lg : lg.name]
  description = "Names of the created CloudWatch log groups."
}

