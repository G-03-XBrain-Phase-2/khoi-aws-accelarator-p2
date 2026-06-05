###############################################################################
# modules/compute/main.tf
# EC2 instance — Docker + minikube will be installed via remote-exec
###############################################################################

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.ec2_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30    # minikube needs breathing room
    delete_on_termination = true
  }

  # Minimal user-data: just ensure system is up-to-date before bootstrap.sh
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y curl wget git
  EOF

  tags = { Name = "${var.project_name}-node" }
}
