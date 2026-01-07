#!/bin/bash
set -e

#############################################################
# Local Server Deployment Script
# Deploys all services using Docker Compose on local machine
#############################################################

# Get build number from argument
BUILD_NUMBER=${1:-latest}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ipconfig getifaddr en0 2>/dev/null || echo "localhost")

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Local Server Deployment Started${NC}"
echo -e "${BLUE}   Build: ${BUILD_NUMBER}${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# 1. Pre-deployment cleanup
echo -e "${YELLOW}[1/6] Pre-deployment cleanup...${NC}"
# Remove old build-tagged images to free space
docker images --format "{{.Repository}}:{{.Tag}}" | grep "buy01-pipeline.*:build-" | xargs -r docker rmi -f 2>/dev/null || true
docker image prune -f --filter "until=30m" 2>/dev/null || true
docker builder prune -f 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

# 2. Build Docker images
echo -e "${YELLOW}[2/6] Building Docker images with build #${BUILD_NUMBER}...${NC}"

# Build backend services
echo "Building service-registry..."
docker build -t buy01-pipeline-service-registry:build-${BUILD_NUMBER} ./service-registry

echo "Building api-gateway..."
docker build -t buy01-pipeline-api-gateway:build-${BUILD_NUMBER} ./api-gateway

echo "Building user-service..."
docker build -t buy01-pipeline-user-service:build-${BUILD_NUMBER} ./user-service

echo "Building product-service..."
docker build -t buy01-pipeline-product-service:build-${BUILD_NUMBER} ./product-service

echo "Building media-service..."
docker build -t buy01-pipeline-media-service:build-${BUILD_NUMBER} ./media-service

# Build frontend
echo "Building frontend..."
docker build -t buy01-pipeline-frontend:build-${BUILD_NUMBER} ./buy-01-ui

echo -e "${GREEN}✓ All Docker images built${NC}"
echo ""

# 3. Tag images as latest
echo -e "${YELLOW}[3/6] Tagging images as latest...${NC}"

# Backup current images as 'previous' for rollback
for service in service-registry api-gateway user-service product-service media-service frontend; do
    if docker images | grep -q "buy01-pipeline-${service}:latest"; then
        echo "Backing up ${service}:latest as ${service}:previous"
        docker tag buy01-pipeline-${service}:latest buy01-pipeline-${service}:previous 2>/dev/null || true
    fi
done

# Tag new images as latest
docker tag buy01-pipeline-service-registry:build-${BUILD_NUMBER} buy01-pipeline-service-registry:latest
docker tag buy01-pipeline-api-gateway:build-${BUILD_NUMBER} buy01-pipeline-api-gateway:latest
docker tag buy01-pipeline-user-service:build-${BUILD_NUMBER} buy01-pipeline-user-service:latest
docker tag buy01-pipeline-product-service:build-${BUILD_NUMBER} buy01-pipeline-product-service:latest
docker tag buy01-pipeline-media-service:build-${BUILD_NUMBER} buy01-pipeline-media-service:latest
docker tag buy01-pipeline-frontend:build-${BUILD_NUMBER} buy01-pipeline-frontend:latest

echo -e "${GREEN}✓ All images tagged${NC}"
echo ""

# 4. Stop existing containers
echo -e "${YELLOW}[4/6] Stopping existing containers...${NC}"
docker-compose down --remove-orphans 2>/dev/null || true
echo -e "${GREEN}✓ Existing containers stopped${NC}"
echo ""

# 5. Start new containers
echo -e "${YELLOW}[5/6] Starting containers with Docker Compose...${NC}"
docker-compose up -d

echo -e "${GREEN}✓ Containers started${NC}"
echo ""

# 6. Health checks
echo -e "${YELLOW}[6/6] Running health checks...${NC}"

HEALTH_CHECK_FAILED=0
MAX_RETRIES=24  # 24 retries x 5 seconds = 120 seconds max wait
RETRY_DELAY=5

# Function to check service with retries
check_service() {
    local service_name=$1
    local health_url=$2
    local retry_count=0
    
    echo -n "  Checking $service_name..."
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if curl -f -s "$health_url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓ healthy${NC} (after $((retry_count * RETRY_DELAY))s)"
            return 0
        fi
        retry_count=$((retry_count + 1))
        echo -n "."
        sleep $RETRY_DELAY
    done
    echo -e " ${RED}❌ failed after ${MAX_RETRIES} attempts${NC}"
    return 1
}

echo "Waiting for services to initialize (this may take up to 2 minutes)..."
echo ""

# Check Service Registry (Eureka) - most critical, starts first
if ! check_service "Service Registry" "http://localhost:8761"; then
    HEALTH_CHECK_FAILED=1
fi

# Check API Gateway - depends on Service Registry  
if ! check_service "API Gateway" "http://localhost:8080/actuator/health"; then
    HEALTH_CHECK_FAILED=1
fi

# Check User Service
if ! check_service "User Service" "http://localhost:8081/actuator/health"; then
    echo -e "  ${YELLOW}⚠ User Service may still be starting${NC}"
fi

# Check Product Service
if ! check_service "Product Service" "http://localhost:8082/actuator/health"; then
    echo -e "  ${YELLOW}⚠ Product Service may still be starting${NC}"
fi

# Check Media Service
if ! check_service "Media Service" "http://localhost:8083/actuator/health"; then
    echo -e "  ${YELLOW}⚠ Media Service may still be starting${NC}"
fi

# Check Frontend
if ! check_service "Frontend" "http://localhost:4200"; then
    HEALTH_CHECK_FAILED=1
fi

echo ""

if [ $HEALTH_CHECK_FAILED -eq 1 ]; then
    echo -e "${RED}============================================${NC}"
    echo -e "${RED}   ❌ DEPLOYMENT FAILED!${NC}"
    echo -e "${RED}============================================${NC}"
    echo ""
    echo -e "${YELLOW}Checking container logs for troubleshooting...${NC}"
    echo ""
    echo "Service Registry logs:"
    docker-compose logs --tail=10 service-registry
    echo ""
    echo "API Gateway logs:"
    docker-compose logs --tail=10 api-gateway
    exit 1
fi

# Post-deployment cleanup
echo -e "${YELLOW}Running post-deployment cleanup...${NC}"
docker image prune -f --filter "until=1h" 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}   ✅ LOCAL DEPLOYMENT SUCCESSFUL!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}🌐 Application URLs:${NC}"
echo -e "   Frontend:         ${GREEN}http://localhost:4200${NC}"
echo -e "   API Gateway:      ${GREEN}http://localhost:8080${NC}"
echo -e "   Service Registry: ${GREEN}http://localhost:8761${NC}"
echo -e "   User Service:     ${GREEN}http://localhost:8081${NC}"
echo -e "   Product Service:  ${GREEN}http://localhost:8082${NC}"
echo -e "   Media Service:    ${GREEN}http://localhost:8083${NC}"
echo ""
echo -e "${BLUE}📦 Deployed version: build-${BUILD_NUMBER}${NC}"
echo -e "${YELLOW}💡 Previous version backed up for rollback${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "   View logs:     docker-compose logs -f [service-name]"
echo -e "   Stop all:      docker-compose down"
echo -e "   Rollback:      ./rollback-local.sh"
echo ""

# Show running containers
echo -e "${BLUE}Running containers:${NC}"
docker-compose ps

exit 0
