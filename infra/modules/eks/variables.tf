variable "name" {
  description = "Name prefix for all EKS resources"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
}

variable "aws_region" {
  description = "AWS region — passed to ALB Controller Helm chart"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster lives"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (included in cluster subnet list for control plane)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS worker nodes"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for EKS worker nodes"
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of nodes (ignored after first apply — managed by autoscaler)"
  type        = number
}
