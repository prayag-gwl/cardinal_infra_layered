output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID of the created VPC."
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "Public subnet IDs."
}

output "private_subnet_ids" {
  value       = [for s in aws_subnet.private : s.id]
  description = "Private subnet IDs."
}

output "data_subnet_ids" {
  value       = [for s in aws_subnet.data : s.id]
  description = "Data subnet IDs (if created)."
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "Security group for the public ALB."
}

output "internal_alb_security_group_id" {
  value       = aws_security_group.internal_alb.id
  description = "Security group for the internal ALB."
}

output "ecs_security_group_id" {
  value       = aws_security_group.ecs_service.id
  description = "Security group for ECS services."
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "Security group allowing ECS to reach RDS."
}

output "flow_logs_bucket" {
  value       = try(aws_s3_bucket.flow_logs[0].id, null)
  description = "Bucket storing VPC flow logs when enabled."
}

