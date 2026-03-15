# ─────────────────────────────────────────────────────────────────────────────
#  MEDIA MODULE — Photo Upload + Lambda Resize
#
#  Flow:
#    1. Backend pod generates S3 presigned PUT URL (via IRSA)
#    2. Browser uploads image directly to  uploads/<uuid>.<ext>
#    3. S3 event fires Lambda
#    4. Lambda resizes → resized/thumb/<uuid> + resized/medium/<uuid>
#    5. resized/* is publicly readable; uploads/* is private
# ─────────────────────────────────────────────────────────────────────────────

variable "name" { type = string }
variable "oidc_provider_arn" { type = string }

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Derive OIDC issuer URL from the provider ARN
  oidc_issuer = replace(
    var.oidc_provider_arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/",
    ""
  )
}

# ─── S3 Media Bucket ──────────────────────────────────────────────────────────

resource "aws_s3_bucket" "media" {
  bucket = "${var.name}-media-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.name}-media" }
}

resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Allow public read on resized/ only — uploads/ stays private
resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_resized" {
  bucket     = aws_s3_bucket.media.id
  depends_on = [aws_s3_bucket_public_access_block.media]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadResized"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.media.arn}/resized/*"
    }]
  })
}

# ─── Backend IRSA Role (pods generate presigned upload URLs) ──────────────────

resource "aws_iam_role" "backend_irsa" {
  name = "${var.name}-backend-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:miniblog:backend-sa"
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = { Name = "${var.name}-backend-irsa" }
}

resource "aws_iam_role_policy" "backend_s3_put" {
  name = "${var.name}-backend-s3-put"
  role = aws_iam_role.backend_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "${aws_s3_bucket.media.arn}/uploads/*"
    }]
  })
}

# ─── Lambda IAM Role ──────────────────────────────────────────────────────────

resource "aws_iam_role" "lambda_resize" {
  name = "${var.name}-lambda-resize"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.name}-lambda-resize" }
}

resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.name}-lambda-resize-s3"
  role = aws_iam_role.lambda_resize.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.media.arn}/uploads/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.media.arn}/resized/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_resize.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ─── Lambda Package ───────────────────────────────────────────────────────────
# The package/ directory is built by CI before terraform plan:
#   pip install pillow --target infra/modules/media/lambda/package \
#     --platform manylinux2014_x86_64 --implementation cp \
#     --python-version 3.11 --only-binary=:all: --quiet
#   cp infra/modules/media/lambda/resize.py infra/modules/media/lambda/package/

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/package"
  output_path = "${path.module}/lambda/resize.zip"
}

# ─── CloudWatch Log Group ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}-resize"
  retention_in_days = 14
  tags              = { Name = "${var.name}-lambda-resize-logs" }
}

# ─── Lambda Function ──────────────────────────────────────────────────────────

resource "aws_lambda_function" "resize" {
  function_name    = "${var.name}-resize"
  role             = aws_iam_role.lambda_resize.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "resize.handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.media.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = { Name = "${var.name}-resize" }
}

# ─── S3 → Lambda Event Trigger ────────────────────────────────────────────────

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resize.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.media.arn
}

resource "aws_s3_bucket_notification" "uploads_trigger" {
  bucket = aws_s3_bucket.media.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.resize.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# ─── Outputs ──────────────────────────────────────────────────────────────────

output "bucket_name" {
  description = "Media S3 bucket — set as MEDIA_BUCKET in backend ConfigMap"
  value       = aws_s3_bucket.media.bucket
}

output "bucket_regional_domain" {
  description = "S3 bucket regional domain (for constructing public image URLs)"
  value       = aws_s3_bucket.media.bucket_regional_domain_name
}

output "backend_irsa_role_arn" {
  description = "IRSA role ARN for backend-sa — add as BACKEND_IRSA_ROLE_ARN GitHub Secret"
  value       = aws_iam_role.backend_irsa.arn
}

output "lambda_function_name" {
  description = "Image resize Lambda function name"
  value       = aws_lambda_function.resize.function_name
}
