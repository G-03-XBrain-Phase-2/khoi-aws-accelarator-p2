###############################################################################
# variables.tf
###############################################################################

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix used for all resource names and K8s namespace"
  type        = string
  default     = "minikube-demo"
}

variable "instance_type" {
  description = "EC2 instance type. t3.medium minimum for minikube"
  type        = string
  default     = "m7i-flex.large"
}

variable "app_replicas" {
  description = "Number of nginx pod replicas"
  type        = number
  default     = 2
}
