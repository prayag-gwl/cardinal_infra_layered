#!/usr/bin/env bash
set -euo pipefail
BASE="/home/gwl/Documents/cardinal-infra-layered"

# modules/common
cat > "$BASE/modules/common/variables.tf" <<'EOT'
variable "project" { type = string }
variable "environment" { type = string }
variable "extra_tags" { type = map(string) default = {} }
EOT
cat > "$BASE/modules/common/main.tf" <<'EOT'
locals {
  tags = merge(
    {
      Project       = var.project
      Environment   = title(var.environment)
      ProvisionedBy = "Terraform"
      ManagedBy     = "DevOps Team"
    },
    var.extra_tags
  )
}
output "tags" { value = local.tags }
EOT

# modules/ecr
cat > "$BASE/modules/ecr/variables.tf" <<'EOT'
variable "repository_names" { type = list(string) }
variable "tags" { type = map(string) default = {} }
EOT
cat > "$BASE/modules/ecr/main.tf" <<'EOT'
resource "aws_ecr_repository" "repo" {
  for_each = toset(var.repository_names)
  name     = each.value
  tags     = var.tags
}
output "repositories" {
  value = { for k, r in aws_ecr_repository.repo : k => r.repository_url }
}
EOT

# modules/logging
cat > "$BASE/modules/logging/variables.tf" <<'EOT'
variable "log_groups" { type = list(string) }
variable "retention_in_days" { type = number default = 30 }
variable "tags" { type = map(string) default = {} }
EOT
cat > "$BASE/modules/logging/main.tf" <<'EOT'
resource "aws_cloudwatch_log_group" "lg" {
  for_each          = toset(var.log_groups)
  name              = each.value
  retention_in_days = var.retention_in_days
  tags              = var.tags
}
output "names" { value = [for lg in aws_cloudwatch_log_group.lg : lg.name] }
EOT

# modules/ecs-cluster
cat > "$BASE/modules/ecs-cluster/variables.tf" <<'EOT'
variable "name" { type = string }
variable "tags" { type = map(string) default = {} }
EOT
cat > "$BASE/modules/ecs-cluster/main.tf" <<'EOT'
resource "aws_ecs_cluster" "this" {
  name = var.name
  setting { name = "containerInsights"; value = "enabled" }
  tags = var.tags
}
output "id"   { value = aws_ecs_cluster.this.id }
output "name" { value = aws_ecs_cluster.this.name }
EOT

# modules/alb
cat > "$BASE/modules/alb/variables.tf" <<'EOT'
variable "name"                  { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "frontend_health_path"  { type = string }
variable "backend_health_path"   { type = string }
variable "tags"                  { type = map(string) default = {} }
EOT
cat > "$BASE/modules/alb/main.tf" <<'EOT'
resource "aws_lb" "public" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
  enable_http2       = true
  idle_timeout       = 60
  tags               = var.tags
}
resource "aws_lb_target_group" "frontend" {
  name     = "tg-${var.name}-frontend-3000"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check { path = var.frontend_health_path, matcher = "200-399" }
  tags = var.tags
}
resource "aws_lb_target_group" "backend" {
  name     = "tg-${var.name}-backend-3000"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check { path = var.backend_health_path, matcher = "200" }
  tags = var.tags
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"
  default_action { type = "forward"; target_group_arn = aws_lb_target_group.frontend.arn }
}
resource "aws_lb_listener_rule" "http_api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1
  action { type = "forward"; target_group_arn = aws_lb_target_group.backend.arn }
  condition { path_pattern { values = ["/api/*"] } }
}
output "dns_name"        { value = aws_lb.public.dns_name }
output "tg_frontend_arn" { value = aws_lb_target_group.frontend.arn }
output "tg_backend_arn"  { value = aws_lb_target_group.backend.arn }
EOT

