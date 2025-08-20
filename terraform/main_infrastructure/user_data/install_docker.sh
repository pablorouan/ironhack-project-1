#!/bin/bash

# Update system packages
dnf update -y

# Install Docker
dnf install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create symlink for docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Set hostname
hostnamectl set-hostname ${hostname}

# Install useful tools
dnf install -y git htop telnet nc

# Create a directory for the voting app
mkdir -p /home/ec2-user/voting-app
chown ec2-user:ec2-user /home/ec2-user/voting-app

# Log installation completion
echo "Docker installation completed at $(date)" >> /var/log/user-data.log
echo "Hostname set to: ${hostname}" >> /var/log/user-data.log