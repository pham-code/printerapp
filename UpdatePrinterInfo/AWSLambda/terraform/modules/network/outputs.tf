output "vpc_id" {
  value = aws_vpc.myvpc.id
}

output "vpc_cidr" {
  value = aws_vpc.myvpc.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "db_subnet_id" {
  value = aws_subnet.db.id
}

output "db_route_table_id" {
  value = aws_route_table.db_private.id
}

output "lambda_private_subnet_id" {
  value = aws_subnet.lambda_private.id
}
