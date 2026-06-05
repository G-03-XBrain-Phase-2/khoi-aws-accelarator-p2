###############################################################################
# outputs.tf
###############################################################################

output "alb_url" {
  description = "Application URL — open this in your browser"
  value       = "http://${module.alb.dns_name}"
}

output "ec2_public_ip" {
  description = "EC2 instance public IP (for SSH debugging)"
  value       = module.compute.public_ip
}

output "ssh_command" {
  description = "SSH into EC2 to inspect the cluster"
  value       = "ssh -i ec2_key.pem ec2-user@${module.compute.public_ip}"
}

output "kubectl_command" {
  description = "Run kubectl against the minikube cluster from your machine"
  value       = "kubectl --kubeconfig=kubeconfig.yaml -n ${var.project_name} get pods"
}
