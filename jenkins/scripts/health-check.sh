#!/bin/bash
# =============================================================================
# Health Check Script
# Verifies all services are running and healthy
# =============================================================================

MAX_RETRIES=${1:-24}
RETRY_DELAY=${2:-5}
HEALTH_CHECK_FAILED=0

# Function to check a service
check_service() {
    local name=$1
    local url=$2
    local retry=0
    
    echo -n "Checking ${name}..."
    
    while [ $retry -lt $MAX_RETRIES ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo " ✓ healthy"
            return 0
        fi
        retry=$((retry + 1))
        echo -n "."
        sleep $RETRY_DELAY
    done
    
    echo " ❌ failed"
    return 1
}

echo "Running health checks..."
echo "Waiting for services to initialize (up to 2 minutes)..."

# Determine host to check (for Docker environments)
if [ -n "$DOCKER_HOST" ] || [ -f /.dockerenv ]; then
    # Running inside container, check host machine
    HOST="host.docker.internal"
else
    HOST="localhost"
fi

# Check each service
check_service "Service Registry" "http://${HOST}:8761" || HEALTH_CHECK_FAILED=1
check_service "API Gateway" "http://${HOST}:8080/actuator/health" || HEALTH_CHECK_FAILED=1
check_service "Frontend" "http://${HOST}:4200" || HEALTH_CHECK_FAILED=1

if [ $HEALTH_CHECK_FAILED -eq 1 ]; then
    echo "❌ Health checks failed!"
    exit 1
fi

echo ""
echo "✅ All health checks passed!"
echo ""
echo "🌐 Application URLs:"
echo "   Frontend:         http://localhost:4200"
echo "   API Gateway:      http://localhost:8080"
echo "   Service Registry: http://localhost:8761"

exit 0
