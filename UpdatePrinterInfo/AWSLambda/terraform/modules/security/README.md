# Security Module

This module creates all necessary security groups for the application.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_name` | The name of the project. | `string` | n/a | yes |
| `environment` | The deployment environment (e.g., dev, staging, prod). | `string` | n/a | yes |
| `vpc_id` | The ID of the VPC where security groups will be created. | `string` | n/a | yes |
| `vpc_cidr` | The CIDR block for the VPC, used for DB ingress rules. | `string` | n/a | yes |
| `bryan_ip` | The source IP CIDR for SSH access to the bastion host. | `string` | n/a | yes |
| `ssh_ingress_cidr` | The source IP CIDR for SSH access to public instances. | `string` | n/a | yes |
| `all_traffic_cidr` | CIDR block for all IPv4 traffic, equivalent to 0.0.0.0/0. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `public_sg_id` | The ID of the public (bastion) instance security group. |
| `db_sg_id` | The ID of the database instance security group. |
