locals {
  kms_key_arn = var.create_kms_key ? aws_kms_key.this[0].arn : (var.kms_key_arn != "" ? var.kms_key_arn : null)
}

resource "aws_kms_key" "this" {
  count                   = var.create_kms_key && var.kms_key_arn == "" ? 1 : 0
  description             = "KMS key for RDS ${var.identifier}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  count         = length(aws_kms_key.this) > 0 ? 1 : 0
  name          = "alias/${var.identifier}-rds"
  target_key_id = aws_kms_key.this[0].key_id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-pg"
  family = var.parameter_group_family

  parameter {
    name  = "log_min_duration_statement"
    value = "2000"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier              = var.identifier
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  db_name                 = var.db_name
  username                = var.master_username
  password                = var.master_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.vpc_security_group_ids
  multi_az                = var.multi_az
  storage_encrypted       = var.storage_encrypted
  kms_key_id              = local.kms_key_arn
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  backup_retention_period = var.backup_retention_period
  backup_window           = var.preferred_backup_window
  maintenance_window      = var.preferred_maintenance_window
  deletion_protection     = true
  performance_insights_enabled            = var.performance_insights_enabled
  performance_insights_kms_key_id         = local.kms_key_arn
  iam_database_authentication_enabled     = var.enable_iam_auth
  auto_minor_version_upgrade              = true
  copy_tags_to_snapshot                   = true
  enabled_cloudwatch_logs_exports         = ["postgresql", "upgrade"]
  allow_major_version_upgrade             = false
  apply_immediately                       = false
  parameter_group_name                    = aws_db_parameter_group.this.name

  tags = var.tags
}

