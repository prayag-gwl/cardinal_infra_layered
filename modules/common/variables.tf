variable "project" { type = string }
variable "environment" { type = string }
variable "extra_tags" {
  type    = map(string)
  default = {}
}
