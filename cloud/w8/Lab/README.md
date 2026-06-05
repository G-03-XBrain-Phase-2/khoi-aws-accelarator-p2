# tf-k8s-alb

> **1 lệnh** → VPC + EC2 + minikube + Kubernetes app + ALB → URL truy cập được từ Internet

```
terraform apply -auto-approve
```

---

## Kiến trúc

```
                        ┌─────────────────────────────────────────────────────┐
                        │                    AWS (ap-southeast-1)              │
                        │                                                      │
   Browser              │  ┌──────────────────────────────────────────────┐   │
      │                 │  │  VPC  10.0.0.0/16                            │   │
      │  HTTP :80       │  │                                              │   │
      ▼                 │  │  ┌─────────────┐    ┌─────────────────────┐ │   │
  ┌───────┐             │  │  │   Subnet 1  │    │     Subnet 2        │ │   │
  │  ALB  │─────────────┼──┼─▶│  (AZ-a)    │    │     (AZ-b)          │ │   │
  └───────┘  :30080     │  │  │             │    │                     │ │   │
      │      NodePort   │  │  │ ┌─────────┐ │    └─────────────────────┘ │   │
      │                 │  │  │ │   EC2   │ │                             │   │
      │                 │  │  │ │t3.medium│ │                             │   │
      │                 │  │  │ │         │ │                             │   │
      │                 │  │  │ │┌───────┐│ │                             │   │
      │                 │  │  │ ││minikube││ │                             │   │
      └─────────────────┼──┼──┼─││       ││ │                             │   │
                        │  │  │ ││ Pod 1 ││ │                             │   │
                        │  │  │ ││ Pod 2 ││ │                             │   │
                        │  │  │ │└───────┘│ │                             │   │
                        │  │  │ └─────────┘ │                             │   │
                        │  │  └─────────────┘                             │   │
                        │  └──────────────────────────────────────────────┘   │
                        └─────────────────────────────────────────────────────┘

  Luồng traffic:
  Internet → ALB (port 80) → Target Group → EC2:30080 (NodePort) → nginx pod:80
```

---

## Cách wire 2 Provider

### Provider 1: `hashicorp/aws`
Quản lý toàn bộ hạ tầng AWS:
- VPC, Subnets, Internet Gateway, Route Table
- Security Groups (ALB SG + EC2 SG)
- EC2 instance (Amazon Linux 2023, t3.medium)
- Application Load Balancer + Target Group + Listener
- Key Pair (public key từ `tls_private_key`)

### Provider 2: `hashicorp/kubernetes`
Deploy app vào minikube **sau khi** cluster đã up. Quản lý:
- `kubernetes_namespace` — namespace `minikube-demo`
- `kubernetes_config_map` — HTML page mount vào nginx
- `kubernetes_deployment` — 2 replicas nginx:alpine
- `kubernetes_service` — NodePort 30080

**Cơ chế wire (quan trọng):**

```
Terraform execution order:
  1. aws_* resources   → dựng VPC, EC2, ALB song song
  2. null_resource.bootstrap_minikube
       └─ remote-exec SSH vào EC2
       └─ chạy scripts/bootstrap.sh (cài Docker + minikube, start cluster)
  3. null_resource.fetch_kubeconfig
       └─ local-exec: SSH fetch /home/ec2-user/.kube/config
       └─ sed patch: https://127.0.0.1:8443 → https://<EC2_PUBLIC_IP>:8443
       └─ ghi ra ./kubeconfig.yaml
  4. local_file.kubeconfig   → đảm bảo file tồn tại trên disk
  5. kubernetes_* resources  → depends_on fetch_kubeconfig
       └─ Terraform gọi Kubernetes provider với config_path = ./kubeconfig.yaml
       └─ Deploy Namespace, ConfigMap, Deployment, Service
```

```hcl
# Provider được configure với đường dẫn file tĩnh
provider "kubernetes" {
  config_path = "${path.module}/kubeconfig.yaml"
}

# Nhưng file này chỉ tồn tại SAU khi fetch_kubeconfig chạy xong
# Tất cả kubernetes_* resource đều khai báo:
resource "kubernetes_deployment" "app" {
  depends_on = [null_resource.fetch_kubeconfig]
  ...
}
```

**Tại sao cách này hoạt động:** Terraform evaluate provider config lazily — nó chỉ thực sự kết nối tới Kubernetes khi có resource kubernetes_* nào đó cần plan/apply. Vì tất cả các resource đó đều `depends_on` fetch_kubeconfig, đến lúc Terraform gọi provider thì kubeconfig.yaml đã tồn tại rồi.

