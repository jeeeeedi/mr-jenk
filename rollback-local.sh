#!/bin/bash
set -e

#############################################################
# Local Server Rollback Script
# Rolls back to the previous version of deployed services
#############################################################

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Local Server Rollback Started${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if previous images exist
echo -e "${YELLOW}[1/4] Checking for previous version images...${NC}"
ROLLBACK_POSSIBLE=1

for service in service-registry api-gateway user-service product-service media-service frontend; do
    if ! docker images | grep -q "buy01-pipeline-${service}:previous"; then
        echo -e "${RED}❌ No previous version found for ${service}${NC}"
        ROLLBACK_POSSIBLE=0
    else
        echo -e "${GREEN}✓ Found previous version for ${service}${NC}"
    fi
done

if [ $ROLLBACK_POSSIBLE -eq 0 ]; then
    echo ""
    echo -e "${RED}============================================${NC}"
    echo -e "${RED}   ❌ ROLLBACK NOT POSSIBLE!${NC}"
    echo -e "${RED}   No previous version images available${NC}"
    echo -e "${RED}============================================${NC}"
    exit 1
fi
echo ""

# Tag previous as latest
echo -e "${YELLOW}[2/4] Promoting previous version to latest...${NC}"
for service in service-registry api-gateway user-service product-service media-service frontend; do
    echo "  Promoting ${service}:previous to ${service}:latest"
    docker tag buy01-pipeline-${service}:previous buy01-pipeline-${service}:latest
done
echo -e "${GREEN}✓ Previous version promoted${NC}"
echo ""

# Restart containers with rolled-back images
echo -e "${YELLOW}[3/4] Restarting containers with previous version...${NC}"
docker compose down --remove-orphans 2>/dev/null || true
docker compose up -d
echo -e "${GREEN}✓ Containers restarted${NC}"
echo ""

# Health checks
echo -e "${YELLOW}[4/4] Running health checks...${NC}"

HEALTH_CHECK_FAILED=0
MAX_RETRIES=20
RETRY_DELAY=5

check_service() {
    local service_name=$1
    local health_url=$2
    local retry_count=0
    
    echo -n "  Checking $service_name..."
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if curl -f -s "$health_url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓ healthy${NC}"
            return 0
        fi
        retry_count=$((retry_count + 1))
        echo -n "."
        sleep $RETRY_DELAY
    done
    echo -e " ${RED}❌ failed${NC}"
    return 1
}

echo "Waiting for services to initialize..."
sleep 10

if ! check_service "Service Registry" "http://localhost:8761"; then
    HEALTH_CHECK_FAILED=1
fi

if ! check_service "API Gateway" "http://localhost:8080/actuator/health"; then
    HEALTH_CHECK_FAILED=1
fi

if ! check_service "Frontend" "http://localhost:4200"; then
    HEALTH_CHECK_FAILED=1
fi

echo ""

if [ $HEALTH_CHECK_FAILED -eq 1 ]; then
    echo -e "${RED}============================================${NC}"
    echo -e "${RED}   ❌ ROLLBACK FAILED!${NC}"
    echo -e "${RED}   Manual intervention required${NC}"
    echo -e "${RED}============================================${NC}"
    exit 1
fi

echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}   ✅ ROLLBACK SUCCESSFUL!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}Application rolled back to previous version${NC}"
echo ""
echo -e "${GREEN}🌐 Application URLs:${NC}"
echo -e "   Frontend:         http://localhost:4200"
echo -e "   API Gateway:      http://localhost:8080"
echo -e "   Service Registry: http://localhost:8761"
echo ""

docker compose ps

exit 0
