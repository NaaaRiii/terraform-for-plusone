resource "aws_lb" "rails_alb" {
  name               = "rails-alb"
  internal           = false  # パブリックALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  # 2つ以上の異なる AZ のサブネットを指定
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_c.id
  ]

  tags = {
    Name = "plusone-tg"
  }
}

resource "aws_lb_target_group" "plusone-tg" {
  name     = "plusone-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "rails_http" {
  load_balancer_arn = aws_lb.rails_alb.arn
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

resource "aws_lb_listener" "rails_https" {
  load_balancer_arn = aws_lb.rails_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.api_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.plusone-tg.arn
  }

  # ACM の検証完了を保証したい場合
  depends_on = [
    aws_acm_certificate_validation.api_cert_validation
  ]
}
