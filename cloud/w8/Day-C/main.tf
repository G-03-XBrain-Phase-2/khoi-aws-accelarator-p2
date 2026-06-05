terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # Provider 1: AWS  — infrastructure (VPC, EC2, ALB, SG)
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }


provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

module "compute" {
  source             = "./modules/compute"
  project_name       = var.project_name
  ami_id             = data.aws_ami.al2023.id
  instance_type      = var.instance_type
  subnet_id          = module.networking.public_subnet_id
  ec2_sg_id          = module.networking.ec2_sg_id
  key_name           = aws_key_pair.this.key_name
  node_port          = local.node_port
}


data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
