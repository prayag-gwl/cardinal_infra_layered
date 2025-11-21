variable "project" {
  description = "Project name used for tagging."
  type        = string
  default     = "cardinal"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
}

variable "azs" {
  description = "Availability zones to deploy into."
  type        = list(string)
}

# Existing VPC and networking resources (reused from DEV)
variable "existing_vpc_id" {
  description = "ID of the existing VPC to reuse (e.g., cardinal-vpc)."
  type        = string
}

variable "existing_public_subnets" {
  description = "List of existing public subnet IDs to use for ALB."
  type        = list(string)
}

variable "existing_private_subnets" {
  description = "List of existing private subnet IDs to use for ECS tasks."
  type        = list(string)
}

variable "existing_db_subnets" {
  description = "List of existing database subnet IDs (optional, defaults to private subnets)."
  type        = list(string)
  default     = []
}

variable "existing_rds_sg_id" {
  description = "Security group ID of the existing RDS instance."
  type        = string
}

variable "existing_rds_endpoint" {
  description = "Endpoint (hostname) of the existing RDS instance."
  type        = string
}

variable "frontend_image" {
  description = "Container image for the frontend service."
  type        = string
}

variable "backend_image" {
  description = "Container image for the backend service."
  type        = string
}

variable "frontend_env" {
  description = "Environment variables for the frontend service."
  type        = map(string)
  default     = {}
}

variable "backend_env" {
  description = "Environment variables for the backend service."
  type        = map(string)
  default     = {}
}

variable "frontend_certificate_arn" {
  description = "ACM certificate ARN for the public ALB. Leave blank to run HTTP-only."
  type        = string
  default     = ""
}

variable "backend_certificate_arn" {
  description = "ACM certificate ARN for the internal backend ALB. Leave blank to run HTTP-only."
  type        = string
  default     = ""
}

variable "waf_web_acl_arn" {
  description = "Optional WAF Web ACL ARN to associate with the public ALB."
  type        = string
  default     = ""
}

variable "database_secret_arn" {
  description = "Secrets Manager secret ARN containing database credentials (JSON). Required. Should contain host, username, password, port, database."
  type        = string
}

variable "existing_rds_identifier" {
  description = "Identifier of the existing RDS database instance to reference (reused from DEV)."
  type        = string
}


variable "alarm_emails" {
  description = "Email addresses for alert subscriptions."
  type        = list(string)
  default     = []
}

variable "backup_copy_actions" {
  description = "Optional backup copy actions for cross-region replication."
  type = list(object({
    destination_vault_arn = string
    lifecycle = optional(object({
      cold_storage_after = optional(number)
      delete_after       = optional(number)
    }))
  }))
  default = []
}

variable "backup_kms_key_arn" {
  description = "ARN of existing KMS key for backup vault encryption. If provided, Terraform will use this key instead of creating a new one."
  type        = string
  default     = ""
}

variable "existing_backup_vault_name" {
  description = "Name of existing backup vault to use. If provided, Terraform will not create a new vault."
  type        = string
  default     = ""
}

variable "existing_backup_plan_id" {
  description = "ID of existing backup plan to use. If provided, Terraform will not create a new backup plan."
  type        = string
  default     = ""
}

variable "backup_iam_role_arn" {
  description = "ARN of existing IAM role for AWS Backup. If provided, Terraform will use this role instead of creating a new one."
  type        = string
  default     = ""
}

variable "frontend_health_path" {
  description = "Frontend health check path."
  type        = string
  default     = "/health"
}

variable "backend_health_path" {
  description = "Backend health check path."
  type        = string
  default     = "/api/cardinal-education-service/v1/health"
}

variable "frontend_host_header" {
  description = "Host header for frontend service routing (e.g., beta.cedu.app)."
  type        = string
  default     = "beta.cedu.app"
}

variable "backend_host_header" {
  description = "Host header for backend service routing (e.g., api.cedu.app)."
  type        = string
  default     = "api.cedu.app"
}

variable "extra_tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

