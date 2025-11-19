variable "topic_name" {
  description = "Name of the SNS topic for alerts."
  type        = string
}

variable "alarm_emails" {
  description = "Email addresses to subscribe to the SNS topic."
  type        = list(string)
  default     = []
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for metrics."
  type        = string
}

variable "frontend_service_name" {
  description = "Frontend ECS service name."
  type        = string
}

variable "backend_service_name" {
  description = "Backend ECS service name."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix for the Application Load Balancer."
  type        = string
}

variable "frontend_tg_name" {
  description = "Frontend target group name."
  type        = string
  default     = ""
}

variable "backend_tg_name" {
  description = "Backend target group name."
  type        = string
  default     = ""
}

variable "rds_identifier" {
  description = "RDS instance identifier."
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch dashboard widgets."
  type        = string
}

variable "tags" {
  description = "Tags to apply to monitoring resources."
  type        = map(string)
  default     = {}
}

