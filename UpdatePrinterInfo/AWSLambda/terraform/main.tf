# TODO:
#    - replace or create new myKeyPairName
#    - replace certificate_arn
#    - replace db_name, db_user, db_pass with secure values
#    - replace bryan_ip_cidr with your own IP CIDR for secure access
#    - replace ssh_ingress_cidr with your own IP CIDR for secure acces
#    - Once everything is created and started up, the NAT Gateway can be deleted to reduce costs.
#    - release elastic IP used by NAT Gateway to reduce costs. (eip-my-ecr-1-nat_eip)

provider "aws" {
	region = var.aws_region
}

# Terraform configuration for secured web application
terraform {
	required_version = ">= 1.0"
	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 5.0"
		}
	}
}

# Root module: call submodules for logical separation. All original resources are moved into modules.

module "network" {
  source = "./modules/network"

  project_name        = var.project_name
  environment         = var.environment
  availability_zones  = var.availability_zones
  bryan_ip            = var.bryan_ip_cidr
}

module "security" {
  source = "./modules/security"

  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.network.vpc_id
  vpc_cidr         = module.network.vpc_cidr
  bryan_ip         = var.bryan_ip_cidr
  ssh_ingress_cidr = var.ssh_ingress_cidr
  all_traffic_cidr = var.all_traffic_cidr
}

module "asg" {
  source = "./modules/asg"

  project_name                      = var.project_name
  aws_region                        = var.aws_region
  environment                       = var.environment
  public_subnet_ids                 = module.network.public_subnet_ids
  db_subnet_id                      = module.network.db_subnet_id
  public_sg_id                      = module.security.public_sg_id
  db_sg_id                          = module.security.db_sg_id
  myKeyPairName                     = var.myKeyPairName
  user_data_mysql_template_path     = "${path.root}/user_data_mysql.tpl"
  user_data_wordpress_template_path = "${path.root}/user_data_wordpress.tpl"
  db_name                           = var.db_name
  db_user                           = var.db_user
  db_pass                           = var.db_pass
}

module "iam" {
  source = "./modules/iam"

  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  account_id             = data.aws_caller_identity.current.account_id
  db_instance_identifier = module.asg.db_instance_id
  db_user                = var.db_user
}

module "lambda" {
  source = "./modules/lambda"

  project_name             = var.project_name
  environment              = var.environment
  s3_bucket_name           = var.s3_bucket_name
  lambda_iam_role_arn      = module.iam.lambda_iam_role_arn
  lambda_private_subnet_id = module.network.lambda_private_subnet_id
  lambda_sg_id             = module.security.lambda_sg_id
  db_private_ip            = module.asg.db_private_ip
  db_port                  = var.db_port
  db_name                  = var.db_name
  db_user                  = var.db_user
  db_pass                  = var.db_pass
  mail_username            = var.mail_username
  mail_password            = var.mail_password
}

# Root outputs to preserve original outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "worpress_public_ip" {
  description = "Public IP of the WordPress bastion host"
  value       = module.asg.public_instance_elastic_ip
}

output "worpress_public_instance_id" {
  description = "Public IP of the WordPress bastion host"
  value       = module.asg.public_instance_id
}

output "db_instance_id" {
  description = "The instance ID of the DB instance"
  value       = module.asg.db_instance_id
}

output "db_private_ip" {
  description = "The private IP of the DB instance"
  value       = module.asg.db_private_ip
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "api_gateway_endpoint" {
  description = "The invoke URL of the API Gateway"
  value       = module.lambda.api_gateway_endpoint
}
