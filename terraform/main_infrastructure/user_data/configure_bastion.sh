#!/bin/bash

# Update system packages
dnf update -y

# Install useful tools for bastion host
dnf install -y git htop telnet nc tree vim

# Set hostname
hostnamectl set-hostname ${hostname}

# Install Ansible (via EPEL)
dnf install -y epel-release
dnf install -y ansible

# Configure SSH for jump host functionality
cat >> /home/ec2-user/.ssh/config << 'EOF'
# SSH configuration for jump host
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    LogLevel=ERROR
EOF

chown ec2-user:ec2-user /home/ec2-user/.ssh/config
chmod 600 /home/ec2-user/.ssh/config

# Create a directory for Ansible playbooks
mkdir -p /home/ec2-user/ansible
chown ec2-user:ec2-user /home/ec2-user/ansible

# Log installation completion
echo "Bastion configuration completed at $(date)" >> /var/log/user-data.log
echo "Hostname set to: ${hostname}" >> /var/log/user-data.log
echo "Ansible installed and ready for use" >> /var/log/user-data.log
