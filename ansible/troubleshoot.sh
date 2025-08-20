#!/bin/bash
set -euo pipefail

echo "=== Troubleshooting Voting App deployment... ==="

# 1. Check containers only on real app hosts (skip bastion)
echo "--- Checking container status on app hosts (frontend, backend, database) ---"
ansible 'frontend-host:backend-host:database-host' -i inventory -m community.docker.docker_container_info -a "name=vote" || true
ansible 'frontend-host:backend-host:database-host' -i inventory -m community.docker.docker_container_info -a "name=result" || true
ansible 'backend-host' -i inventory -m community.docker.docker_container_info -a "name=worker" || true
ansible 'backend-host' -i inventory -m community.docker.docker_container_info -a "name=redis" || true
ansible 'database-host' -i inventory -m community.docker.docker_container_info -a "name=postgres" || true

# 2. Test connectivity between components
echo "--- Testing connectivity ---"
ansible frontend-host -i inventory -m shell -a "curl -s http://localhost:8080 || true"
ansible frontend-host -i inventory -m shell -a "curl -s http://localhost:8081 || true"
ansible backend-host -i inventory -m shell -a "nc -zv {{ hostvars['database-host'].ansible_host }} 5432" || true
ansible frontend-host -i inventory -m shell -a "nc -zv {{ hostvars['backend-host'].ansible_host }} 6379" || true

echo "=== Troubleshooting completed. Check results above. ==="
