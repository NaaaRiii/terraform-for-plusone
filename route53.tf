# 1. Hosted Zone
resource "aws_route53_zone" "plusoneup" {
  name = "plusoneup.net"
}


# 2. Outputs（Zone ID と Name Servers）
output "plusoneup_hosted_zone_id" {
  description = "Route 53 zone ID for plusoneup.net"
  value = aws_route53_zone.plusoneup.zone_id
}

output "plusoneup_name_servers" {
  description = "The NS name servers assigned by Route53"
  value = aws_route53_zone.plusoneup.name_servers
}


# 3. www サブドメインの CNAMEレコード
resource "aws_route53_record" "www_cname" {
  zone_id = aws_route53_zone.plusoneup.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = ["plusoneup.net"]
}


# 4. API 用 Hosted Zone
resource "aws_route53_zone" "api_plusoneup" {
  name = "api-plusoneup.com"
}

output "api_plusoneup_hosted_zone_id" {
  description = "Route 53 zone ID for api-plusoneup.com"
  value       = aws_route53_zone.api_plusoneup.zone_id
}

output "api_plusoneup_name_servers" {
  description = "Name servers for api-plusoneup.com"
  value       = aws_route53_zone.api_plusoneup.name_servers
}


# 5. API 用 ACM 証明書（DNS 検証）
resource "aws_acm_certificate" "api_cert" {
  domain_name       = "api-plusoneup.com"
  validation_method = "DNS"
}

# DNS 検証レコードを自動生成
resource "aws_route53_record" "api_cert_validation" {
  for_each = {
    for opt in aws_acm_certificate.api_cert.domain_validation_options :
    opt.domain_name => {
      name   = opt.resource_record_name
      type   = opt.resource_record_type
      record = opt.resource_record_value
    }
  }

  zone_id = aws_route53_zone.api_plusoneup.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [ each.value.record ]
}

# 証明書発行の完了待ち
resource "aws_acm_certificate_validation" "api_cert_validation" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = values(aws_route53_record.api_cert_validation)[*].fqdn
}

# 6. ALB リスナーの HTTPS 化
resource "aws_lb_listener" "https_api" {
  load_balancer_arn = aws_lb.rails_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.api_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.plusone-tg.arn
  }
}


# 7. Route53 エイリアスレコード
resource "aws_route53_record" "api_alias" {
  zone_id = aws_route53_zone.api_plusoneup.zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = aws_lb.rails_alb.dns_name
    zone_id                = aws_lb.rails_alb.zone_id
    evaluate_target_health = true
  }
}
