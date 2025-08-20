#!/bin/bash
# pre-deploy-check.sh - Verify environment is ready for deployment

set -euo pipefail

echo "=== Pre-Deployment Verification ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Check SSH key
echo "1. Checking SSH key setup..."
if [ -f ~/.ssh/pablo-voting-app-key.pem ]; then
    print_status "SSH key file exists"
    chmod 400 ~/.ssh/pablo-voting-app-key.pem
    print_status "SSH key permissions set correctly"
else
    print_status "SSH key file missing" && exit 1
fi

# 2. Check SSH agent
echo ""
echo "2. Checking SSH agent..."
if ssh-add -l | grep -q pablo-voting-app-key; then
    print_status "SSH key loaded in agent"
else
    print_warning "SSH key not in agent. Adding it now..."
    ssh-add ~/.ssh/pablo-voting-app-key.pem
    print_status "SSH key added to agent"
fi

# 3. Test bastion connectivity
echo ""
echo "3. Testing bastion connectivity..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes voting-bastion "echo 'Bastion OK'" 2>/dev/null; then
    print_status "Bastion host reachable"
else
    print_status "Bastion host unreachable" && exit 1
fi

# 4. Test Ansible inventory
echo ""
echo "4. Testing Ansible inventory..."
if ansible-inventory -i inventory --list > /dev/null; then
    print_status "Ansible inventory syntax OK"
else
    print_status "Ansible inventory has issues" && exit 1
fi

# 5. Test private host connectivity via Ansible
echo ""
echo "5. Testing private hosts via Ansible..."
if ansible private -i inventory -m ping --one-line; then
    print_status "All private hosts reachable via Ansible"
else
    print_status "Some private hosts unreachable" && exit 1
fi

# 6. Check Docker images availability
echo ""
echo "6. Checking Docker images..."
IMAGES=("postgres:15" "redis:latest")
CUSTOM_IMAGES=("prouan/vote:latest" "prouan/result:latest" "prouan/worker:latest")
FALLBACK_IMAGES=("dockersamples/examplevotingapp_vote:latest" "dockersamples/examplevotingapp_result:latest" "dockersamples/examplevotingapp_worker:latest")

for img in "${IMAGES[@]}"; do
    if docker pull "$img" > /dev/null 2>&1; then
        print_status "Image $img available"
    else
        print_status "Image $img unavailable" && exit 1
    fi
done

echo ""
echo "Checking custom images (will use fallbacks if needed):"
for i in "${!CUSTOM_IMAGES[@]}"; do
    if docker pull "${CUSTOM_IMAGES[$i]}" > /dev/null 2>&1; then
        print_status "Custom image ${CUSTOM_IMAGES[$i]} available"
    else
        print_warning "Custom image ${CUSTOM_IMAGES[$i]} not found, will use ${FALLBACK_IMAGES[$i]}"
    fi
done

# 7. Check Ansible collections
echo ""
echo "7. Checking Ansible collections..."
if ansible-galaxy collection list | grep -q community.docker; then
    print_status "community.docker collection installed"
else
    print_warning "Installing community.docker collection..."
    ansible-galaxy collection install community.docker
    print_status "community.docker collection installed"
fi

echo ""
echo -e "${GREEN}=== Pre-deployment checks completed successfully! ===${NC}"
echo ""
echo "Ready to deploy! Run: ./deploy.sh"
echo ""
echo "URLs after deployment:"
FRONTEND_IP=$(ansible-inventory -i inventory --host frontend-host | python3 -c "import sys, json; print(json.load(sys.stdin)['ansible_host'])")
echo "Vote App: http://${FRONTEND_IP}:8080"
echo "Result App: http://${FRONTEND_IP}:8081"