# modules/ecs-service
cat > "$BASE/modules/ecs-service/variables.tf" <<'EOT'
variable "cluster_id"         { type = string }
variable "service_name"       { type = string }
variable "image"              { type = string }
variable "cpu"                { type = string default = "512" }
variable "memory"             { type = string default = "1024" }
variable "container_name"     { type = string }
variable "container_port"     { type = number default = 3000 }
variable "log_group_name"     { type = string }
variable "aws_region"         { type = string }
variable "subnet_ids"         { type = list(string) }
variable "security_group_id"  { type = string }
variable "target_group_arn"   { type = string }
variable "environment_vars"   { type = map(string) default = {} }
variable "tags"               { type = map(string) default = {} }
EOT
cat > "$BASE/modules/ecs-service/main.tf" <<'EOT'
resource "aws_iam_role" "task_exec" {
  name               = "${var.service_name}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["ecs-tasks.amazonaws.com"] }
  }
}
resource "aws_iam_role_policy_attachment" "exec" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_task_definition" "td" {
  family                   = "${var.service_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_exec.arn
  container_definitions = jsonencode([
    {
      name         = var.container_name
      image        = var.image
      essential    = true
      portMappings = [{ containerPort = var.container_port, hostPort = var.container_port }]
      environment  = [for k, v in var.environment_vars : { name = k, value = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
resource "aws_ecs_service" "svc" {
  name            = "${var.service_name}-service"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.td.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
  deployment_circuit_breaker { enable = true, rollback = true }
  lifecycle { ignore_changes = [task_definition] }
  tags = var.tags
}
output "service_name" { value = aws_ecs_service.svc.name }
EOT

# stacks/dev
cat > "$BASE/stacks/dev/versions.tf" <<'EOT'
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
  backend "s3" {}
}
EOT
cat > "$BASE/stacks/dev/providers.tf" <<'EOT'
provider "aws" { region = var.aws_region }
EOT
cat > "$BASE/stacks/dev/backend.tf" <<'EOT'
# Provide via terraform init:
#  -backend-config="bucket=<state-bucket>"
#  -backend-config="key=envs/dev/terraform.tfstate"
#  -backend-config="region=us-west-1"
#  -backend-config="dynamodb_table=<lock-table>"
EOT
cat > "$BASE/stacks/dev/main.tf" <<'EOT'
variable "aws_region"            { type = string }
variable "project"               { type = string }
variable "environment"           { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "ecs_service_sg_id"     { type = string }
variable "frontend_image"        { type = string }
variable "backend_image"         { type = string }
variable "frontend_health_path"  { type = string default = "/health" }
variable "backend_health_path"   { type = string default = "/api/cardinal-education-service/v1/health" }
variable "frontend_env"          { type = map(string) default = {} }
variable "backend_env"           { type = map(string) default = {} }

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
EOT
cat > "$BASE/stacks/dev/outputs.tf" <<'EOT'
output "alb_dns_name"          { value = module.alb.dns_name }
output "ecs_cluster_name"      { value = module.ecs_cluster.name }
output "frontend_service_name" { value = module.frontend_service.service_name }
output "backend_service_name"  { value = module.backend_service.service_name }
EOT
cat > "$BASE/stacks/dev/terraform.tfvars" <<'EOT'
aws_region            = "us-west-1"
project               = "cardinal"
environment           = "dev"
vpc_id                = "vpc-0d55fd072ff0e07c6"
public_subnet_ids     = ["subnet-064f7edf88ed74436", "subnet-0369bc2294fb8dc4e"]
alb_security_group_id = "sg-064c6d22a3c4976ed"
ecs_service_sg_id     = "sg-014871e60b1d05a0f"
frontend_image        = "<acct>.dkr.ecr.us-west-1.amazonaws.com/cardinal-frontend:develop-latest"
backend_image         = "<acct>.dkr.ecr.us-west-1.amazonaws.com/cardinal-backend:develop-latest"
frontend_health_path  = "/health"
backend_health_path   = "/api/cardinal-education-service/v1/health"
frontend_env = {
  NEXT_PUBLIC_API_BASE_URL = "http://cardinal-alb-public-1130134455.us-west-1.elb.amazonaws.com/api/cardinal-education-service/v1"
  API_SECRET_KEY           = "cardinal_secret_key"
}
backend_env = {
  NODE_ENV     = "production"
  FRONTEND_URL = "http://cardinal-alb-public-1130134455.us-west-1.elb.amazonaws.com"
}
EOT
echo "Files populated under: $BASE"
