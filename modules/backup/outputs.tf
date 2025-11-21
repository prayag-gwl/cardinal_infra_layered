output "vault_arn" {
  value       = local.vault_arn
  description = "ARN of the backup vault (existing or created)."
}

output "plan_id" {
  value       = var.existing_plan_id != "" ? var.existing_plan_id : (var.create_backup_plan ? aws_backup_plan.this[0].id : null)
  description = "ID of the backup plan (existing or created)."
}

output "role_arn" {
  value       = local.backup_role_arn
  description = "IAM role ARN used by AWS Backup."
}

