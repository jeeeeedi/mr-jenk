#!/bin/bash
# =============================================================================
# Docker Image Build Script
# Builds all microservices and frontend Docker images
# =============================================================================

set -e

BUILD_NUMBER=${1:-latest}

echo "============================================"
echo "   BUILDING DOCKER IMAGES"
echo "   Build Number: ${BUILD_NUMBER}"
echo "============================================"

# Service list
SERVICES=(
    "service-registry"
    "api-gateway"
    "user-service"
    "product-service"
    "media-service"
)

# Build backend services
for service in "${SERVICES[@]}"; do
    echo "Building ${service}..."
    docker build -t "buy01-pipeline-${service}:build-${BUILD_NUMBER}" "./${service}"
    docker tag "buy01-pipeline-${service}:build-${BUILD_NUMBER}" "buy01-pipeline-${service}:latest"
done

# Build frontend
echo "Building frontend..."
docker build -t "buy01-pipeline-frontend:build-${BUILD_NUMBER}" ./buy-01-ui
docker tag "buy01-pipeline-frontend:build-${BUILD_NUMBER}" "buy01-pipeline-frontend:latest"

echo "✓ All Docker images built with build-${BUILD_NUMBER} tags"
