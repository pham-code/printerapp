# Network module

This module creates the VPC, public and private subnets, NAT gateways, route tables, internet gateway, and network ACLs.

Inputs:
- `project_name` (string) - project prefix for naming
- `environment` (string) - environment tag
- `availability_zones` (list(string)) - AZ list to create subnets in
- `bryan_ip` (string) - Bryan's IP address for SSH access

Outputs:
- `vpc_id` - ID of the created VPC
- `public_subnet_ids` - list of public subnet IDs
- `db_subnet_id` - ID of the DB subnet
