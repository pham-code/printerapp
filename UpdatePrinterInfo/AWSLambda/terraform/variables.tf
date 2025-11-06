variable "bryan_ip_cidr" {
  description = "Bryan's IP address for SSH access"
  type        = string
  default     = "97.170.56.0/24"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "printerapp"
}

variable "myKeyPairName" {
  description = "Keypair name"
  type        = string
  default     = "myecrkey"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "certificate_arn" {
  description = "SSL certificate ARN for HTTPS"
  type        = string
  default     = "arn:aws:acm:us-east-1:502882675682:certificate/171bb49a-5fed-48ef-9fdd-042a074894c4"
}

variable "availability_zones" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH to public instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_name" {
  description = "Database name for WordPress"
  type        = string
  default     = "wp_db"
}

variable "db_user" {
  description = "Database user for WordPress"
  type        = string
  default     = "wp_user"
}

variable "db_pass" {
  description = "Database password for WordPress."
  type        = string
  default     = "P@ssw0rd123"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for Lambda deployment packages"
  type        = string
  default     = "printer-ink-lambda-deployments-unique-name" # IMPORTANT: Replace with a globally unique S3 bucket name
}

variable "all_traffic_cidr" {
  description = "CIDR block for all IPv4 traffic, equivalent to 0.0.0.0/0."
  type        = string
  default     = "0.0.0.0/0"
}

variable "mail_username" {
  description = "Username for the SMTP server"
  type        = string
  default     = "bryanpham2000"
}

variable "mail_password" {
  description = "Password for the SMTP server"
  type        = string
  default     = "gckd nmxi drka dlxm"
}

data "aws_caller_identity" "current" {}
