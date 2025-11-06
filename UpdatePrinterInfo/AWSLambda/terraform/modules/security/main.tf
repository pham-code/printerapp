resource "aws_security_group" "public" {
  name_prefix = "security-${var.project_name}-${var.environment}-public-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.all_traffic_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bryan_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_traffic_cidr]
  }

  tags = {
    Name        = "security-${var.project_name}-${var.environment}-public"
    Environment = var.environment
  }
}

resource "aws_security_group" "db" {
  name_prefix = "security-${var.project_name}-${var.environment}-db-"
  description = "DB SG - allow VPC internal access only"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_traffic_cidr]
  }

  egress { # Explicit rule for SMTP
    description = "Allow outbound SMTP"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = [var.all_traffic_cidr]
  }

  tags = {
    Name        = "db-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "lambda" {
  name_prefix = "security-${var.project_name}-${var.environment}-lambda-"
  description = "Lambda SG - allow outbound internet access for email"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_traffic_cidr]
  }

  egress { # Explicit rule for SMTP
    description = "Allow outbound SMTP"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = [var.all_traffic_cidr]
  }

  egress { # Explicit rule for HTTPS
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.all_traffic_cidr]
  }

  tags = {
    Name        = "lambda-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}
