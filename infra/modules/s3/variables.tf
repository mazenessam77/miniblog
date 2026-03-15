variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "project_name" {
  description = "Project name (used in S3 bucket naming)"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g. miniblog.com)"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN (must be us-east-1 for CloudFront)"
  type        = string
}
