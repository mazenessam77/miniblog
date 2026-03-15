output "app_log_group_name" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.app.name
}

output "eks_pod_log_group_name" {
  description = "CloudWatch log group for EKS pod logs"
  value       = aws_cloudwatch_log_group.eks_pods.name
}

output "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
