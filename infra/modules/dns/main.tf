# ─────────────────────────────────────────────────────────────────────────────
#  DNS MODULE — Route53 + ACM Certificate
#
#  Creates:
#    - Route53 hosted zone for the root domain
#    - ACM wildcard certificate (domain + *.domain) with DNS validation
#    - Route53 CNAME for api.<domain> → ALB
#
#  NOTE: Point your domain registrar's nameservers to the NS records output
#        from this module before running terraform apply (or after, and wait
#        for propagation before the ACM certificate validates).
# ─────────────────────────────────────────────────────────────────────────────

# ─── Route53 Hosted Zone ─────────────────────────────────────────────────────

resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = { Name = var.domain_name }
}

# ─── ACM Certificate ─────────────────────────────────────────────────────────
# Covers both the apex (miniblog.com) and all subdomains (*.miniblog.com).
# Deployment region must be us-east-1 for this cert to be usable by CloudFront.

resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = var.domain_name }
}

# ─── DNS Validation Records ───────────────────────────────────────────────────

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ─── API Subdomain (CNAME → ALB) ─────────────────────────────────────────────

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.alb_dns_name]
}
