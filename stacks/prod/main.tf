locals {
  common_tags = merge({
    Project       = var.project
    Environment   = title(var.environment)
    ProvisionedBy = "Terraform"
  }, var.extra_tags)
}

resource "random_string" "alb_logs" {
  length  = 6
  upper   = false
  special = false
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project}-${var.environment}-alb-logs-${random_string.alb_logs.result}"
  tags   = merge(local.common_tags, { Purpose = "alb-logs" })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "networking" {
  source                = "../../modules/networking"
  azs                   = var.azs
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  vpc_cidr              = "10.0.0.0/16"
  tags                  = local.common_tags
}

module "logging" {
  source     = "../../modules/logging"
  log_groups = [
    "/ecs/${var.project}-${var.environment}-frontend",
    "/ecs/${var.project}-${var.environment}-backend",
    "/aws/ecs/${var.project}-${var.environment}-exec",
  ]
  retention_in_days = 30
  tags              = local.common_tags
}

module "ecr" {
  source           = "../../modules/ecr"
  repository_names = ["${var.project}-frontend", "${var.project}-backend"]
  tags             = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_exec" {
  name              = "/aws/ecs/${var.project}-${var.environment}-exec"
  retention_in_days = 30
  tags              = local.common_tags
}

module "ecs_cluster" {
  source                     = "../../modules/ecs-cluster"
  name                       = "${var.project}-${var.environment}-cluster"
  tags                       = local.common_tags
  exec_log_group_name        = aws_cloudwatch_log_group.ecs_exec.name
  capacity_providers         = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
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

module "alb_frontend" {
  source                   = "../../modules/alb"
  name                     = "${var.project}-${var.environment}-frontend-alb"
  vpc_id                   = module.networking.vpc_id
  subnet_ids               = module.networking.public_subnet_ids
  security_group_ids       = [module.networking.alb_security_group_id]
  internal                 = false
  certificate_arn          = var.frontend_certificate_arn
  frontend_health_path     = var.frontend_health_path
  backend_health_path      = var.backend_health_path
  enable_backend_target    = false
  access_logs_bucket       = aws_s3_bucket.alb_logs.bucket
  access_logs_prefix       = "frontend"
  waf_web_acl_arn          = var.waf_web_acl_arn
  tags                     = local.common_tags
}

module "alb_backend" {
  source                   = "../../modules/alb"
  name                     = "${var.project}-${var.environment}-backend-alb"
  vpc_id                   = module.networking.vpc_id
  subnet_ids               = module.networking.private_subnet_ids
  security_group_ids       = [module.networking.internal_alb_security_group_id]
  internal                 = true
  certificate_arn          = var.backend_certificate_arn
  enable_frontend_target   = false
  backend_health_path      = var.backend_health_path
  access_logs_bucket       = aws_s3_bucket.alb_logs.bucket
  access_logs_prefix       = "backend"
  enable_http_redirect     = false
  tags                     = local.common_tags
}

module "frontend_service" {
  source                    = "../../modules/ecs-service"
  cluster_id                = module.ecs_cluster.id
  cluster_name              = module.ecs_cluster.name
  service_name              = "${var.project}-${var.environment}-frontend"
  image                     = var.frontend_image
  container_name            = "${var.project}-frontend"
  log_group_name            = "/ecs/${var.project}-${var.environment}-frontend"
  aws_region                = var.aws_region
  subnet_ids                = module.networking.private_subnet_ids
  security_group_id         = module.networking.ecs_security_group_id
  target_group_arn          = module.alb_frontend.tg_frontend_arn
  environment_vars          = var.frontend_env
  assign_public_ip          = false
  autoscaling_cpu_target    = 60
  autoscaling_memory_target = 70
  tags                      = local.common_tags
}

module "backend_service" {
  source                    = "../../modules/ecs-service"
  cluster_id                = module.ecs_cluster.id
  cluster_name              = module.ecs_cluster.name
  service_name              = "${var.project}-${var.environment}-backend"
  image                     = var.backend_image
  container_name            = "${var.project}-backend"
  log_group_name            = "/ecs/${var.project}-${var.environment}-backend"
  aws_region                = var.aws_region
  subnet_ids                = module.networking.private_subnet_ids
  security_group_id         = module.networking.ecs_security_group_id
  target_group_arn          = module.alb_backend.tg_backend_arn
  environment_vars          = var.backend_env
  assign_public_ip          = false
  autoscaling_cpu_target    = 60
  autoscaling_memory_target = 70
  tags                      = local.common_tags
}

module "rds" {
  source                 = "../../modules/rds"
  identifier             = "${var.project}-${var.environment}-db"
  db_name                = "${var.project}_${var.environment}"
  master_username        = var.db_master_username
  master_password        = var.db_master_password
  subnet_ids             = module.networking.private_subnet_ids
  vpc_security_group_ids = [module.networking.rds_security_group_id]
  kms_key_arn            = var.db_kms_key_arn
  tags                   = local.common_tags
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project}/${var.environment}/db"
  tags = local.common_tags
}

module "monitoring" {
  source                  = "../../modules/monitoring"
  topic_name              = "${var.project}-${var.environment}-alerts"
  alarm_emails            = var.alarm_emails
  ecs_cluster_name        = module.ecs_cluster.name
  frontend_service_name   = module.frontend_service.service_name
  backend_service_name    = module.backend_service.service_name
  alb_arn_suffix          = module.alb_frontend.arn_suffix
  frontend_tg_name        = module.alb_frontend.tg_frontend_name
  backend_tg_name         = coalesce(module.alb_backend.tg_backend_name, module.alb_frontend.tg_backend_name)
  rds_identifier          = module.rds.identifier
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = var.db_master_password
    endpoint = module.rds.endpoint
    port     = module.rds.port
  })
}

module "backup" {
  source            = "../../modules/backup"
  vault_name        = "${var.project}-${var.environment}-db-backup-vault"
  plan_name         = "${var.project}-${var.environment}-db-backup-plan"
  backup_resources  = module.rds.arn != "" ? [module.rds.arn] : []
  tags              = local.common_tags
  sns_topic_arn     = module.monitoring.sns_topic_arn
  copy_actions      = var.backup_copy_actions
}

