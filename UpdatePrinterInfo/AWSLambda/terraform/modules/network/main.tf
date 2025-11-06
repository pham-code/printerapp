resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "vpc-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name        = "subnet-${var.project_name}-${var.environment}-public-${count.index + 1}"
    Type        = "Public"
    Environment = var.environment
  }
}

resource "aws_subnet" "db" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name        = "subnet-${var.project_name}-${var.environment}-db"
    Type        = "DB"
    Environment = var.environment
  }
}

resource "aws_subnet" "lambda_private" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name        = "subnet-${var.project_name}-${var.environment}-lambda-private"
    Type        = "Lambda"
    Environment = var.environment
  }
}

resource "aws_network_acl" "mynacl_public" {
  count      = length(var.availability_zones)
  vpc_id     = aws_vpc.myvpc.id
  subnet_ids = [aws_subnet.public[count.index].id]
  tags = {
    Name        = "nacl-${var.project_name}-${var.environment}-public-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_network_acl" "mynacl_db" {
  vpc_id     = aws_vpc.myvpc.id
  subnet_ids = [aws_subnet.db.id]
  tags = {
    Name        = "nacl-${var.project_name}-${var.environment}-db"
    Environment = var.environment
  }
}

# public rules
resource "aws_network_acl_rule" "inbound_public_http" {
  rule_number    = 100
  count          = length(var.availability_zones)
  network_acl_id = aws_network_acl.mynacl_public[count.index].id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "inbound_public_https" {
  rule_number    = 110
  count          = length(var.availability_zones)
  network_acl_id = aws_network_acl.mynacl_public[count.index].id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "inbound_public_rule_ssh" {
  rule_number    = 120
  count          = length(var.availability_zones)
  network_acl_id = aws_network_acl.mynacl_public[count.index].id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.bryan_ip
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "inbound_public_other" {
  rule_number    = 200
  count          = length(var.availability_zones)
  network_acl_id = aws_network_acl.mynacl_public[count.index].id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 32768
  to_port        = 65535
}

resource "aws_network_acl_rule" "outbound_public_all" {
  rule_number    = 300
  count          = length(var.availability_zones)
  network_acl_id = aws_network_acl.mynacl_public[count.index].id
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"  # All IP addresses
  from_port      = 0
  to_port        = 65535
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "igw-${var.project_name}-${var.environment}"
  }
}

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  depends_on = [aws_internet_gateway.my_igw]
  tags = {
    Name        = "eip-${var.project_name}-${count.index + 1}-nat_eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "mynat" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.my_igw]
  tags = {
    Name        = "nat-${var.project_name}-${count.index + 1}-nat_gw"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name        = "rt-${var.project_name}-${var.environment}-public"
    Environment = var.environment
  }
}

resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mynat[0].id
  }

  tags = {
    Name        = "rt-${var.project_name}-${var.environment}-db-private"
    Environment = var.environment
  }
}

resource "aws_route_table" "lambda_private" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mynat[0].id
  }

  tags = {
    Name        = "rt-${var.project_name}-${var.environment}-lambda-private"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "db_private_assoc" {
  subnet_id      = aws_subnet.db.id
  route_table_id = aws_route_table.db_private.id
}

resource "aws_route_table_association" "lambda_private_assoc" {
  subnet_id      = aws_subnet.lambda_private.id
  route_table_id = aws_route_table.lambda_private.id
}

resource "aws_network_acl_rule" "inbound_db_mysql" {
  rule_number    = 800
  network_acl_id = aws_network_acl.mynacl_db.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.myvpc.cidr_block
  from_port      = 3306
  to_port        = 3306
}

resource "aws_network_acl_rule" "inbound_db_ssh" {
  rule_number    = 801
  network_acl_id = aws_network_acl.mynacl_db.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.myvpc.cidr_block
  from_port      = 22
  to_port        = 22
}

# START: Inbound rules for HTTPS, other for internet access
resource "aws_network_acl_rule" "inbound_db_https" {
  rule_number    = 802
  network_acl_id = aws_network_acl.mynacl_db.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "inbound_db_other" {
  rule_number    = 803
  network_acl_id = aws_network_acl.mynacl_db.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 32768
  to_port        = 65535
}

# END: Inbound rules for HTTPS, other for internet access

resource "aws_network_acl_rule" "outbound_db_all" {
  rule_number    = 900
  network_acl_id = aws_network_acl.mynacl_db.id
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

