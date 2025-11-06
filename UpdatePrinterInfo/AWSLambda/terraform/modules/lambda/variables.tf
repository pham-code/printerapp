variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "lambda_iam_role_arn" {
  type = string
}

variable "lambda_private_subnet_id" {
  type = string
}

variable "lambda_sg_id" {
  type = string
}

variable "db_private_ip" {
  type = string
}

variable "db_port" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_pass" {
  type = string
}

variable "mail_username" {
  type = string
  description = "Username for the SMTP server"
}

variable "mail_password" {
  type = string
  description = "Password for the SMTP server"
}