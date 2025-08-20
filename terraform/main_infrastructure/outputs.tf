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

# SSH connection information
output "ssh_connection_info" {
  description = "SSH connection commands and setup instructions"
  value = {
    # Direct bastion connection
    bastion_ssh = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.bastion.public_ip}"
    
    # ProxyJump commands for private instances
    frontend_ssh = "ssh -i ${var.private_key_path} -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.frontend.private_ip}"
    backend_ssh  = "ssh -i ${var.private_key_path} -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.backend.private_ip}"
    database_ssh = "ssh -i ${var.private_key_path} -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.database.private_ip}"
    
    # Alternative: Two-step SSH
    step1 = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.bastion.public_ip}"
    step2_frontend = "ssh ec2-user@${aws_instance.frontend.private_ip}"
    step2_backend  = "ssh ec2-user@${aws_instance.backend.private_ip}"
    step2_database = "ssh ec2-user@${aws_instance.database.private_ip}"
  }
}

# SSH Config for easy management
output "ssh_config_snippet" {
  description = "SSH config snippet to add to ~/.ssh/config"
  value = <<-EOF
# Voting App Infrastructure SSH Config
Host voting-bastion
    HostName ${aws_instance.bastion.public_ip}
    User ec2-user
    IdentityFile ${var.private_key_path}
    ServerAliveInterval 30
    
Host voting-frontend
    HostName ${aws_instance.frontend.private_ip}
    User ec2-user
    IdentityFile ${var.private_key_path}
    ProxyJump voting-bastion
    
Host voting-backend
    HostName ${aws_instance.backend.private_ip}
    User ec2-user
    IdentityFile ${var.private_key_path}
    ProxyJump voting-bastion
    
Host voting-database
    HostName ${aws_instance.database.private_ip}
    User ec2-user
    IdentityFile ${var.private_key_path}
    ProxyJump voting-bastion
EOF
}

# Ansible inventory format
output "ansible_inventory" {
  description = "Ansible inventory snippet"
  value = <<-EOF
[bastion]
voting-bastion ansible_host=${aws_instance.bastion.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${var.private_key_path}

[frontend]
voting-frontend ansible_host=${aws_instance.frontend.private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${var.private_key_path} ansible_ssh_common_args='-o ProxyJump=ec2-user@${aws_instance.bastion.public_ip}'

[backend]
voting-backend ansible_host=${aws_instance.backend.private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${var.private_key_path} ansible_ssh_common_args='-o ProxyJump=ec2-user@${aws_instance.bastion.public_ip}'

[database]
voting-database ansible_host=${aws_instance.database.private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${var.private_key_path} ansible_ssh_common_args='-o ProxyJump=ec2-user@${aws_instance.bastion.public_ip}'

[all:vars]
ansible_ssh_extra_args=-o StrictHostKeyChecking=no
EOF
}
