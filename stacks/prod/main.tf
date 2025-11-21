locals {
  common_tags = merge({
    Project       = var.project
    Environment   = title(var.environment)
    ProvisionedBy = "Terraform"
  }, var.extra_tags)

  # Database credentials from Secrets Manager (including DB_NAME to match dev configuration)
  db_secret_suffixes = [
    { name = "DB_HOST",     suffix = ":host::" },
    { name = "DB_NAME",     suffix = ":database::" },
    { name = "DB_PASSWORD", suffix = ":password::" },
    { name = "DB_PORT",     suffix = ":port::" },
    { name = "DB_USERNAME", suffix = ":username::" },
  ]
  
  # No DB_NAME as environment variable - it comes from Secrets Manager (matching dev config)
  db_env_vars = {}

  # Use provided secret ARN (PROD uses its own secret: cardinal/prod-db-creds)
  database_secret_arn = var.database_secret_arn
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

# Get AWS account ID and region for ALB access logs policy
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.alb_logs
  ]
}

# Wait for S3 bucket policy to propagate before creating ALBs
resource "time_sleep" "alb_logs_policy_propagation" {
  depends_on = [aws_s3_bucket_policy.alb_logs]
  create_duration = "30s"
}

# Security group for PROD ALB (allows inbound 80/443 from Internet)
resource "aws_security_group" "prod_alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Allow internet access to PROD ALB"
  vpc_id      = var.existing_vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-alb-sg" })
}

# Security group for PROD ECS tasks (allows inbound from ALB, outbound to RDS)
resource "aws_security_group" "prod_ecs" {
  name        = "${var.project}-${var.environment}-ecs-sg"
  description = "Allow ALB to reach PROD ECS services and ECS to reach RDS"
  vpc_id      = var.existing_vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_alb.id]
  }

  ingress {
    description     = "Allow traffic from ALB on container port"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-ecs-sg" })
}

# Security group rule: Allow ECS to connect to existing RDS
resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.prod_ecs.id
  security_group_id        = var.existing_rds_sg_id
  description              = "Allow PostgreSQL from PROD ECS tasks"
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
  repository_names = ["${var.project}-frontend-${var.environment}", "${var.project}-backend-${var.environment}"]
  tags             = local.common_tags
}

module "ecs_cluster" {
  source                     = "../../modules/ecs-cluster"
  name                       = "${var.project}-${var.environment}-cluster"
  tags                       = local.common_tags
  exec_log_group_name        = "/aws/ecs/${var.project}-${var.environment}-exec"
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

# Single ALB for both PROD frontend and backend services
# ALB Name: cardinal-prod-alb
# Scheme: Internet-facing
# HTTP:80 → Redirect to HTTPS:443
# HTTPS:443 → Host-based routing (beta.cedu.app → frontend, api.cedu.app → backend)
module "alb_prod" {
  source                 = "../../modules/alb"
  name                   = "cardinal-prod-alb"
  vpc_id                 = var.existing_vpc_id
  subnet_ids             = var.existing_public_subnets
  security_group_ids     = [aws_security_group.prod_alb.id]
  internal               = false
  certificate_arn        = var.frontend_certificate_arn != "" ? var.frontend_certificate_arn : var.backend_certificate_arn
  enable_https_listener  = (var.frontend_certificate_arn != "" || var.backend_certificate_arn != "")
  enable_http_redirect   = true  # Always redirect HTTP to HTTPS
  frontend_health_path   = var.frontend_health_path
  backend_health_path    = var.backend_health_path
  enable_frontend_target = true
  enable_backend_target  = true
  frontend_target_port   = 3000
  backend_target_port    = 3000
  frontend_host_header   = var.frontend_host_header  # beta.cedu.app
  backend_host_header    = var.backend_host_header   # api.cedu.app
  frontend_target_group_name = "tg-cardinal-prod-frontend-3000"
  backend_target_group_name  = "tg-cardinal-prod-backend-3000"
  access_logs_bucket     = aws_s3_bucket.alb_logs.bucket
  access_logs_prefix     = "prod"
  waf_web_acl_arn        = var.waf_web_acl_arn
  tags                   = local.common_tags

