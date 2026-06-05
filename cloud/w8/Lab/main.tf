###############################################################################
# main.tf
# Orchestrates: VPC → EC2 → minikube bootstrap → kubeconfig fetch →
#               Kubernetes provider → deploy app → ALB
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # Provider 1: AWS  — infrastructure (VPC, EC2, ALB, SG)
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }

    # Provider 2: Kubernetes — deploy app declaratively into minikube
    # Wired AFTER bootstrap: config_path points to kubeconfig fetched from EC2
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

###############################################################################
# PROVIDER CONFIGURATIONS
###############################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

# Kubernetes provider wired to minikube running on EC2
# config_path is written by null_resource.fetch_kubeconfig (local-exec scp)
# All kubernetes_* resources declare depends_on = [null_resource.fetch_kubeconfig]
# so Terraform only calls this provider after the file exists on disk
provider "kubernetes" {
  config_path = local.kubeconfig_local_path
}

###############################################################################
# LOCALS
###############################################################################

locals {
  kubeconfig_local_path = "${path.module}/kubeconfig.yaml"
  node_port             = 30080
  app_port              = 80
  ssh_key_path          = "${path.module}/ec2_key.pem"
}

###############################################################################
# SSH KEY PAIR  (generated fresh every terraform apply on a clean workspace)
###############################################################################

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_sensitive_file" "ssh_key" {
  filename        = local.ssh_key_path
  content         = tls_private_key.this.private_key_pem
  file_permission = "0600"
}

###############################################################################
# MODULES
###############################################################################

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  node_port    = local.node_port
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

module "alb" {
  source          = "./modules/alb"
  project_name    = var.project_name
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnet_ids
  alb_sg_id       = module.networking.alb_sg_id
  instance_id     = module.compute.instance_id
  node_port       = local.node_port
}

###############################################################################
# AMI  — Amazon Linux 2023 (latest)
###############################################################################

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

###############################################################################
# STEP 1 — Bootstrap EC2: install Docker, minikube, start cluster
###############################################################################

resource "null_resource" "bootstrap_minikube" {
  depends_on = [module.compute, local_sensitive_file.ssh_key]

  triggers = {
    instance_id = module.compute.instance_id
  }

  connection {
    type        = "ssh"
    host        = module.compute.public_ip
    user        = "ec2-user"
    private_key = tls_private_key.this.private_key_pem

    # Retry until EC2 is fully up (cloud-init may still run)
    timeout = "15m"
  }

  # Upload the user-data bootstrap script
  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap.sh"
    destination = "/home/ec2-user/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/bootstrap.sh",
      "sudo /home/ec2-user/bootstrap.sh 2>&1 | tee /home/ec2-user/bootstrap.log",
    ]
  }
}

###############################################################################
# STEP 2 — Fetch kubeconfig from EC2 → patch server address → write locally
###############################################################################

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.bootstrap_minikube]

  triggers = {
    instance_id = module.compute.instance_id
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $sshKey = (Resolve-Path "${local.ssh_key_path}").Path

      # Fix permissions
      icacls $sshKey /inheritance:r | Out-Null
      icacls $sshKey /grant:r "$($env:USERNAME):(R)" | Out-Null
      icacls $sshKey /remove "BUILTIN\Administrators" 2>$null
      icacls $sshKey /remove "NT AUTHORITY\SYSTEM" 2>$null
      icacls $sshKey /remove "BUILTIN\Users" 2>$null

      # SCP raw kubeconfig
      scp -o StrictHostKeyChecking=no `
          -o UserKnownHostsFile=NUL `
          -i $sshKey `
          ec2-user@${module.compute.public_ip}:/home/ec2-user/.kube/config `
          ./kubeconfig_raw.yaml

      if ($LASTEXITCODE -ne 0) { Write-Error "SCP failed"; exit 1 }

      # Patch: thay internal Docker IP → 127.0.0.1 (dùng qua tunnel)
      (Get-Content ./kubeconfig_raw.yaml -Raw) `
        -replace '192\.168\.49\.2','127.0.0.1' |
      Out-File -FilePath "${local.kubeconfig_local_path}" -Encoding ascii -NoNewline

      # Mở SSH tunnel nền: local 8443 → EC2 → minikube 192.168.49.2:8443
      $job = Start-Process ssh -ArgumentList @(
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=NUL",
        "-i", $sshKey,
        "-L", "8443:192.168.49.2:8443",
        "-N",
        "ec2-user@${module.compute.public_ip}"
      ) -PassThru -WindowStyle Hidden

      # Lưu PID để kill sau
      $job.Id | Out-File -FilePath "./tunnel.pid"

      # Chờ tunnel sẵn sàng
      Start-Sleep -Seconds 5

      Write-Host "Tunnel PID: $($job.Id)"
      Write-Host "Server:"
      Select-String "server" "${local.kubeconfig_local_path}"
    EOT
  }
}

###############################################################################
# STEP 3 — Deploy app using Kubernetes provider (Provider #2)
# All resources depend on fetch_kubeconfig so provider has config before use
###############################################################################

resource "kubernetes_namespace" "app" {
  depends_on = [null_resource.fetch_kubeconfig]

  metadata {
    name = var.project_name
    labels = {
      "managed-by" = "terraform"
    }
  }
}

resource "kubernetes_config_map" "html" {
  depends_on = [null_resource.fetch_kubeconfig]

  metadata {
    name      = "${var.project_name}-html"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    "index.html" = templatefile("${path.module}/app/index.html.tpl", {
      project_name = var.project_name
      aws_region   = var.aws_region
      alb_url      = "http://${module.alb.dns_name}"
    })
  }
}

resource "kubernetes_deployment" "app" {
  depends_on = [null_resource.fetch_kubeconfig]

  metadata {
    name      = var.project_name
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = var.project_name
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = var.project_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.project_name
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          # Mount custom HTML
          volume_mount {
            name       = "html"
            mount_path = "/usr/share/nginx/html"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }

        volume {
          name = "html"
          config_map {
            name = kubernetes_config_map.html.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  depends_on = [null_resource.fetch_kubeconfig]

  metadata {
    name      = var.project_name
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = var.project_name
    }

    type = "NodePort"

    port {
      port        = 80
      target_port = 80
      node_port   = local.node_port
      protocol    = "TCP"
    }
  }
}
