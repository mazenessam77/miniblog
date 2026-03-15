variable "name" {
  description = "Name prefix for all RDS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the RDS security group"
  type        = string
}

variable "subnet_ids" {
  description = "Private DB subnet IDs (must span at least 2 AZs)"
  type        = list(string)
}

variable "eks_node_sg_id" {
  description = "EKS cluster security group ID — only this SG can reach the database"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class (e.g. db.t3.small)"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "storage_gb" {
  description = "Allocated storage in GB"
  type        = number
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
}
