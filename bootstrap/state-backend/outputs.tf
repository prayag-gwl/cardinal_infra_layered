output "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.state.arn
}

output "state_lock_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  value       = aws_dynamodb_table.state_lock.name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for state encryption (if enabled)."
  value       = var.enable_kms ? aws_kms_key.state[0].arn : null
}

output "kms_alias_name" {
  description = "Alias associated with the KMS key (if enabled)."
  value       = var.enable_kms ? aws_kms_alias.state[0].name : null
}

