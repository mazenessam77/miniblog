output "backend_repository_url" {
  description = "Full ECR URL for backend image (use in Kubernetes deployment)"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repository_url" {
  description = "Full ECR URL for frontend image"
  value       = aws_ecr_repository.frontend.repository_url
}

output "registry_url" {
  description = "ECR registry base URL (account.dkr.ecr.region.amazonaws.com)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
