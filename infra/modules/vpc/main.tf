# ─────────────────────────────────────────────────────────────────────────────
#  VPC MODULE
#  Creates a secure 3-tier network:
#    Public  subnets → ALB + NAT Gateway
#    Private app subnets → EKS worker nodes
#    Private db  subnets → RDS (no internet route table entry)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.name}-vpc" }
}

# ─── Internet Gateway ─────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name}-igw" }
}

# ─── Public Subnets (ALB + NAT Gateway) ──────────────────────────────────────

resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.name}-public-${var.azs[count.index]}"
    "kubernetes.io/role/elb" = "1" # Tells AWS LBC this subnet is for public ALBs
  }
}

# ─── Private App Subnets (EKS worker nodes) ───────────────────────────────────

resource "aws_subnet" "private_app" {
  count = length(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name                                        = "${var.name}-private-app-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb"           = "1" # Internal ALBs
    "kubernetes.io/cluster/${var.name}-cluster" = "shared"
  }
}

# ─── Private DB Subnets (RDS — fully isolated, no NAT route) ──────────────────

resource "aws_subnet" "private_db" {
  count = length(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.name}-private-db-${var.azs[count.index]}" }
}

# ─── Elastic IPs for NAT Gateways ────────────────────────────────────────────

resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"

  tags       = { Name = "${var.name}-nat-eip-${count.index + 1}" }
  depends_on = [aws_internet_gateway.main]
}

# ─── NAT Gateways (one per AZ for high availability) ─────────────────────────

resource "aws_nat_gateway" "main" {
  count = length(var.azs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # NAT lives in PUBLIC subnet

  tags       = { Name = "${var.name}-nat-${var.azs[count.index]}" }
  depends_on = [aws_internet_gateway.main]
}

# ─── Route Tables ─────────────────────────────────────────────────────────────

# Public: 0.0.0.0/0 → Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private App: 0.0.0.0/0 → NAT Gateway (one route table per AZ)
resource "aws_route_table" "private_app" {
  count  = length(var.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = { Name = "${var.name}-private-app-rt-${var.azs[count.index]}" }
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# Private DB: no internet route — completely isolated
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name}-private-db-rt" }
}

resource "aws_route_table_association" "private_db" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}
