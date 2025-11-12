variable "name"                  { type = string }
variable "vpc_id"                { type = string }
variable "subnet_ids"            { type = list(string) }
variable "security_group_ids"    { type = list(string) }
variable "internal" {
  description = "Whether the ALB is internal."
  type        = bool
  default     = false
}
variable "enable_https_listener" {
  description = "Whether to create an HTTPS listener on port 443."
  type        = bool
  default     = true
}
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listeners."
  type        = string
  default     = ""
}
variable "enable_http_redirect" {
  description = "Redirect HTTP 80 to HTTPS 443 when true."
  type        = bool
  default     = true
}
variable "frontend_health_path" {
  description = "Health check path for the frontend target group."
  type        = string
  default     = "/health"
}
variable "backend_health_path" {
  description = "Health check path for the backend target group."
  type        = string
  default     = "/api/health"
}
variable "enable_frontend_target" {
  description = "Create a target group for the frontend service."
  type        = bool
  default     = true
}
variable "enable_backend_target" {
  description = "Create a target group for the backend service."
  type        = bool
  default     = true
}
variable "frontend_target_port" {
  description = "Frontend target group port."
  type        = number
  default     = 3000
}
variable "backend_target_port" {
  description = "Backend target group port."
  type        = number
  default     = 3000
}
variable "access_logs_bucket" {
  description = "S3 bucket name to store ALB access logs."
  type        = string
  default     = ""
}
variable "access_logs_prefix" {
  description = "Prefix within the access log bucket."
  type        = string
  default     = ""
}
variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer."
  type        = bool
  default     = true
}
variable "waf_web_acl_arn" {
  description = "ARN of AWS WAFv2 Web ACL to associate."
  type        = string
  default     = ""
}
variable "tags" {
  description = "Tags to apply to the ALB resources."
  type        = map(string)
  default     = {}
}
