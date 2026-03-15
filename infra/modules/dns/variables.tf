variable "domain_name" {
  description = "Root domain name (e.g. miniblog.com)"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for api.<domain_name> CNAME record"
  type        = string
}
