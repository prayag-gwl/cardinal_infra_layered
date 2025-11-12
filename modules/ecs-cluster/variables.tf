variable "name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the ECS cluster."
  type        = map(string)
  default     = {}
}

variable "capacity_providers" {
  description = "Capacity providers to associate with the cluster."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy."
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

variable "enable_execute_command" {
  description = "Enable ECS Exec on the cluster."
  type        = bool
  default     = true
}

variable "exec_log_group_name" {
  description = "CloudWatch log group name for ECS Exec logs."
  type        = string
  default     = ""
}
