variable "cluster_id"         { type = string }
variable "cluster_name"       { type = string }
variable "service_name"       { type = string }
variable "image"              { type = string }
variable "cpu" {
  type    = string
  default = "1024"
}
variable "memory" {
  type    = string
  default = "2048"
}
variable "container_name"     { type = string }
variable "container_port" {
  type    = number
  default = 80
}
variable "log_group_name"     { type = string }
variable "aws_region"         { type = string }
variable "subnet_ids"         { type = list(string) }
variable "security_group_id"  { type = string }
variable "target_group_arn"   { type = string }
variable "environment_vars" {
  type    = map(string)
  default = {}
}
variable "secrets" {
  description = "List of container secrets (name/value_from)."
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}
variable "secret_arns" {
  description = "Secret ARNs (or ARN patterns) the task role should be allowed to read."
  type        = list(string)
  default     = []
}
variable "task_role_policy_arns" {
  description = "Additional IAM policies to attach to the task role."
  type        = list(string)
  default     = []
}
variable "health_check" {
  description = "Container health check configuration."
  type = object({
    command      = list(string)
    interval     = number
    timeout      = number
    retries      = number
    start_period = number
  })
  default = null
}
variable "ephemeral_storage" {
  description = "Ephemeral storage size (GiB) for the task."
  type        = number
  default     = null
}
variable "desired_count" {
  description = "Desired task count."
  type        = number
  default     = 2
}
variable "platform_version" {
  description = "Platform version for Fargate."
  type        = string
  default     = "LATEST"
}
variable "assign_public_ip" {
  description = "Assign a public IP to tasks."
  type        = bool
  default     = false
}
variable "enable_execute_command" {
  description = "Enable ECS Exec."
  type        = bool
  default     = true
}
variable "capacity_provider_strategies" {
  description = "List of capacity provider strategy configurations."
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
      base              = 0
    }
  ]
}
variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent for deployments."
  type        = number
  default     = 50
}
variable "deployment_maximum_percent" {
  description = "Maximum healthy percent for deployments."
  type        = number
  default     = 200
}
variable "autoscaling_enabled" {
  description = "Enable target tracking auto scaling."
  type        = bool
  default     = true
}
variable "autoscaling_min_capacity" {
  description = "Minimum task count for auto scaling."
  type        = number
  default     = 2
}
variable "autoscaling_max_capacity" {
  description = "Maximum task count for auto scaling."
  type        = number
  default     = 6
}
variable "autoscaling_cpu_target" {
  description = "CPU utilization target for auto scaling."
  type        = number
  default     = 60
}
variable "autoscaling_memory_target" {
  description = "Memory utilization target for auto scaling."
  type        = number
  default     = 70
}
variable "tags" {
  type    = map(string)
  default = {}
}
