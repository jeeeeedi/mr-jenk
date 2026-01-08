#!/bin/bash
# Quick setup script for Jenkins credentials

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Jenkins Security Setup Helper${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

echo -e "${YELLOW}This script will guide you through setting up Jenkins credentials.${NC}"
echo ""

# Function to print credential instructions
print_credential() {
    local id=$1
    local type=$2
    local description=$3
    local example=$4
    
    echo -e "${GREEN}📝 Credential: ${id}${NC}"
    echo "   Type: ${type}"
    echo "   Description: ${description}"
    if [ -n "$example" ]; then
        echo "   Example: ${example}"
    fi
    echo ""
}

echo "Add these credentials in Jenkins:"
echo "Navigate to: Jenkins → Manage Jenkins → Credentials → System → Global credentials"
echo ""
echo "---"
echo ""

print_credential \
    "team-email" \
    "Secret Text" \
    "Email addresses for notifications" \
    "othmane.afilali@gritlab.ax,jedi.reston@gritlab.ax"

print_credential \
    "aws-deploy-host" \
    "Secret Text" \
    "AWS server IP address" \
    "13.61.234.232"

print_credential \
    "aws-ssh-key-file" \
    "Secret File" \
    "SSH private key for AWS access" \
    "Upload lastreal.pem file"

print_credential \
    "mongo-root-password" \
    "Secret Text" \
    "MongoDB root password (CHANGE FROM DEFAULT!)" \
    "Use a strong password, not 'example'"

echo "---"
echo ""

echo -e "${YELLOW}After adding credentials in Jenkins:${NC}"
echo "1. Copy .env.production to AWS server as .env"
echo "2. Update MongoDB password in .env"
echo "3. Run: chmod 600 /home/ec2-user/buy-01-app/.env"
echo "4. Trigger a build to test"
echo ""

echo -e "${GREEN}✅ Setup guide complete!${NC}"
echo -e "See SECURITY_SETUP.md for detailed instructions"
