# ─────────────────────────────────────────────────────────────────────────────
#  RDS MODULE — PostgreSQL
#  - Deployed in private DB subnets (no internet route)
#  - Security group allows access ONLY from EKS worker nodes
#  - Multi-AZ for production reliability
#  - Encrypted at rest with AWS-managed KMS key
# ─────────────────────────────────────────────────────────────────────────────

# ─── Security Group (only EKS nodes can reach port 5432) ──────────────────────

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Allow PostgreSQL access ONLY from EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS cluster"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id] # Only backend pods can connect
  }

  # No egress rule — RDS does not initiate outbound connections.
  # Omitting the block keeps AWS's default (deny all outbound for custom SGs),
  # which is the correct posture for a database.

  tags = { Name = "${var.name}-rds-sg" }
}

# ─── Subnet Group ─────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name        = "${var.name}-db-subnet-group"
  description = "Private DB subnets for RDS - fully isolated, no internet route"
  subnet_ids  = var.subnet_ids

  tags = { Name = "${var.name}-db-subnet-group" }
}

# ─── Parameter Group ──────────────────────────────────────────────────────────

resource "aws_db_parameter_group" "postgres" {
  family      = "postgres15"
  name        = "${var.name}-pg-params"
  description = "Custom parameter group for MiniBlog PostgreSQL"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = "1000" # Log queries taking > 1 second
    apply_method = "pending-reboot"
  }

  tags = { Name = "${var.name}-pg-params" }
}

# ─── RDS Instance ─────────────────────────────────────────────────────────────

resource "aws_db_instance" "main" {
  identifier = "${var.name}-postgres"

  # Engine
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Storage
  allocated_storage     = var.storage_gb
  max_allocated_storage = var.storage_gb * 2 # Enable auto-scaling up to 2x
  storage_type          = "gp3"
  storage_encrypted     = true # Encrypted at rest

  # Database
  db_name  = "miniblog"
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Networking — PRIVATE ONLY
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false        # ← CRITICAL: never expose to internet
  multi_az               = var.multi_az # HA standby in second AZ

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00" # UTC — low-traffic window
  maintenance_window      = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot   = true

  # Upgrades
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  # Deletion protection
  deletion_protection = false
  skip_final_snapshot = true

  # Performance Insights (free tier for 7 days)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  tags = { Name = "${var.name}-postgres" }
}
