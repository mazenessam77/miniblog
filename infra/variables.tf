# ─── Global ─────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (production | staging | development)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "environment must be one of: production, staging, development."
  }
}

variable "project_name" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  default     = "miniblog"
}

# ─── Networking ─────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ─── EKS ────────────────────────────────────────────────────────────────────

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for managed node group workers"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes (for Cluster Autoscaler)"
  type        = number
  default     = 6
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

# ─── RDS ────────────────────────────────────────────────────────────────────

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "miniblog_admin"
  sensitive   = true
}

variable "rds_password" {
  description = "RDS master password — minimum 16 characters (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.rds_password) >= 16
    error_message = "rds_password must be at least 16 characters."
  }
}

variable "rds_storage_gb" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS (recommended for production)"
  type        = bool
  default     = true
}

# ─── DNS ────────────────────────────────────────────────────────────────────

variable "domain_name" {
  description = "Root domain name managed in Route 53 (e.g. miniblog.example.com)"
  type        = string
  default     = "miniblog.example.com"
}
