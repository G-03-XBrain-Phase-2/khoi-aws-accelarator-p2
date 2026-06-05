###############################################################################
# modules/networking/main.tf
# VPC, subnets (2 AZs for ALB), IGW, route table, security groups
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

###############################################################################
# SUBNETS  — 2 public subnets in different AZs (ALB requires ≥2 AZs)
###############################################################################

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-${count.index + 1}" }
}

###############################################################################
# INTERNET GATEWAY + ROUTE
###############################################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.project_name}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# SECURITY GROUP — ALB (inbound HTTP from Internet)
###############################################################################

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP from Internet to ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

###############################################################################
# SECURITY GROUP — EC2 (NodePort from ALB, SSH from Internet for bootstrap)
###############################################################################

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow NodePort from ALB and SSH for bootstrap"
  vpc_id      = aws_vpc.this.id

  # SSH — needed during terraform apply for remote-exec provisioner
  ingress {
    description = "SSH for Terraform provisioner"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Tighten to your IP in production
  }

  # NodePort — only from ALB security group
  ingress {
    description     = "NodePort from ALB"
    from_port       = var.node_port
    to_port         = var.node_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # minikube API server — for kubectl from local machine (fetch kubeconfig)
  ingress {
    description = "minikube API server"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ec2-sg" }
}
