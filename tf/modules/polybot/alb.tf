resource "aws_lb" "alb" {
  name               = "tf-${var.owner}-polybot-lb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.tf-polybot-alb-sg.id]
}

resource "aws_alb_target_group" "polybot-tg" {
  name     = "tf-${var.owner}-polybot-tg"
  port     = 8443
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path     = "/"
    port     = 8443
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "tg-attachment" {
   for_each = {
    for k, v in aws_instance.app_server :
    k => v
  }
  target_group_arn = aws_alb_target_group.polybot-tg.arn
  target_id        = each.value.id
  port             = 8443
}

resource "aws_lb_listener" "alb_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.alb_cert.arn
  depends_on = [
    aws_acm_certificate_validation.validate_alb_cert
  ]

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.polybot-tg.arn
  }
}

resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8443"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.polybot-tg.arn
  }
}

resource "aws_lb_listener_rule" "allow_post_requests" {
  listener_arn = aws_lb_listener.alb_http.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.polybot-tg.arn
  }

  condition {
    field  = "http-request-method"
    values = ["POST"]
  }

  priority = 1
}

resource "aws_route53_record" "alb_record" {
  name    = "${var.owner}-polybot-${var.region}"
  type    = "A"
  zone_id = data.aws_route53_zone.hosted_zone_id.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
  }
}
