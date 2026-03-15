# ─────────────────────────────────────────────────────────────────────────────
#  ELASTICACHE MODULE — Redis for Rate Limiting
#  Single-shard Redis 7 cluster in private app subnets
#  EKS pods connect on port 6379 (no TLS needed within VPC)
# ─────────────────────────────────────────────────────────────────────────────

variable "name"           { type = string }
variable "vpc_id"         { type = string }
variable "subnet_ids"     { type = list(string) }
variable "eks_node_sg_id" { type = string }

# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "Allow Redis port 6379 from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id]
    description     = "Redis from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-redis-sg" }
}

# ─── Subnet Group ────────────────────────────────────────────────────────────

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-redis-subnet"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.name}-redis-subnet-group" }
}

# ─── Redis Replication Group ──────────────────────────────────────────────────
# num_cache_clusters = 1 → single primary, no replica (cheapest for rate limiting)

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.name}-redis"
  description          = "Redis for MiniBlog rate limiting"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 1
  port                 = 6379
  engine               = "redis"
  engine_version       = "7.0"

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  apply_immediately = true

  tags = { Name = "${var.name}-redis" }
}

# ─── Outputs ─────────────────────────────────────────────────────────────────

output "primary_endpoint" {
  description = "Redis primary endpoint address (port 6379)"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}
