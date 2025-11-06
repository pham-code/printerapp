# Compute Module

This module creates the compute resources, including a public bastion host and a private database EC2 instance.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_name` | The name of the project. | `string` | n/a | yes |
| `environment` | The deployment environment. | `string` | n/a | yes |
| `public_subnet_ids` | A list of public subnet IDs for the bastion host. | `list(string)` | n/a | yes |
| `db_subnet_id` | The subnet ID for the DB instance. | `string` | n/a | yes |
| `public_sg_id` | The security group ID for the public bastion host. | `string` | n/a | yes |
| `db_sg_id` | The security group ID for the DB instance. | `string` | n/a | yes |
| `myKeyPairName` | Keypair name for EC2 instances. | `string` | n/a | yes |
| `user_data_mysql_template_path` | Path to the user data template for the MySQL instance. | `string` | n/a | yes |
| `user_data_wordpress_template_path` | Path to the user data template for WordPress. | `string` | n/a | yes |
| `db_name` | Database name for WordPress. | `string` | n/a | yes |
| `db_user` | Database user for WordPress. | `string` | n/a | yes |
| `db_pass` | Database password for WordPress. | `string` | n/a | yes |
| `aws_region` | AWS region. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `public_instance_id` | The ID of the public bastion instance. |
| `public_instance_ip` | The public IP of the public bastion instance. |
| `public_instance_private_ip` | The private IP of the public bastion instance. |
| `db_private_ip` | The private IP of the DB instance. |
| `db_instance_id` | The instance ID of the DB instance. |
