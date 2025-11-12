variable "region" {
  description = "AWS region where the backend resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket that will store Terraform state."
  type        = string
}

variable "bucket_force_destroy" {
  description = "Allow Terraform to delete the state bucket even when it contains objects."
  type        = bool
  default     = false
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  type        = string
}

variable "enable_kms" {
  description = "Whether to create a dedicated KMS key for encrypting the state bucket."
  type        = bool
  default     = false
}

variable "kms_alias" {
  description = "Alias to assign to the KMS key when enable_kms is true."
  type        = string
  default     = "tf-state-backend"
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period before the KMS key is actually deleted."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all created resources."
  type        = map(string)
  default     = {}
}

