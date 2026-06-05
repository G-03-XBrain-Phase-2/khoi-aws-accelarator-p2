variable "project_name"   { type = string }
variable "vpc_id"         { type = string }
variable "public_subnets" { type = list(string) }
variable "alb_sg_id"      { type = string }
variable "instance_id"    { type = string }
variable "node_port"      { type = number }
