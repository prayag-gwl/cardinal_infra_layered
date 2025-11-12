terraform {
  required_version = ">= 1.5.0"
}

variable "aws_region"            { type = string }
variable "project"               { type = string }
variable "environment"           { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "ecs_service_sg_id"     { type = string }
variable "frontend_image"        { type = string }
variable "frontend_health_path" {
  type    = string
  default = "/health"
}
variable "frontend_env" {
  type    = map(string)
  default = {}
}

module "common" {
  source      = "../../../modules/common"
  project     = var.project
  environment = var.environment
}

module "logging" {
  source            = "../../../modules/logging"
  log_groups        = ["/ecs/${var.project}-frontend"]
  retention_in_days = 30
  tags              = module.common.tags
}

module "ecs_cluster" {
  source = "../../../modules/ecs-cluster"
  name   = "${var.project}-${var.environment}-app-cluster"
  tags   = module.common.tags
}

module "alb" {
  source                = "../../../modules/alb"
  name                  = "${var.project}-${var.environment}-app-alb"
  vpc_id                = var.vpc_id
  subnet_ids            = var.public_subnet_ids
  security_group_ids    = [var.alb_security_group_id]
  enable_https_listener = false
  enable_http_redirect  = false
  frontend_health_path  = var.frontend_health_path
  backend_health_path   = "/health"  # Default for single service
  tags                  = module.common.tags
}

module "frontend_service" {
  source            = "../../../modules/ecs-service"
  cluster_id        = module.ecs_cluster.id
  cluster_name      = module.ecs_cluster.name
  service_name      = "${var.project}-${var.environment}-frontend"
  image             = var.frontend_image
  container_name    = "${var.project}-frontend"
  log_group_name    = "/ecs/${var.project}-frontend"
  aws_region        = var.aws_region
  subnet_ids        = var.public_subnet_ids
  security_group_id = var.ecs_service_sg_id
  target_group_arn  = module.alb.tg_frontend_arn
  environment_vars  = var.frontend_env
  desired_count     = 1
  autoscaling_enabled = false
  assign_public_ip  = true
  tags              = module.common.tags
}

