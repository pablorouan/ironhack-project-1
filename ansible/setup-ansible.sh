#!/bin/bash
# setup-ansible.sh - Bootstrap control node for Ansible

echo "=== Installing Ansible and dependencies on control node ==="

# Update control node
sudo dnf update -y

# Install Ansible + required collections
sudo dnf install -y python3 python3-pip git

# Ensure ansible-core and docker modules
pip3 install --user ansible-core boto3 botocore

# Install collections (docker)
ansible-galaxy collection install community.docker

echo "=== Setup complete. You can now run deploy.sh ==="
