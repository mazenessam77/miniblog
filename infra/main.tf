# ─── Data Sources ────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

# ─── Locals ──────────────────────────────────────────────────────────────────

locals {
  name = "${var.project_name}-${var.environment}"

  # Always use 2 AZs for HA; slice prevents failures in regions with fewer AZs
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Subnet layout:
  #   Public  (10.0.1–2.0/24)  — ALB, NAT Gateway
  #   App     (10.0.11–12.0/24)— EKS worker nodes
  #   DB      (10.0.21–22.0/24)— RDS (no internet route)
  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
}

# ─── VPC / Networking ────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  name                     = local.name
  vpc_cidr                 = var.vpc_cidr
  azs                      = local.azs
  public_subnet_cidrs      = local.public_subnet_cidrs
  private_app_subnet_cidrs = local.private_app_subnet_cidrs
  private_db_subnet_cidrs  = local.private_db_subnet_cidrs
}

# ─── IAM Roles ───────────────────────────────────────────────────────────────

module "iam" {
  source = "./modules/iam"

  name = local.name
}

# ─── Container Registry ──────────────────────────────────────────────────────

module "ecr" {
  source = "./modules/ecr"

  name         = local.name
  project_name = var.project_name
}

# ─── EKS Cluster ─────────────────────────────────────────────────────────────
# Step 1: terraform apply -target=module.eks
# Step 2: terraform apply

module "eks" {
  source = "./modules/eks"

  name                = local.name
  cluster_version     = var.eks_cluster_version
  aws_region          = var.aws_region
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_app_subnet_ids
  cluster_role_arn    = module.iam.eks_cluster_role_arn
  node_role_arn       = module.iam.eks_node_role_arn
  node_instance_types = var.eks_node_instance_types
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size
  node_desired_size   = var.eks_node_desired_size

  depends_on = [module.vpc, module.iam]
}

# ─── RDS (PostgreSQL) ────────────────────────────────────────────────────────

module "rds" {
  source = "./modules/rds"

  name           = local.name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_db_subnet_ids
  eks_node_sg_id = module.eks.cluster_security_group_id
  instance_class = var.rds_instance_class
  db_username    = var.rds_username
  db_password    = var.rds_password
  storage_gb     = var.rds_storage_gb
  multi_az       = var.rds_multi_az

  depends_on = [module.vpc, module.eks]
}

# ─── ElastiCache (Redis — Rate Limiting) ─────────────────────────────────────

module "elasticache" {
  source = "./modules/elasticache"

  name           = local.name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_app_subnet_ids
  eks_node_sg_id = module.eks.cluster_security_group_id

  depends_on = [module.vpc, module.eks]
}

# ─── S3 + CloudFront (Static Frontend) ───────────────────────────────────────

module "s3" {
  source = "./modules/s3"

  name         = local.name
  project_name = var.project_name
}

# ─── CloudWatch (Monitoring & Alerting) ──────────────────────────────────────

module "cloudwatch" {
  source = "./modules/cloudwatch"

  name             = local.name
  eks_cluster_name = module.eks.cluster_name
  rds_identifier   = module.rds.identifier

  depends_on = [module.eks, module.rds]
}
