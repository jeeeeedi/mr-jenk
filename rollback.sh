#!/bin/bash
# Manual Rollback Script for EC2 Deployment
# Usage: ./rollback.sh [BUILD_NUMBER]
# If BUILD_NUMBER not provided, rolls back to the previous deployment

set -e

cd /home/ubuntu

echo "=========================================="
echo "🔄 Rollback Deployment Script"
echo "=========================================="

# Check if CURRENT_BUILD.txt exists
if [ ! -f CURRENT_BUILD.txt ]; then
    echo "❌ Error: No deployment history found (CURRENT_BUILD.txt not found)"
    exit 1
fi

CURRENT_BUILD=$(cat CURRENT_BUILD.txt)
echo "Current deployment: Build #$CURRENT_BUILD"

# Determine which build to rollback to
if [ -z "$1" ]; then
    # No argument provided, find the most recent backup
    echo "Looking for previous deployment to rollback to..."
    
    PREVIOUS_BUILD=$(ls -t /home/ubuntu/deployments/docker-compose-*.yml 2>/dev/null | head -1 | xargs -I {} basename {} | sed 's/docker-compose-//' | sed 's/.yml//')
    
    if [ -z "$PREVIOUS_BUILD" ]; then
        echo "❌ Error: No previous deployment found in /home/ubuntu/deployments/"
        echo "Available backups:"
        ls -lh /home/ubuntu/deployments/ 2>/dev/null || echo "  (none)"
        exit 1
    fi
else
    # Build number provided as argument
    PREVIOUS_BUILD=$1
    
    if [ ! -f /home/ubuntu/deployments/docker-compose-$PREVIOUS_BUILD.yml ]; then
        echo "❌ Error: No backup found for Build #$PREVIOUS_BUILD"
        echo "Available backups:"
        ls -lh /home/ubuntu/deployments/
        exit 1
    fi
fi

echo "Rollback target: Build #$PREVIOUS_BUILD"

# Confirm rollback
echo ""
echo "⚠️  WARNING: This will stop all services and deploy Build #$PREVIOUS_BUILD"
read -p "Are you sure you want to rollback? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Rollback cancelled"
    exit 0
fi

echo "=========================================="
echo "🔄 Starting Rollback Process"
echo "=========================================="

# Add user to docker group if not already
if ! groups ubuntu | grep -q docker; then
    echo "Adding ubuntu user to docker group..."
    sudo usermod -aG docker ubuntu
fi

# Execute in docker group context
exec sg docker -c "
    set -e
    
    echo 'Stopping current deployment (Build #$CURRENT_BUILD)...'
    docker-compose down || true
    
    echo 'Restoring docker-compose-$PREVIOUS_BUILD.yml...'
    cp /home/ubuntu/deployments/docker-compose-$PREVIOUS_BUILD.yml /home/ubuntu/docker-compose.yml
    
    echo 'Pulling images for Build #$PREVIOUS_BUILD...'
    docker-compose pull
    
    echo 'Starting containers...'
    docker-compose up -d
    
    echo 'Waiting 10 seconds for services to stabilize...'
    sleep 10
    
    echo 'Running health check...'
    if timeout 30 curl -f http://localhost:8080/api/health >/dev/null 2>&1; then
        echo '✅ Health check PASSED!'
    else
        echo '⚠️ Health check did not return success - services may still be starting'
    fi
    
    echo 'Updating deployment history...'
    echo '$PREVIOUS_BUILD' > /home/ubuntu/CURRENT_BUILD.txt
    
    echo '=========================================='
    echo '✅ Rollback to Build #$PREVIOUS_BUILD completed successfully!'
    echo '=========================================='
    echo ''
    echo 'Current containers:'
    docker-compose ps
"