---

## Cấu trúc thư mục

```
tf-k8s-alb/
├── main.tf                   # Orchestration: providers, modules, bootstrap, K8s resources
├── variables.tf              # Input variables
├── outputs.tf                # ALB URL, SSH command, kubectl command
├── app/
│   └── index.html.tpl        # Custom HTML (templatefile)
├── scripts/
│   └── bootstrap.sh          # Cài Docker + minikube trên EC2
└── modules/
    ├── networking/            # VPC, subnets, security groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── compute/               # EC2 instance
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── alb/                   # ALB + Target Group + Listener
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Prerequisites

```bash
# Cài Terraform >= 1.6
brew install terraform   # macOS
# hoặc: https://developer.hashicorp.com/terraform/install

# AWS credentials (một trong các cách):
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
# hoặc: aws configure
# hoặc: IAM role nếu chạy từ EC2/CI

# Quyền AWS cần thiết:
# EC2 (full), VPC (full), ElasticLoadBalancingV2 (full)
```

---

## Chạy

```bash
# 1. Clone và vào thư mục
git clone <repo>
cd tf-k8s-alb

# 2. Init providers
terraform init

# 3. (Tuỳ chọn) Xem plan trước
terraform plan

# 4. Dựng tất cả — 1 lệnh
terraform apply -auto-approve
```

**Thời gian:** ~10–15 phút (EC2 boot + minikube start chiếm phần lớn)

**Output sau khi xong:**
```
Outputs:
  alb_url        = "http://minikube-demo-alb-XXXXXXXXXX.ap-southeast-1.elb.amazonaws.com"
  ec2_public_ip  = "x.x.x.x"
  ssh_command    = "ssh -i ec2_key.pem ec2-user@x.x.x.x"
  kubectl_command = "kubectl --kubeconfig=kubeconfig.yaml -n minikube-demo get pods"
```

Mở `alb_url` trên browser là xong ✅

---

## Tuỳ chỉnh

```hcl
# terraform.tfvars (tạo file này để override)
aws_region    = "us-east-1"
project_name  = "my-app"
instance_type = "t3.large"    # nếu muốn nhiều RAM hơn
app_replicas  = 3
```

---

## Debug

```bash
# SSH vào EC2 xem log bootstrap
ssh -i ec2_key.pem ec2-user@<EC2_IP>
cat ~/bootstrap.log

# Kiểm tra cluster từ local
kubectl --kubeconfig=kubeconfig.yaml get all -n minikube-demo

# Xem pods
kubectl --kubeconfig=kubeconfig.yaml -n minikube-demo get pods -o wide

# Xem logs nginx
kubectl --kubeconfig=kubeconfig.yaml -n minikube-demo logs -l app=minikube-demo
```

---

## Dọn dẹp

```bash
terraform destroy -auto-approve
```

Lệnh này xoá sạch: ALB, Target Group, EC2, VPC, Security Groups, Key Pair.  
File local (`ec2_key.pem`, `kubeconfig.yaml`) được xoá tự động vì là `local_file` / `local_sensitive_file` resource.

---

## Vì sao chọn cách làm này

| Quyết định | Lý do |
|---|---|
| **minikube + docker driver** | Không cần nested virtualization (KVM), chạy được trên EC2 thường. Kind cũng hợp lệ nhưng minikube dễ debug hơn với `minikube dashboard`, `minikube ssh` |
| **t3.medium** | minikube cần tối thiểu 2 vCPU + 2GB RAM. t3.small không đủ |
| **remote-exec provisioner** | Cách trực tiếp nhất để bootstrap software trên EC2 trong Terraform. Không cần Ansible hay SSM |
| **kubeconfig fetch + sed patch** | minikube bind API server trên 127.0.0.1 trong cluster; cần patch sang public IP để Terraform Kubernetes provider reach được từ máy local |
| **NodePort thay vì LoadBalancer** | Trên minikube, Service type LoadBalancer không có external IP (cần metallb). NodePort đơn giản hơn và đủ cho bài này |
| **ALB forward sang NodePort** | ALB là L7 load balancer, có health check, dễ thêm HTTPS sau này. NodePort expose port cố định (30080) trên EC2 |
| **Kubernetes provider** | Thay vì dùng `kubectl apply` trong remote-exec, dùng provider cho phép Terraform track state K8s objects, diff được, destroy được sạch |
