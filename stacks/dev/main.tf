variable "aws_region"            { type = string }
variable "project"               { type = string }
variable "environment"           { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "ecs_service_sg_id"     { type = string }
variable "frontend_image"        { type = string }
variable "backend_image"         { type = string }
variable "frontend_health_path" {
  type    = string
  default = "/health"
}
variable "backend_health_path" {
  type    = string
  default = "/api/cardinal-education-service/v1/health"
}
variable "frontend_env" {
  type    = map(string)
  default = {}
}
variable "backend_env" {
  type    = map(string)
  default = {}
}

module "common" {
  source      = "../../modules/common"
  project     = var.project
  environment = var.environment
}
module "ecr" {
  source           = "../../modules/ecr"
  repository_names = ["${var.project}-frontend", "${var.project}-backend"]
  tags             = module.common.tags
}
module "logging" {
  source            = "../../modules/logging"
  log_groups        = ["/ecs/${var.project}-frontend", "/ecs/${var.project}-backend"]
  retention_in_days = 30
  tags              = module.common.tags
}
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"
  name   = "${var.project}-${var.environment}-cluster"
  tags   = module.common.tags
}
module "alb" {
  source                = "../../modules/alb"
  name                  = "${var.project}-alb-public"
  vpc_id                = var.vpc_id
  public_subnet_ids     = var.public_subnet_ids
  alb_security_group_id = var.alb_security_group_id
  frontend_health_path  = var.frontend_health_path
  backend_health_path   = var.backend_health_path
  tags                  = module.common.tags
}
module "frontend_service" {
  source            = "../../modules/ecs-service"
  cluster_id        = module.ecs_cluster.id
  service_name      = "${var.project}-${var.environment}-frontend"
  image             = var.frontend_image
  container_name    = "${var.project}-frontend"
  log_group_name    = "/ecs/${var.project}-frontend"
  aws_region        = var.aws_region
  subnet_ids        = var.public_subnet_ids
  security_group_id = var.ecs_service_sg_id
  target_group_arn  = module.alb.tg_frontend_arn
  environment_vars  = var.frontend_env
  tags              = module.common.tags
}
module "backend_service" {
  source            = "../../modules/ecs-service"
  cluster_id        = module.ecs_cluster.id
  service_name      = "${var.project}-${var.environment}-backend"
  image             = var.backend_image
  container_name    = "${var.project}-backend"
  log_group_name    = "/ecs/${var.project}-backend"
  aws_region        = var.aws_region
  subnet_ids        = var.public_subnet_ids
  security_group_id = var.ecs_service_sg_id
  target_group_arn  = module.alb.tg_backend_arn
  environment_vars  = var.backend_env
  tags              = module.common.tags
}
