# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_private_dns
  enable_dns_support   = var.enable_private_dns

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
  }

  depends_on = [aws_vpc.main]
}

# Public Subnets (for NAT Gateway and Load Balancer)
resource "aws_subnet" "public" {
  count                   = var.availability_zones
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                            = "${var.project_name}-public-subnet-${var.environment}-${count.index + 1}"
    "kubernetes.io/role/elb"        = "1"
    "kubernetes.io/type"            = "public"
  }

  depends_on = [aws_internet_gateway.main]
}

# Private Subnets (for EKS nodes)
resource "aws_subnet" "private" {
  count             = var.availability_zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + var.availability_zones)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                              = "${var.project_name}-private-subnet-${var.environment}-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/type"              = "private"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? var.availability_zones : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip-${var.environment}-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways (one per AZ for high availability)
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? var.availability_zones : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${var.environment}-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = var.availability_zones
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for NAT Gateway)
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? var.availability_zones : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.environment}-${count.index + 1}"
  }
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count          = var.availability_zones
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.public.id
}

# Network ACL for additional security
resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-nacl-${var.environment}"
  }
}

# VPN Gateway (optional)
resource "aws_vpn_gateway" "main" {
  count  = var.enable_vpn_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-vpn-${var.environment}"
  }
}

# Enable VPN Gateway route propagation
resource "aws_vpn_gateway_route_propagation" "private" {
  count          = var.enable_vpn_gateway ? var.availability_zones : 0
  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.public.id
}

# VPC Flow Logs for monitoring
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-vpc-flowlogs-${var.environment}"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flowlogs-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-vpc-flowlogs-role-${var.environment}"
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flowlogs-policy-${var.environment}"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-vpc-flowlogs-${var.environment}"
  }
}

# Security Group for EKS control plane
resource "aws_security_group" "eks_control_plane" {
  name        = "${var.project_name}-eks-control-plane-${var.environment}"
  description = "Security group for EKS control plane"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-control-plane-sg-${var.environment}"
  }
}

# Security Group for EKS worker nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-${var.environment}"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-nodes-sg-${var.environment}"
  }
}

# Allow control plane to communicate with nodes
resource "aws_security_group_rule" "control_plane_to_nodes" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_control_plane.id
  security_group_id        = aws_security_group.eks_nodes.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state  = "available"
  filter {
    name   = "region-name"
    values = [var.aws_region]
  }
}
