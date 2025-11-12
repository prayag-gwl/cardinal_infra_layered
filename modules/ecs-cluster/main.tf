resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  dynamic "configuration" {
    for_each = var.enable_execute_command ? [1] : []
    content {
      execute_command_configuration {
        logging = var.exec_log_group_name != "" ? "OVERRIDE" : "DEFAULT"
        dynamic "log_configuration" {
          for_each = var.exec_log_group_name != "" ? [1] : []
          content {
            cloud_watch_log_group_name = var.exec_log_group_name
          }
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count         = length(var.capacity_providers) > 0 ? 1 : 0
  cluster_name  = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = lookup(default_capacity_provider_strategy.value, "base", 0)
    }
  }
}

output "id" {
  value = aws_ecs_cluster.this.id
}

output "name" {
  value = aws_ecs_cluster.this.name
}
