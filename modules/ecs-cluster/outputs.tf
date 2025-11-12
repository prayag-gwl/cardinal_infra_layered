output "id" {
  value       = aws_ecs_cluster.this.id
  description = "ID of the ECS cluster."
}

output "name" {
  value       = aws_ecs_cluster.this.name
  description = "Name of the ECS cluster."
}

output "capacity_providers" {
  value       = try(aws_ecs_cluster_capacity_providers.this[0].capacity_providers, [])
  description = "Capacity providers associated with the cluster."
}

