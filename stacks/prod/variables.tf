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

variable "azs" {
  description = "Availability zones to deploy into."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs corresponding to the AZ list."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs corresponding to the AZ list."
  type        = list(string)
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
  description = "ACM certificate ARN for the public ALB."
  type        = string
}

variable "backend_certificate_arn" {
  description = "ACM certificate ARN for the internal backend ALB."
  type        = string
}

variable "waf_web_acl_arn" {
  description = "Optional WAF Web ACL ARN to associate with the public ALB."
  type        = string
  default     = ""
}

variable "db_master_username" {
  description = "Master username for RDS."
  type        = string
}

variable "db_master_password" {
  description = "Master password for RDS."
  type        = string
  sensitive   = true
}

variable "db_kms_key_arn" {
  description = "Optional existing KMS key ARN for RDS encryption."
  type        = string
  default     = ""
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

variable "extra_tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

