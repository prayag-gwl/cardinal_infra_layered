output "prod_alb_dns_name" {
  description = "DNS name of the PROD ALB (cardinal-prod-alb)."
  value       = module.alb_prod.dns_name
}

output "prod_alb_arn" {
  description = "ARN of the PROD ALB (cardinal-prod-alb)."
  value       = module.alb_prod.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (port 443) on PROD ALB."
  value       = module.alb_prod.https_listener_arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener (port 80) on PROD ALB."
  value       = module.alb_prod.http_listener_arn
}

output "prod_backend_tg_arn" {
  description = "ARN of the backend target group."
  value       = module.alb_prod.tg_backend_arn
}

output "prod_frontend_tg_arn" {
  description = "ARN of the frontend target group."
  value       = module.alb_prod.tg_frontend_arn
}

output "prod_cluster_arn" {
  description = "ARN of the PROD ECS cluster."
  value       = module.ecs_cluster.id
}

output "prod_service_backend_arn" {
  description = "ARN of the PROD backend service (constructed from cluster and service name)."
  value       = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${module.ecs_cluster.name}/${module.backend_service.service_name}"
}

output "prod_service_frontend_arn" {
  description = "ARN of the PROD frontend service (constructed from cluster and service name)."
  value       = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${module.ecs_cluster.name}/${module.frontend_service.service_name}"
}

output "ecs_cluster_name" {
  description = "Name of the PROD ECS cluster."
  value       = module.ecs_cluster.name
}

output "frontend_service_name" {
  description = "Name of the PROD frontend service."
  value       = module.frontend_service.service_name
}

output "backend_service_name" {
  description = "Name of the PROD backend service."
  value       = module.backend_service.service_name
}

output "rds_endpoint" {
  description = "Endpoint of the existing RDS instance (reused from DEV)."
  value       = data.aws_db_instance.existing.endpoint
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials (PROD secret: cardinal/prod-db-creds)."
  value       = data.aws_secretsmanager_secret.db_credentials.arn
}

output "backup_vault_arn" {
  description = "ARN of the backup vault."
  value       = module.backup.vault_arn
}

output "monitoring_dashboard" {
  description = "Name of the CloudWatch dashboard."
  value       = module.monitoring.dashboard_name
}

