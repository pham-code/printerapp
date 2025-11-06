output "public_sg_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.public.id
}

output "db_sg_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.db.id
}

output "lambda_sg_id" {
  description = "The ID of the lambda security group"
  value       = aws_security_group.lambda.id
}
