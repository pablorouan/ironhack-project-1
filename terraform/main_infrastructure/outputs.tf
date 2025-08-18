# outputs.tf - Outputs Configuration

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.voting_app_vpc.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_backend_id" {
  description = "Private backend subnet ID"
  value       = aws_subnet.private_subnet_backend.id
}

output "private_subnet_database_id" {
  description = "Private database subnet ID"
  value       = aws_subnet.private_subnet_database.id
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "Bastion host public DNS"
  value       = aws_instance.bastion.public_dns
}

output "frontend_public_ip" {
  description = "Frontend instance public IP"
  value       = aws_instance.frontend.public_ip
}

output "frontend_public_dns" {
  description = "Frontend instance public DNS"
  value       = aws_instance.frontend.public_dns
}

output "frontend_private_ip" {
  description = "Frontend instance private IP"
  value       = aws_instance.frontend.private_ip
}

output "backend_private_ip" {
  description = "Backend instance private IP"
  value       = aws_instance.backend.private_ip
}

output "database_private_ip" {
  description = "Database instance private IP"
  value       = aws_instance.database.private_ip
}

output "frontend_private_dns" {
  description = "Frontend instance private DNS"
  value       = aws_instance.frontend.private_dns
}

output "backend_private_dns" {
  description = "Backend instance private DNS"
  value       = aws_instance.backend.private_dns
}

output "database_private_dns" {
  description = "Database instance private DNS"
  value       = aws_instance.database.private_dns
}

# URLs for accessing the applications
output "vote_app_url" {
  description = "URL for the voting application"
  value       = "http://${aws_instance.frontend.public_ip}:8080"
}

output "result_app_url" {
  description = "URL for the results application"
  value       = "http://${aws_instance.frontend.public_ip}:8081"
}

# SSH connection strings (using .pem key file)
output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.bastion.public_ip}"
}

output "frontend_ssh_command" {
  description = "SSH command to connect to frontend via bastion"
  value       = "ssh -i ${var.private_key_path} -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.frontend.private_ip}"
}

output "backend_ssh_command" {
  description = "SSH command to connect to backend via bastion"
  value       = "ssh -i ${var.private_key_path} -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.backend.private_ip}"
}

output "database_ssh_command" {
  description = "SSH command to connect to database via bastion"
  value       = "ssh -i ${var.private_key_path} -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.database.private_ip}"
}