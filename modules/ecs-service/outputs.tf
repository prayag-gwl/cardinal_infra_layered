output "service_name" {
  value       = aws_ecs_service.svc.name
  description = "Name of the ECS service."
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.td.arn
  description = "ARN of the created task definition."
}

output "task_role_arn" {
  value       = aws_iam_role.task.arn
  description = "ARN of the IAM task role."
}

