output "endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "RDS endpoint."
}

output "port" {
  value       = aws_db_instance.this.port
  description = "Database port."
}

output "identifier" {
  value       = aws_db_instance.this.id
  description = "Database identifier."
}

output "arn" {
  value       = aws_db_instance.this.arn
  description = "ARN of the RDS instance."
}

output "kms_key_arn" {
  value       = local.kms_key_arn
  description = "KMS key ARN used for encryption."
}

output "db_subnet_group" {
  value       = aws_db_subnet_group.this.name
  description = "Name of the DB subnet group."
}

