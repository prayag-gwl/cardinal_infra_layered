locals {
  vault_kms_arn  = var.create_kms_key && var.kms_key_arn == "" ? aws_kms_key.vault[0].arn : (var.kms_key_arn != "" ? var.kms_key_arn : null)
  backup_role_arn = var.iam_role_arn != "" ? var.iam_role_arn : (var.create_backup_role ? aws_iam_role.backup[0].arn : null)
}

resource "aws_kms_key" "vault" {
  count                   = var.create_kms_key && var.kms_key_arn == "" ? 1 : 0
  description             = "KMS key for AWS Backup vault ${var.vault_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "vault" {
  count         = length(aws_kms_key.vault) > 0 ? 1 : 0
  name          = "alias/${var.vault_name}"
  target_key_id = aws_kms_key.vault[0].key_id
}

resource "aws_iam_role" "backup" {
  count = var.create_backup_role && var.iam_role_arn == "" ? 1 : 0

  name               = "${var.vault_name}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "backup_default" {
  count      = length(aws_iam_role.backup) > 0 ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  count      = length(aws_iam_role.backup) > 0 ? 1 : 0
  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_vault" "this" {
  name        = var.vault_name
  kms_key_arn = local.vault_kms_arn
  tags        = var.tags
}

resource "aws_backup_vault_notifications" "this" {
  count          = var.sns_topic_arn != "" ? 1 : 0
  backup_vault_name = aws_backup_vault.this.name
  sns_topic_arn     = var.sns_topic_arn
  backup_vault_events = ["BACKUP_JOB_COMPLETED", "RESTORE_JOB_COMPLETED", "BACKUP_JOB_FAILED", "RESTORE_JOB_FAILED"]
}

resource "aws_backup_plan" "this" {
  name = var.plan_name
  tags = var.tags

  rule {
    rule_name         = "daily-full"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 5 * * ? *)"
    start_window      = 60
    completion_window = 180
    lifecycle {
      delete_after = 90
    }

    dynamic "copy_action" {
      for_each = var.copy_actions
      content {
        destination_vault_arn = copy_action.value.destination_vault_arn
        dynamic "lifecycle" {
          for_each = try([copy_action.value.lifecycle], [])
          content {
            cold_storage_after = try(lifecycle.value.cold_storage_after, null)
            delete_after       = try(lifecycle.value.delete_after, null)
          }
        }
      }
    }
  }

  rule {
    rule_name         = "hourly-incremental"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 * * * ? *)"
    start_window      = 60
    completion_window = 120
    lifecycle {
      delete_after = 30
    }
  }
}

resource "aws_backup_selection" "this" {
  count        = local.backup_role_arn != null ? 1 : 0
  name         = "${var.plan_name}-selection"
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = local.backup_role_arn

  resources = var.backup_resources
}

