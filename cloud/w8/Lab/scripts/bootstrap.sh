#!/usr/bin/env bash
###############################################################################
# bootstrap.sh
# Runs on EC2 via remote-exec. Installs Docker, minikube, starts cluster,
# and patches kubeconfig to allow external access on port 8443.
###############################################################################
set -euo pipefail

log() { echo "[bootstrap] $(date '+%H:%M:%S') $*"; }

###############################################################################
# 0. System prereqs
###############################################################################
log "Installing system packages..."
dnf install -y curl wget git conntrack socat --allowerasing

###############################################################################
# 1. Docker
###############################################################################
log "Installing Docker..."
dnf install -y docker
systemctl enable --now docker

# Let ec2-user run docker without sudo
usermod -aG docker ec2-user

# Reload group membership for THIS session (newgrp would exit the script)
export DOCKER_HOST=unix:///var/run/docker.sock

log "Docker version: $(docker --version)"

###############################################################################
# 2. kubectl
###############################################################################
log "Installing kubectl..."
KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
log "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

###############################################################################
# 3. minikube
###############################################################################
log "Installing minikube..."
curl -sLO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
log "minikube version: $(minikube version)"

###############################################################################
# 4. Start minikube with docker driver
#    --apiserver-port 8443   → consistent port for kubeconfig
#    --listen-address        → bind API server to all interfaces so we can
#                              reach it from Terraform local-exec
###############################################################################
log "Starting minikube..."
sudo -u ec2-user bash -c "
  minikube start \
    --driver=docker \
    --apiserver-port=8443 \
    --apiserver-ips=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) \
    --listen-address=0.0.0.0 \
    --kubernetes-version=stable \
    --cpus=2 \
    --memory=2048 \
    --wait=all \
    --wait-timeout=5m
"

###############################################################################
# 5. Verify cluster is healthy
###############################################################################
log "Waiting for node to be Ready..."
sudo -u ec2-user bash -c "
  export KUBECONFIG=~/.kube/config
  for i in \$(seq 1 30); do
    kubectl get nodes | grep -q ' Ready' && echo 'Node is Ready!' && exit 0
    echo \"  attempt \$i/30 — waiting...\"
    sleep 10
  done
  echo 'ERROR: node never became Ready'
  exit 1
"

###############################################################################
# 6. Expose kubeconfig for Terraform to read
###############################################################################
log "Kubeconfig is at /home/ec2-user/.kube/config"
chmod 644 /home/ec2-user/.kube/config

log "Bootstrap complete. Cluster info:"
sudo -u ec2-user bash -c "
  export KUBECONFIG=~/.kube/config
  kubectl cluster-info
  kubectl get nodes -o wide
"

# Thêm vào cuối bootstrap.sh

# Forward NodePort từ host → minikube container
# Chạy nền và persist qua reboot
cat > /etc/systemd/system/minikube-nodeport.service << 'EOF'
[Unit]
Description=Forward NodePort 30080 to minikube
After=docker.service
Wants=docker.service

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:30080,fork,reuseaddr TCP:192.168.49.2:30080
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now minikube-nodeport.service
log "NodePort 30080 forwarding enabled"
