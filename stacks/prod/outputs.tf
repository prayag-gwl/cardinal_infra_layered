output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_alb_dns" {
  value = module.alb_frontend.dns_name
}

output "internal_alb_dns" {
  value = module.alb_backend.dns_name
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.name
}

output "frontend_service_name" {
  value = module.frontend_service.service_name
}

output "backend_service_name" {
  value = module.backend_service.service_name
}

output "rds_endpoint" {
  value = data.aws_db_instance.existing.endpoint
}

output "db_secret_arn" {
  value = data.aws_secretsmanager_secret.db_credentials.arn
}

output "backup_vault_arn" {
  value = module.backup.vault_arn
}

output "monitoring_dashboard" {
  value = module.monitoring.dashboard_name
}

