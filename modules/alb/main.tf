locals {
  default_target_group_arn = var.enable_frontend_target ? try(aws_lb_target_group.frontend[0].arn, null) : try(aws_lb_target_group.backend[0].arn, null)
}

resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
  enable_http2       = true
  idle_timeout       = 60
  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "frontend" {
  count    = var.enable_frontend_target ? 1 : 0
  name     = "tg-${var.name}-frontend-${var.frontend_target_port}"
  port     = var.frontend_target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path    = var.frontend_health_path
    matcher = "200-399"
  }

  tags = var.tags
}

resource "aws_lb_target_group" "backend" {
  count    = var.enable_backend_target ? 1 : 0
  name     = "tg-${var.name}-backend-${var.backend_target_port}"
  port     = var.backend_target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path    = var.backend_health_path
    matcher = "200-399"
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_http_redirect ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_http_redirect ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = local.default_target_group_arn
    }
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

resource "aws_lb_listener" "https" {
  count             = var.enable_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = local.default_target_group_arn
  }
}

resource "aws_lb_listener_rule" "http_api" {
  count        = var.enable_frontend_target && var.enable_backend_target ? 1 : 0
  listener_arn = var.enable_https_listener ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend[0].arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_web_acl_arn != "" ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}
