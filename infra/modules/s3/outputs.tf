output "bucket_name" {
  description = "S3 bucket name for frontend assets"
  value       = aws_s3_bucket.frontend.id
}

output "website_endpoint" {
  description = "S3 static website URL"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

# Root outputs.tf references cloudfront_domain — we return the S3 URL here
output "cloudfront_domain" {
  description = "S3 website endpoint (CloudFront can be added later)"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
