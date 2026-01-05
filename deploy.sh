#!/bin/bash
set -e

# AWS Deployment Configuration
DEPLOY_HOST="ec2-user@51.21.198.139"
DEPLOY_PATH="/home/ec2-user/buy-01-app"
SSH_KEY="$HOME/Downloads/lastreal.pem"
AWS_PUBLIC_IP="51.21.198.139"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   AWS Deployment Started${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}❌ Error: SSH key not found at $SSH_KEY${NC}"
    exit 1
fi

# Ensure correct permissions on SSH key
chmod 600 "$SSH_KEY"

# 1. Build Docker images
echo -e "${YELLOW}[1/5] Building Docker images...${NC}"
docker-compose build --no-cache
echo -e "${GREEN}✓ Docker images built${NC}"
echo ""

# 2. Save images to tar files
echo -e "${YELLOW}[2/5] Saving Docker images to tar files...${NC}"
docker save -o service-registry.tar mr-jenk-service-registry:latest || docker save -o service-registry.tar buy-01-service-registry:latest
docker save -o api-gateway.tar mr-jenk-api-gateway:latest || docker save -o api-gateway.tar buy-01-api-gateway:latest
docker save -o user-service.tar mr-jenk-user-service:latest || docker save -o user-service.tar buy-01-user-service:latest
docker save -o product-service.tar mr-jenk-product-service:latest || docker save -o product-service.tar buy-01-product-service:latest
docker save -o media-service.tar mr-jenk-media-service:latest || docker save -o media-service.tar buy-01-media-service:latest
docker save -o frontend.tar mr-jenk-frontend:latest || docker save -o frontend.tar buy-01-frontend:latest
echo -e "${GREEN}✓ Docker images saved${NC}"
echo ""

# 3. Transfer docker-compose.yml and tar files to AWS
echo -e "${YELLOW}[3/5] Transferring files to AWS (this may take a few minutes)...${NC}"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$DEPLOY_HOST" "mkdir -p $DEPLOY_PATH"
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no docker-compose.yml "$DEPLOY_HOST:$DEPLOY_PATH/"
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no *.tar "$DEPLOY_HOST:$DEPLOY_PATH/"
echo -e "${GREEN}✓ Files transferred to AWS${NC}"
echo ""

# 4. Deploy on AWS instance
echo -e "${YELLOW}[4/5] Loading images and starting containers on AWS...${NC}"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$DEPLOY_HOST" << 'ENDSSH'
cd /home/ec2-user/buy-01-app

# Load Docker images
echo "Loading Docker images..."
docker load -i service-registry.tar
docker load -i api-gateway.tar
docker load -i user-service.tar
docker load -i product-service.tar
docker load -i media-service.tar
docker load -i frontend.tar

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down || true

# Start new containers
echo "Starting containers..."
docker-compose up -d

# Clean up tar files
rm -f *.tar

# Show running containers
echo ""
echo "Running containers:"
docker-compose ps
ENDSSH

echo -e "${GREEN}✓ Deployment completed on AWS${NC}"
echo ""

# 5. Health check
echo -e "${YELLOW}[5/5] Performing health check...${NC}"
sleep 10

# Check if services are responding
if curl -s "http://${AWS_PUBLIC_IP}:8761" > /dev/null; then
    echo -e "${GREEN}✓ Service Registry (Eureka) is responding${NC}"
else
    echo -e "${YELLOW}⚠ Service Registry not yet ready (may take a minute)${NC}"
fi

if curl -s "http://${AWS_PUBLIC_IP}:8080/actuator/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API Gateway is responding${NC}"
else
    echo -e "${YELLOW}⚠ API Gateway not yet ready (may take a minute)${NC}"
fi

# Clean up local tar files
rm -f *.tar

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}   ✅ DEPLOYMENT SUCCESSFUL!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}🌐 Application URLs:${NC}"
echo -e "   Frontend (HTTPS): https://${AWS_PUBLIC_IP}:4201"
echo -e "   Frontend (HTTP):  http://${AWS_PUBLIC_IP}:4200"
echo -e "   API Gateway:      http://${AWS_PUBLIC_IP}:8080"
echo -e "   Eureka Dashboard: http://${AWS_PUBLIC_IP}:8761"
echo ""
echo -e "${YELLOW}Note: Allow 1-2 minutes for all services to fully start${NC}"
echo ""
