variable "aws_region" {
  description = "AWS region to deploy production infrastructure."
  type        = string
  default     = "us-west-1"
}

provider "aws" {
  region = var.aws_region
}

provider "random" {
}

