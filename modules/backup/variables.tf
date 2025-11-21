variable "vault_name" {
  description = "Name of the backup vault."
  type        = string
}

variable "plan_name" {
  description = "Name of the backup plan."
  type        = string
}

variable "backup_resources" {
  description = "Resource ARNs to include in the backup selection."
  type        = list(string)
}

variable "iam_role_arn" {
  description = "Existing IAM role ARN for AWS Backup to assume."
  type        = string
  default     = ""
}

variable "create_backup_role" {
  description = "Create an IAM role for AWS Backup if one is not provided."
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for backup notifications."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting the vault."
  type        = string
  default     = ""
}

variable "create_kms_key" {
  description = "Create dedicated KMS key if kms_key_arn not provided."
  type        = bool
  default     = true
}

variable "copy_actions" {
  description = "Optional cross-region copy actions."
  type = list(object({
    destination_vault_arn = string
    lifecycle = optional(object({
      cold_storage_after = optional(number)
      delete_after       = optional(number)
    }))
  }))
  default     = []
}

variable "tags" {
  description = "Tags to apply to Backup resources."
  type        = map(string)
  default     = {}
}

variable "existing_vault_name" {
  description = "Name of existing backup vault to use instead of creating a new one. If provided, Terraform will use this vault instead of creating a new one."
  type        = string
  default     = ""
}

variable "existing_plan_id" {
  description = "ID of existing backup plan to use instead of creating a new one. If provided, Terraform will not create a new backup plan."
  type        = string
  default     = ""
}

variable "create_backup_plan" {
  description = "Whether to create a new backup plan. Set to false if using existing_plan_id."
  type        = bool
  default     = true
}