  depends_on = [time_sleep.alb_logs_policy_propagation]
}

module "frontend_service" {
  source             = "../../modules/ecs-service"
  cluster_id         = module.ecs_cluster.id
  cluster_name       = module.ecs_cluster.name
  service_name       = "${var.project}-${var.environment}-frontend"
  image              = var.frontend_image
  container_name     = "${var.project}-frontend"
  log_group_name     = "/ecs/${var.project}-${var.environment}-frontend"
  aws_region         = var.aws_region
  subnet_ids         = var.existing_private_subnets
  security_group_id  = aws_security_group.prod_ecs.id
  target_group_arn   = module.alb_prod.tg_frontend_arn
  environment_vars   = merge(var.frontend_env, local.db_env_vars)
  memory             = "3072"
  container_port     = 3000
  health_check = {
    command      = ["CMD-SHELL", format("curl -f http://localhost:%d%s || exit 1", 3000, var.frontend_health_path)]
    interval     = 30
    timeout      = 5
    retries      = 3
    start_period = 60
  }
  ephemeral_storage       = 21
  secrets                 = [for entry in local.db_secret_suffixes : {
    name       = entry.name
    value_from = "${local.database_secret_arn}${entry.suffix}"
  }]
  secret_arns             = ["${local.database_secret_arn}*"]
  assign_public_ip        = false
  autoscaling_cpu_target  = 60
  autoscaling_memory_target = 70
  tags                    = local.common_tags
}

module "backend_service" {
  source             = "../../modules/ecs-service"
  cluster_id         = module.ecs_cluster.id
  cluster_name       = module.ecs_cluster.name
  service_name       = "${var.project}-${var.environment}-backend"
  image              = var.backend_image
  container_name     = "${var.project}-backend"
  log_group_name     = "/ecs/${var.project}-${var.environment}-backend"
  aws_region         = var.aws_region
  subnet_ids         = var.existing_private_subnets
  security_group_id  = aws_security_group.prod_ecs.id
  target_group_arn   = module.alb_prod.tg_backend_arn
  environment_vars   = merge(var.backend_env, local.db_env_vars)
  memory             = "3072"
  container_port     = 3000
  desired_count      = 1
  autoscaling_enabled = false
  health_check = {
    command      = ["CMD-SHELL", format("curl -f http://localhost:%d%s || exit 1", 3000, var.backend_health_path)]
    interval     = 30
    timeout      = 5
    retries      = 3
    start_period = 60
  }
  ephemeral_storage = 21
  secrets = [for entry in local.db_secret_suffixes : {
    name       = entry.name
    value_from = "${local.database_secret_arn}${entry.suffix}"
  }]
  secret_arns      = ["${local.database_secret_arn}*"]
  assign_public_ip  = false
  tags              = local.common_tags
}

# Reference existing RDS database instance (PROD reuses DEV RDS)
data "aws_db_instance" "existing" {
  db_instance_identifier = var.existing_rds_identifier
}

# Reference PROD Secrets Manager secret (cardinal/prod-db-creds)
data "aws_secretsmanager_secret" "db_credentials" {
  arn = var.database_secret_arn
}

module "monitoring" {
  source                = "../../modules/monitoring"
  topic_name            = "${var.project}-${var.environment}-alerts"
  alarm_emails          = var.alarm_emails
  ecs_cluster_name      = module.ecs_cluster.name
  frontend_service_name = module.frontend_service.service_name
  backend_service_name  = module.backend_service.service_name
  alb_arn_suffix        = module.alb_prod.arn_suffix
  frontend_tg_name      = module.alb_prod.tg_frontend_name
  backend_tg_name       = module.alb_prod.tg_backend_name
  rds_identifier        = data.aws_db_instance.existing.db_instance_identifier
  aws_region            = var.aws_region
  tags                  = local.common_tags
}

module "backup" {
  source              = "../../modules/backup"
  vault_name          = "${var.project}-${var.environment}-db-backup-vault"
  plan_name           = "${var.project}-${var.environment}-db-backup-plan"
  backup_resources    = [data.aws_db_instance.existing.db_instance_arn]
  tags                = local.common_tags
  sns_topic_arn       = ""
  copy_actions        = var.backup_copy_actions
  # Use existing KMS key - set via GitHub variable USW1_BACKUP_KMS_KEY_ARN
  kms_key_arn         = var.backup_kms_key_arn != "" ? var.backup_kms_key_arn : ""
  create_kms_key      = false  # Never create new KMS key, always use existing
  # Use existing backup vault - the existing backup plan is associated with a vault
  # If the vault name is not provided, we'll try to create it (which will fail if it exists)
  # The vault name should match the one associated with the existing backup plan
  existing_vault_name = var.existing_backup_vault_name != "" ? var.existing_backup_vault_name : ""
  # Use existing backup plan - set via GitHub variable USW1_EXISTING_BACKUP_PLAN_ID
  existing_plan_id    = var.existing_backup_plan_id != "" ? var.existing_backup_plan_id : ""
  create_backup_plan  = var.existing_backup_plan_id == ""  # Only create plan if existing_plan_id is not provided
  # Use existing IAM role - set via GitHub variable USW1_BACKUP_IAM_ROLE_ARN
  iam_role_arn        = var.backup_iam_role_arn != "" ? var.backup_iam_role_arn : ""
  create_backup_role  = var.backup_iam_role_arn == ""  # Only create role if IAM role ARN is not provided
}

