locals {
  # Default target group is frontend (for default action on HTTPS listener)
  default_target_group_arn = var.enable_frontend_target ? aws_lb_target_group.frontend[0].arn : (var.enable_backend_target ? aws_lb_target_group.backend[0].arn : null)
  # Use provided target group names or generate from ALB name
  frontend_tg_name         = var.frontend_target_group_name != "" ? substr(var.frontend_target_group_name, 0, 32) : substr("${var.name}-fe-3000", 0, 32)
  backend_tg_name          = var.backend_target_group_name != "" ? substr(var.backend_target_group_name, 0, 32) : substr("${var.name}-be-3000", 0, 32)
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
  count       = var.enable_frontend_target ? 1 : 0
  name        = local.frontend_tg_name
  port        = var.frontend_target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = var.frontend_health_path
    matcher = "200-399"
  }

  tags = var.tags
}

resource "aws_lb_target_group" "backend" {
  count       = var.enable_backend_target ? 1 : 0
  name        = local.backend_tg_name
  port        = var.backend_target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

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

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.enable_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  # Default action: forward to frontend target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[0].arn
  }
}

# Priority 1: Frontend host header (beta.cedu.app) → frontend TG
resource "aws_lb_listener_rule" "frontend_host" {
  count        = var.enable_https_listener && var.enable_frontend_target && var.frontend_host_header != "" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[0].arn
  }

  condition {
    host_header {
      values = [var.frontend_host_header]
    }
  }
}

# Priority 2: Backend host header (api.cedu.app) → backend TG
resource "aws_lb_listener_rule" "backend_host" {
  count        = var.enable_https_listener && var.enable_backend_target && var.backend_host_header != "" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend[0].arn
  }

  condition {
    host_header {
      values = [var.backend_host_header]
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_web_acl_arn != "" ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}
