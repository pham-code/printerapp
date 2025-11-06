variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_sg_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "myKeyPairName" {
  description = "Keypair name for EC2 instances"
  type        = string
}

variable "db_subnet_id" {
  description = "The subnet ID for the DB instance"
  type        = string
}

variable "db_sg_id" {
  description = "The security group ID for the DB instance"
  type        = string
}

variable "user_data_mysql_template_path" {
  description = "Path to the user data template for the MySQL instance"
  type        = string
}

variable "user_data_wordpress_template_path" {
  description = "Path to the user data template for the WordPress instances"
  type        = string
}

variable "db_name" {
  description = "Database name for WordPress."
  type        = string
}

variable "db_user" {
  description = "Database user for WordPress."
  type        = string
}

variable "db_pass" {
  description = "Database password for WordPress."
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}