variable "cluster_id"         { type = string }
variable "service_name"       { type = string }
variable "image"              { type = string }
variable "cpu" {
  type    = string
  default = "512"
}
variable "memory" {
  type    = string
  default = "1024"
}
variable "container_name"     { type = string }
variable "container_port" {
  type    = number
  default = 3000
}
variable "log_group_name"     { type = string }
variable "aws_region"         { type = string }
variable "subnet_ids"         { type = list(string) }
variable "security_group_id"  { type = string }
variable "target_group_arn"   { type = string }
variable "environment_vars" {
  type    = map(string)
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
