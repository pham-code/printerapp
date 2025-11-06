data "aws_ami" "myec2type" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "db" {
  ami                         = data.aws_ami.myec2type.id
  instance_type               = "t3.micro"
  subnet_id                   = var.db_subnet_id
  vpc_security_group_ids      = [var.db_sg_id]
  key_name                    = var.myKeyPairName
  associate_public_ip_address = false

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  user_data = base64encode(templatefile(var.user_data_mysql_template_path, {
    db_name = var.db_name,
    db_user = var.db_user,
    db_pass = var.db_pass
  }))

  tags = {
    Name        = "db-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

// Bastion host in public subnet for SSH access
resource "aws_instance" "bastion_public" {
  ami                         = data.aws_ami.myec2type.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_ids[0]
  associate_public_ip_address = true
  key_name                    = var.myKeyPairName
  vpc_security_group_ids      = [var.public_sg_id]

  user_data = base64encode(templatefile(var.user_data_wordpress_template_path, {
    db_host = aws_instance.db.private_ip,
    db_name = var.db_name,
    db_user = var.db_user,
    db_pass = var.db_pass
  }))

  tags = {
    Name = "bastion-${var.project_name}-${var.environment}-ec2-public"
    Environment = var.environment
  }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion_public.id

  tags = {
    Name        = "eip-${var.project_name}-${var.environment}-bastion"
    Environment = var.environment
  }
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion_public.id
  allocation_id = aws_eip.bastion_eip.id
}

