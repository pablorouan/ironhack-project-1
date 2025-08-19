#!/bin/bash

# setup-ansible.sh - Run this script to set up your Ansible environment

echo "Setting up Ansible environment for Voting App deployment..."

# 1. Install Ansible (if not already installed)
if ! command -v ansible &> /dev/null; then
    echo "Installing Ansible..."
    pip3 install ansible
fi

# 2. Install required Ansible collections
echo "Installing Ansible collections..."
ansible-galaxy collection install community.docker

# 3. Set up SSH config
echo "Setting up SSH configuration..."
cat >> ~/.ssh/config << 'EOF'

# Voting App Bastion Configuration
Host bastion-voting
  HostName 3.38.162.242
  User ec2-user
  IdentityFile ~/.ssh/pablo-voting-app-key.pem
  StrictHostKeyChecking no

Host voting-frontend
  HostName 10.0.1.120
  User ec2-user
  ProxyJump bastion-voting
  IdentityFile ~/.ssh/pablo-voting-app-key.pem
  StrictHostKeyChecking no

Host voting-backend
  HostName 10.0.2.131
  User ec2-user
  ProxyJump bastion-voting
  IdentityFile ~/.ssh/pablo-voting-app-key.pem
  StrictHostKeyChecking no

Host voting-database
  HostName 10.0.3.108
  User ec2-user
  ProxyJump bastion-voting
  IdentityFile ~/.ssh/pablo-voting-app-key.pem
  StrictHostKeyChecking no
EOF

# 4. Test connectivity
echo "Testing SSH connectivity..."
echo "Testing bastion host..."
ssh -o ConnectTimeout=10 bastion-voting "echo 'Bastion host connection successful'"

echo "Testing frontend host..."
ssh -o ConnectTimeout=10 voting-frontend "echo 'Frontend host connection successful'"

echo "Testing backend host..."
ssh -o ConnectTimeout=10 voting-backend "echo 'Backend host connection successful'"

echo "Testing database host..."
ssh -o ConnectTimeout=10 voting-database "echo 'Database host connection successful'"

echo "Setup complete! You can now run the Ansible playbook."

# deploy.sh - Run this script to deploy the application
#!/bin/bash

echo "Deploying Voting Application..."

# Run the Ansible playbook
ansible-playbook -i inventory site.yml --check --diff

echo "This was a dry run. If everything looks good, run without --check:"
echo "ansible-playbook -i inventory site.yml"

# troubleshoot.sh - Troubleshooting script
#!/bin/bash

echo "Troubleshooting Voting App deployment..."

echo "1. Checking container status on all hosts..."

echo "=== Frontend containers ==="
ansible frontend -i inventory -m shell -a "docker ps"

echo "=== Backend containers ==="
ansible backend -i inventory -m shell -a "docker ps"

echo "=== Database containers ==="
ansible database -i inventory -m shell -a "docker ps"

echo "2. Checking container logs..."
echo "=== Vote app logs ==="
ansible frontend -i inventory -m shell -a "docker logs vote" --ignore-errors

echo "=== Result app logs ==="
ansible frontend -i inventory -m shell -a "docker logs result" --ignore-errors

echo "=== Worker logs ==="
ansible backend -i inventory -m shell -a "docker logs worker" --ignore-errors

echo "=== Redis logs ==="
ansible backend -i inventory -m shell -a "docker logs redis" --ignore-errors

echo "=== PostgreSQL logs ==="
ansible database -i inventory -m shell -a "docker logs postgres" --ignore-errors

echo "3. Testing connectivity between services..."
echo "=== Testing Redis connectivity from frontend ==="
ansible frontend -i inventory -m shell -a "telnet 10.0.2.131 6379" --ignore-errors

echo "=== Testing PostgreSQL connectivity from backend ==="
ansible backend -i inventory -m shell -a "telnet 10.0.3.108 5432" --ignore-errors