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
  health_check {
    path    = var.frontend_health_path
    matcher = "200-399"
  }
  tags = var.tags
}
resource "aws_lb_target_group" "backend" {
  name     = "tg-${var.name}-backend-3000"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path    = var.backend_health_path
    matcher = "200"
  }
  tags = var.tags
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
resource "aws_lb_listener_rule" "http_api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
output "dns_name"        { value = aws_lb.public.dns_name }
output "tg_frontend_arn" { value = aws_lb_target_group.frontend.arn }
output "tg_backend_arn"  { value = aws_lb_target_group.backend.arn }
