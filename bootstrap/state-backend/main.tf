provider "aws" {
  region = var.region
}

locals {
  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Stack     = "state-backend"
    },
    var.tags,
  )
}

resource "aws_kms_key" "state" {
  count                   = var.enable_kms ? 1 : 0
  description             = "KMS key for encrypting Terraform state bucket"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "state" {
  count         = var.enable_kms ? 1 : 0
  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.state[0].key_id
}

resource "aws_s3_bucket" "state" {
  bucket        = var.bucket_name
  force_destroy = var.bucket_force_destroy

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_kms ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_kms ? aws_kms_key.state[0].arn : null
    }
  }
}

resource "aws_dynamodb_table" "state_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.common_tags
}

