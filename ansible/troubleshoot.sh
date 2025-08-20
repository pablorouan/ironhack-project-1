#!/bin/bash
set -euo pipefail

echo "=== Voting App Deployment Troubleshooting ==="
echo "Timestamp: $(date)"
echo ""

# Helper function for section headers
print_section() {
    echo ""
    echo "=== $1 ==="
    echo ""
}

# 1. Test basic connectivity
print_section "Testing Basic SSH Connectivity"
echo "Testing bastion host..."
ansible bastion-host -i inventory -m ping || echo "❌ Bastion host unreachable"

echo "Testing private hosts via bastion..."
ansible private -i inventory -m ping || echo "❌ Some private hosts unreachable"

# 2. Check Docker service status
print_section "Checking Docker Service Status"
ansible private -i inventory -m shell -a "sudo systemctl is-active docker" || true
ansible private -i inventory -m shell -a "sudo systemctl is-enabled docker" || true

# 3. Check running containers
print_section "Container Status Check"
echo "Frontend containers:"
ansible frontend-host -i inventory -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" || true

echo "Backend containers:"
ansible backend-host -i inventory -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" || true

echo "Database containers:"
ansible database-host -i inventory -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" || true

# 4. Check container logs for errors
print_section "Container Logs (Last 20 lines)"
echo "Vote app logs:"
ansible frontend-host -i inventory -m shell -a "docker logs --tail 20 vote 2>/dev/null || echo 'Vote container not running'" || true

echo "Result app logs:"
ansible frontend-host -i inventory -m shell -a "docker logs --tail 20 result 2>/dev/null || echo 'Result container not running'" || true

echo "Worker logs:"
ansible backend-host -i inventory -m shell -a "docker logs --tail 20 worker 2>/dev/null || echo 'Worker container not running'" || true

echo "Redis logs:"
ansible backend-host -i inventory -m shell -a "docker logs --tail 20 redis 2>/dev/null || echo 'Redis container not running'" || true

echo "PostgreSQL logs:"
ansible database-host -i inventory -m shell -a "docker logs --tail 20 postgres 2>/dev/null || echo 'Postgres container not running'" || true

# 5. Test network connectivity between services
print_section "Network Connectivity Tests"
echo "Frontend -> Backend (Redis):"
ansible frontend-host -i inventory -m shell -a "nc -zv {{ hostvars['backend-host']['ansible_host'] }} 6379 2>&1 || echo 'Redis connection failed'" || true

echo "Backend -> Database (PostgreSQL):"
ansible backend-host -i inventory -m shell -a "nc -zv {{ hostvars['database-host']['ansible_host'] }} 5432 2>&1 || echo 'PostgreSQL connection failed'" || true

echo "Frontend -> Database (PostgreSQL):"
ansible frontend-host -i inventory -m shell -a "nc -zv {{ hostvars['database-host']['ansible_host'] }} 5432 2>&1 || echo 'PostgreSQL connection failed'" || true

# 6. Test application endpoints
print_section "Application Endpoint Tests"
echo "Vote app (port 8080):"
ansible frontend-host -i inventory -m shell -a "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080 2>/dev/null || echo 'Vote app not responding'" || true

echo "Result app (port 8081):"
ansible frontend-host -i inventory -m shell -a "curl -s -o /dev/null -w '%{http_code}' http://localhost:8081 2>/dev/null || echo 'Result app not responding'" || true

# 7. Check environment variables
print_section "Environment Variables Check"
echo "Vote container environment:"
ansible frontend-host -i inventory -m shell -a "docker exec vote env 2>/dev/null | grep -E '(REDIS|HOST)' || echo 'Vote container not running or env vars missing'" || true

echo "Result container environment:"
ansible frontend-host -i inventory -m shell -a "docker exec result env 2>/dev/null | grep -E '(PG|HOST)' || echo 'Result container not running or env vars missing'" || true

echo "Worker container environment:"
ansible backend-host -i inventory -m shell -a "docker exec worker env 2>/dev/null | grep -E '(REDIS|DB|HOST)' || echo 'Worker container not running or env vars missing'" || true

# 8. Check disk space
print_section "System Resources Check"
ansible private -i inventory -m shell -a "df -h / | tail -1" || true
ansible private -i inventory -m shell -a "free -h" || true

# 9. Summary
print_section "Quick Access URLs"
FRONTEND_IP=$(ansible-inventory -i inventory --host frontend-host | grep ansible_host | cut -d'"' -f4)
echo "Vote App: http://${FRONTEND_IP}:8080"
echo "Result App: http://${FRONTEND_IP}:8081"
echo ""
echo "To access via bastion:"
echo "ssh -L 8080:${FRONTEND_IP}:8080 -L 8081:${FRONTEND_IP}:8081 voting-bastion"
echo "Then access: http://localhost:8080 and http://localhost:8081"

echo ""
echo "=== Troubleshooting Complete ==="