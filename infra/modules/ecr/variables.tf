variable "name" {
  description = "Name prefix for resource tags"
  type        = string
}

variable "project_name" {
  description = "Project name used for ECR repository path (e.g. miniblog/backend)"
  type        = string
}
