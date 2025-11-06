variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "bryan_ip" {
  description = "Bryan's IP address for SSH access"
  type        = string
}