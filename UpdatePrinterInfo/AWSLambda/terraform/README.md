# My ECR Dev Environment

This Terraform project provisions a development environment on AWS for a web application, consisting of a WordPress frontend and a MySQL backend. The infrastructure is designed with a focus on modularity and security.

## Architecture Overview

The project utilizes a modular structure to organize AWS resources:

- **Network Module**: Sets up the Virtual Private Cloud (VPC), public and private subnets, NAT Gateway, Internet Gateway, route tables, and Network ACLs.
- **Security Module**: Configures security groups for the public bastion host, the private database instance, and the Lambda function, controlling inbound and outbound traffic.
- **Compute Module (ASG)**: Provisions the EC2 instances for the WordPress application (bastion host) and the MySQL database.
- **IAM Module**: Manages IAM roles and policies for the Lambda function.
- **Lambda Module**: Provisions the Lambda function and its associated API Gateway endpoint.

## Key Features

- **Modular Design**: Infrastructure is broken down into reusable modules for better organization and maintainability.
- **Secure Network**: VPC with public and private subnets, Network ACLs, and Security Groups to control traffic flow.
- **Bastion Host**: A public EC2 instance acts as a bastion host for secure SSH access to the private database instance.
- **MySQL Database**: A private EC2 instance running MySQL to serve the WordPress application.
- **Cost Management**: Instructions are provided on how to manually stop and start EC2 instances to manage AWS costs when the environment is idle.

## Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured with appropriate credentials

### Deployment

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url>
    cd myECRDev
    ```

2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

3.  **Review the plan (optional):**
    ```bash
    terraform plan
    ```

4.  **Apply the configuration:**
    ```bash
    terraform apply -auto-approve
    ```

### Cost Management (Stopping/Starting Instances)

To stop your EC2 instances and reduce AWS charges when the environment is idle:

1.  **Get Instance IDs:** After `terraform apply`, you can get the instance IDs from the Terraform outputs:
    ```bash
    terraform output public_instance_id
    terraform output db_instance_id
    ```

2.  **Stop Instances:** Use the AWS CLI with the instance IDs:
    ```powershell
    aws ec2 stop-instances --instance-ids <public_instance_id> <db_instance_id> --region <your_aws_region>
    ```
    aws ec2 stop-instances --instance-ids i-0b377783bf5881138 i-06ff179faad2c20ae --region us-east-1

3.  **Start Instances:** To restart, use:
    ```powershell
    aws ec2 start-instances --instance-ids <public_instance_id> <db_instance_id> --region <your_aws_region>
    ```
    aws ec2 start-instances --instance-ids i-0b377783bf5881138 i-06ff179faad2c20ae --region us-east-1

## Important Notes

-   Remember to replace placeholder values like `<your-repo-url>`, `<public_instance_id>`, `<db_instance_id>`, and `<your_aws_region>` with your actual values.
-   Public IP addresses of EC2 instances may change upon restart unless Elastic IPs are used.
-   Ensure your database is configured to handle graceful stops and starts.
