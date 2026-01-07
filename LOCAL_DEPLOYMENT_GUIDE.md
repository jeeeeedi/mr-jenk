# Local Server Deployment Guide

This guide explains how to deploy the Buy-01 application to a **local server** after successful builds in Jenkins.

## Overview

The local deployment setup includes:
- **Jenkinsfile.local** - Jenkins pipeline for local deployment
- **deploy-local.sh** - Local deployment script
- **rollback-local.sh** - Rollback script for local deployments
- **docker-compose-local.yml** - Docker Compose optimized for local servers

## Prerequisites

### On the Jenkins Server (Local Machine)
1. **Docker** installed and running
2. **Docker Compose** installed
3. **Maven 3.9.x** installed
4. **Node.js 18+** installed
5. **Google Chrome** (for Angular headless tests)

### Verify Prerequisites
```bash
docker --version
docker-compose --version
mvn -version
node --version
npm --version
```

## Quick Start

### Option 1: Manual Deployment (No Jenkins)

```bash
# 1. Build the backend services
mvn clean install -DskipTests

# 2. Run the local deployment script
./deploy-local.sh

# The script will:
# - Build all Docker images
# - Start all containers
# - Run health checks
# - Display the service URLs
```

### Option 2: Jenkins Pipeline (Automatic Deployment)

1. **Configure Jenkins to use local pipeline:**
   - In Jenkins, create a new pipeline job or configure existing one
   - Set the **Pipeline script from SCM** option
   - Point to `Jenkinsfile.local` instead of `Jenkinsfile`
   
2. **Or rename the file:**
   ```bash
   # Backup original Jenkinsfile
   mv Jenkinsfile Jenkinsfile.aws
   
   # Use local deployment Jenkinsfile
   mv Jenkinsfile.local Jenkinsfile
   ```

3. **The pipeline will automatically:**
   - Checkout code
   - Build backend (Maven)
   - Run backend tests (JUnit)
   - Build frontend (Angular)
   - Run frontend tests (Jasmine/Karma)
   - Deploy to local Docker environment
   - Send email notifications

## Service URLs (After Deployment)

| Service | URL |
|---------|-----|
| Frontend (Angular) | http://localhost:4200 |
| API Gateway | http://localhost:8080 |
| Service Registry (Eureka) | http://localhost:8761 |
| User Service | http://localhost:8081 |
| Product Service | http://localhost:8082 |
| Media Service | http://localhost:8083 |
| MongoDB | localhost:27017 |
| Kafka | localhost:9092 |

## Deployment Scripts

### deploy-local.sh
Full local deployment with:
- Pre-deployment cleanup
- Docker image building
- Container orchestration
- Health checks
- Automatic rollback on failure

```bash
# Deploy with default build number
./deploy-local.sh

# Deploy with specific build number
./deploy-local.sh 42
```

### rollback-local.sh
Rollback to previous version:
```bash
./rollback-local.sh
```

## Docker Commands

### View running containers
```bash
docker-compose -f docker-compose-local.yml ps
```

### View logs
```bash
# All services
docker-compose -f docker-compose-local.yml logs -f

# Specific service
docker-compose -f docker-compose-local.yml logs -f api-gateway
```

### Stop all services
```bash
docker-compose -f docker-compose-local.yml down
```

### Restart a specific service
```bash
docker-compose -f docker-compose-local.yml restart user-service
```

## Pipeline Stages

The `Jenkinsfile.local` pipeline includes:

1. **Checkout** - Get latest code from SCM
2. **Build Backend** - `mvn clean install -DskipTests`
3. **Test Backend** - Run JUnit tests
4. **Build Frontend** - `npm install && npm run build`
5. **Test Frontend** - Run Jasmine/Karma tests (headless Chrome)
6. **Deploy to Local Server** - Build images, start containers, health checks

## Troubleshooting

### Docker disk space issues
```bash
# Clean up unused Docker resources
docker system prune -a -f
docker volume prune -f
```

### Service not starting
```bash
# Check container logs
docker logs buy-01-api-gateway

# Check if ports are in use
lsof -i :8080
lsof -i :4200
```

### MongoDB connection issues
```bash
# Verify MongoDB is running
docker logs buy-01-mongodb

# Connect to MongoDB
docker exec -it buy-01-mongodb mongosh -u root -p example
```

### Health check failures
```bash
# Check Eureka dashboard
open http://localhost:8761

# Check API Gateway health
curl http://localhost:8080/actuator/health
```

## Switching Between Local and AWS Deployment

### Use Local Deployment
```bash
# In Jenkins, point to:
Jenkinsfile.local
docker-compose-local.yml
```

### Use AWS Deployment
```bash
# In Jenkins, point to:
Jenkinsfile
docker-compose.yml
```

## File Structure

```
├── Jenkinsfile              # AWS deployment pipeline (original)
├── Jenkinsfile.local        # LOCAL deployment pipeline (new)
├── docker-compose.yml       # AWS Docker Compose
├── docker-compose-local.yml # LOCAL Docker Compose (new)
├── deploy.sh                # AWS deployment script
├── deploy-local.sh          # LOCAL deployment script (new)
├── rollback.sh              # AWS rollback script
├── rollback-local.sh        # LOCAL rollback script (new)
```

## Email Notifications

The pipeline sends email notifications on:
- ✅ **Success** - Deployment completed successfully
- ❌ **Failure** - Build/test/deployment failed

Configure email recipients in `Jenkinsfile.local`:
```groovy
environment {
    TEAM_EMAIL = 'your-team@example.com'
    EMAIL_JEDI = 'developer1@example.com'
    EMAIL_OZZY = 'developer2@example.com'
}
```
