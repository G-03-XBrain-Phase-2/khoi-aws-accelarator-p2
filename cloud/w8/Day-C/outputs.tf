###############################################################################
# outputs.tf
###############################################################################


output "ec2_public_ip" {
  description = "EC2 instance public IP (for SSH debugging)"
  value       = module.compute.public_ip
}
