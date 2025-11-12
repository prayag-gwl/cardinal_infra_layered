output "vault_arn" {
  value       = aws_backup_vault.this.arn
  description = "ARN of the backup vault."
}

output "plan_id" {
  value       = aws_backup_plan.this.id
  description = "ID of the backup plan."
}

output "role_arn" {
  value       = local.backup_role_arn
  description = "IAM role ARN used by AWS Backup."
}

