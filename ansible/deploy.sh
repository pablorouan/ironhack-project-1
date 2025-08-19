#!/bin/bash
# deploy.sh - Deploy Voting App

echo "=== Deploying Voting Application on all hosts ==="

# Dry run first (simulate changes)
ansible-playbook -i inventory site.yml --check --diff

echo "=== Dry run complete. If everything looks good, deploying for real... ==="

# Run for real
ansible-playbook -i inventory site.yml

echo "=== Deployment finished. Apps should now be running! ==="
