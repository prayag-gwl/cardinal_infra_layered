variable "identifier" {
  description = "RDS instance identifier."
  type        = string
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "cardinal"
}

variable "master_username" {
  description = "Master username."
  type        = string
}

variable "master_password" {
  description = "Master password."
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security groups to attach to the instance."
  type        = list(string)
}

variable "instance_class" {
  description = "Instance class for RDS."
  type        = string
  default     = "db.m6g.large"
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.5"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB."
  type        = number
  default     = 50
}

variable "max_allocated_storage" {
  description = "Maximum storage in GB when autoscaling."
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Backup retention period in days."
  type        = number
  default     = 14
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = true
}

variable "preferred_backup_window" {
  description = "Preferred backup window."
  type        = string
  default     = "03:00-05:00"
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window."
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "Enable storage encryption."
  type        = bool
  default     = true
}

variable "create_kms_key" {
  description = "Create a dedicated KMS key for encryption."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing KMS key ARN to use for encryption."
  type        = string
  default     = ""
}

variable "enable_iam_auth" {
  description = "Enable IAM database authentication."
  type        = bool
  default     = true
}

variable "parameter_group_family" {
  description = "DB parameter group family."
  type        = string
  default     = "postgres15"
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

