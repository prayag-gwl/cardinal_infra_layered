variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones to use."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets. Must match the AZ count."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets. Must match the AZ count."
  type        = list(string)
}

variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC flow logs."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all networking resources."
  type        = map(string)
  default     = {}
}

