variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name (for Container Insights metrics)"
  type        = string
}

variable "rds_identifier" {
  description = "RDS instance identifier (for RDS metric alarms)"
  type        = string
}
