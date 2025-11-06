output "public_instance_ip" {
  description = "The ID of the public bastion instance"
  value       = aws_instance.bastion_public.public_ip
}

output "public_instance_id" {
  description = "The instance ID of the public bastion instance"
  value       = aws_instance.bastion_public.id
}

output "public_instance_elastic_ip" {
  description = "Elastic IP of the WordPress host IP"
  value       = aws_eip.bastion_eip.public_ip
}

output "public_instance_private_ip" {
  description = "The private IP of the public bastion instance"
  value       = aws_instance.bastion_public.private_ip
}

output "db_private_ip" {
  description = "The private IP of the DB instance"
  value       = aws_instance.db.private_ip
}

output "db_instance_id" {
  description = "The instance ID of the DB instance"
  value       = aws_instance.db.id
}

