# ─── Networking ──────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB, NAT GW)"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs (EKS nodes)"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private DB subnet IDs (RDS)"
  value       = module.vpc.private_db_subnet_ids
}

# ─── EKS ─────────────────────────────────────────────────────────────────────

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_configure_kubectl" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN (used for IRSA)"
  value       = module.eks.oidc_provider_arn
}

# ─── ECR ─────────────────────────────────────────────────────────────────────

output "ecr_backend_repository_url" {
  description = "ECR backend image URL — use in k8s/backend-deployment.yaml"
  value       = module.ecr.backend_repository_url
}

output "ecr_login_command" {
  description = "Command to authenticate Docker with ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecr.registry_url}"
}

# ─── RDS ─────────────────────────────────────────────────────────────────────

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (private — only reachable from within VPC)"
  value       = module.rds.endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.database_name
}

output "rds_connection_string_template" {
  description = "DATABASE_URL template for backend pods"
  value       = "postgresql://${var.rds_username}:<password>@${module.rds.endpoint}/${module.rds.database_name}"
  sensitive   = true
}

# ─── DNS / HTTPS ─────────────────────────────────────────────────────────────

output "name_servers" {
  description = "Route53 NS records — set these at your domain registrar"
  value       = module.dns.name_servers
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN — set as ACM_CERT_ARN GitHub Secret"
  value       = module.dns.certificate_arn
}

output "site_url" {
  description = "Public URL of the frontend"
  value       = "https://${var.domain_name}"
}

output "api_url" {
  description = "Public URL of the API"
  value       = "https://api.${var.domain_name}"
}

# ─── Frontend ────────────────────────────────────────────────────────────────

output "frontend_cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = module.s3.cloudfront_domain
}

output "frontend_cloudfront_distribution_id" {
  description = "CloudFront distribution ID — set as CLOUDFRONT_DISTRIBUTION_ID GitHub Secret"
  value       = module.s3.cloudfront_distribution_id
}

output "frontend_s3_bucket" {
  description = "S3 bucket name for frontend build artifacts"
  value       = module.s3.bucket_name
}

output "frontend_deploy_command" {
  description = "Command to deploy the React build to S3"
  value       = "aws s3 sync ./frontend/dist s3://${module.s3.bucket_name} --delete"
}

# ─── Media (S3 + Lambda) ─────────────────────────────────────────────────────

output "media_bucket_name" {
  description = "S3 bucket for media uploads — set as MEDIA_BUCKET in backend ConfigMap"
  value       = module.media.bucket_name
}

output "media_backend_irsa_role_arn" {
  description = "IRSA role ARN for backend pods — add as BACKEND_IRSA_ROLE_ARN GitHub Secret"
  value       = module.media.backend_irsa_role_arn
}

output "media_lambda_function" {
  description = "Image resize Lambda function name"
  value       = module.media.lambda_function_name
}

# ─── ElastiCache (Redis) ─────────────────────────────────────────────────────

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint — use in REDIS_URL: redis://<value>:6379/0"
  value       = module.elasticache.primary_endpoint
}

# ─── CloudWatch ──────────────────────────────────────────────────────────────

output "cloudwatch_app_log_group" {
  description = "CloudWatch log group for application logs"
  value       = module.cloudwatch.app_log_group_name
}
