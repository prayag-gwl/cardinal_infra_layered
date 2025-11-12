output "dns_name" {
  value       = aws_lb.this.dns_name
  description = "DNS name of the load balancer."
}

output "arn" {
  value       = aws_lb.this.arn
  description = "ARN of the load balancer."
}

output "arn_suffix" {
  value       = aws_lb.this.arn_suffix
  description = "ARN suffix of the load balancer."
}

output "tg_frontend_arn" {
  value       = try(aws_lb_target_group.frontend[0].arn, null)
  description = "Frontend target group ARN (if created)."
}

output "tg_backend_arn" {
  value       = try(aws_lb_target_group.backend[0].arn, null)
  description = "Backend target group ARN (if created)."
}

output "tg_frontend_name" {
  value       = try(aws_lb_target_group.frontend[0].name, null)
  description = "Frontend target group name."
}

output "tg_backend_name" {
  value       = try(aws_lb_target_group.backend[0].name, null)
  description = "Backend target group name."
}

