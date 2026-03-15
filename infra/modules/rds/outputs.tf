output "endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "RDS hostname (without port)"
  value       = aws_db_instance.main.address
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "identifier" {
  description = "RDS instance identifier (used by CloudWatch)"
  value       = aws_db_instance.main.identifier
}

output "port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}
