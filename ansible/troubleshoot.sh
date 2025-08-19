#!/bin/bash
# troubleshoot.sh - Troubleshooting script for Voting App

echo "=== Troubleshooting Voting App deployment... ==="

# 1) Containers status
echo "--- Checking container status on all hosts ---"
ansible all -i inventory -m community.docker.docker_container_info -a "name=*" --become

# 2) Logs
echo "--- Vote app logs ---"
ansible frontend -i inventory -m shell -a "docker logs vote | tail -n 20" --become --ignore-errors

echo "--- Result app logs ---"
ansible frontend -i inventory -m shell -a "docker logs result | tail -n 20" --become --ignore-errors

echo "--- Worker logs ---"
ansible backend -i inventory -m shell -a "docker logs worker | tail -n 20" --become --ignore-errors

echo "--- Redis logs ---"
ansible backend -i inventory -m shell -a "docker logs redis | tail -n 20" --become --ignore-errors

echo "--- PostgreSQL logs ---"
ansible database -i inventory -m shell -a "docker logs postgres | tail -n 20" --become --ignore-errors

# 3) Connectivity tests
echo "--- Testing Redis connectivity from frontend ---"
ansible frontend -i inventory -m shell -a "nc -zv {{ hostvars['backend-host'].ansible_host }} 6379" --become --ignore-errors

echo "--- Testing PostgreSQL connectivity from backend ---"
ansible backend -i inventory -m shell -a "nc -zv {{ hostvars['database-host'].ansible_host }} 5432" --become --ignore-errors

echo "=== Troubleshooting completed. Check results above. ==="
