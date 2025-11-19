output "vault_arn" {
  value       = local.vault_arn
  description = "ARN of the backup vault (existing or created)."
}

output "plan_id" {
  value       = aws_backup_plan.this.id
  description = "ID of the backup plan."
}

output "role_arn" {
  value       = local.backup_role_arn
  description = "IAM role ARN used by AWS Backup."
}

