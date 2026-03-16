output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "certificate_arn" {
  description = "ACM certificate ARN — covers domain + *.domain (valid for CloudFront and ALB)"
  value       = aws_acm_certificate.main.arn
}

output "name_servers" {
  description = "Route53 NS records — configure these at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}
