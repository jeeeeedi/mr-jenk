#!/bin/bash
# =============================================================================
# Docker Cleanup Script
# Removes old images and frees up disk space
# =============================================================================

echo "🧹 Running Docker cleanup..."

# Remove old build-tagged images
echo "Removing old build-tagged images..."
docker images --format "{{.Repository}}:{{.Tag}}" | grep "buy01-pipeline.*:build-" | xargs -r docker rmi -f 2>/dev/null || true

# Prune old images
docker image prune -a -f --filter "until=30m" 2>/dev/null || true

# Prune builder cache
docker builder prune -f 2>/dev/null || true

# Prune volumes (only for post-deployment)
if [ "$1" == "--volumes" ]; then
    docker volume prune -f 2>/dev/null || true
fi

echo "✓ Docker cleanup completed"
