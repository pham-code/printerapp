variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "bryan_ip" {
  description = "Bryan's public IP CIDR for SSH access"
  type = string
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH to public instances"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "all_traffic_cidr" {
  description = "CIDR block for allowing all IPv4 traffic."
  type        = string
}
