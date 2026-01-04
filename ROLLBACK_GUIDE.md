# Deployment Rollback Strategy

## Overview

The CI/CD pipeline implements an **automatic rollback** mechanism that triggers if deployment health checks fail, plus **manual rollback capability** for emergency scenarios.

## How It Works

### Automatic Rollback (During Jenkins Deployment)

1. **Pre-Deployment**: Previous docker-compose configuration is backed up
2. **Deployment**: New version is deployed and containers started
3. **Health Check**: Pipeline waits 15 seconds, then performs health check against API Gateway
4. **Health Check Endpoint**: `GET http://api-gateway:8080/api/health`
5. **Success**: If health check passes, deployment is complete
6. **Failure**: If health check fails within 30 seconds, automatic rollback is triggered:
   - New containers are stopped (`docker-compose down`)
   - Previous deployment is restored from backup
   - Previous containers are restarted
   - Deployment marked as FAILED in Jenkins
   - Pipeline stops (no retry)

### Deployment History Tracking

Each EC2 instance maintains:

```
/home/ubuntu/CURRENT_BUILD.txt
  └─ Contains the Build number of currently deployed version (e.g., "42")

/home/ubuntu/deployments/
  ├─ docker-compose-41.yml    (Previous deployment)
  ├─ docker-compose-40.yml    (Older deployment)
  └─ docker-compose-39.yml    (etc.)
```

**Note**: Only docker-compose files are backed up. Image artifacts remain in Docker/ECR.

## Manual Rollback

### Scenario: Rollback Required After Automatic Check Passes

If services deploy successfully (pass health check) but later encounter issues, you can manually rollback using the provided script.

### Option 1: Rollback to Previous Deployment (Recommended)

```bash
# SSH to EC2 instance
ssh -i your-key.pem ubuntu@<EC2_HOST>

# Make script executable
chmod +x /home/ubuntu/rollback.sh

# Rollback to previous build (automatically detected)
/home/ubuntu/rollback.sh
```

### Option 2: Rollback to Specific Build

```bash
# Rollback to a specific build number
/home/ubuntu/rollback.sh 39

# Where 39 is a previous Build number
```

### List Available Backups

```bash
ls -lh /home/ubuntu/deployments/docker-compose-*.yml
```

Output example:
```
-rw-r--r-- 1 ubuntu ubuntu 2.5K Jan  4 12:45 /home/ubuntu/deployments/docker-compose-39.yml
-rw-r--r-- 1 ubuntu ubuntu 2.5K Jan  4 12:50 /home/ubuntu/deployments/docker-compose-40.yml
-rw-r--r-- 1 ubuntu ubuntu 2.5K Jan  4 12:55 /home/ubuntu/deployments/docker-compose-41.yml
```

## Rollback Script Details

The `rollback.sh` script:

1. ✅ Validates previous deployment exists
2. ✅ Stops current services gracefully
3. ✅ Restores previous docker-compose configuration
4. ✅ Pulls images for previous build from ECR
5. ✅ Starts containers
6. ✅ Performs health check
7. ✅ Updates deployment tracking files
8. ✅ Confirms success with current status

## Health Check Configuration

### Current Implementation

- **Endpoint**: `GET http://localhost:8080/api/health`
- **Timeout**: 30 seconds
- **Wait Before Check**: 15 seconds (allows services to start)
- **Required**: At least one successful response (HTTP 200)

### Expected Health Check Response

```json
{
  "status": "UP",
  "components": {
    "db": { "status": "UP" },
    "kafka": { "status": "UP" },
    "eureka": { "status": "UP" }
  }
}
```

### Customizing Health Check

To modify health check endpoint or timeout, edit the Jenkinsfile Deploy stage:

```groovy
// Change the endpoint
curl -f http://localhost:8080/api/v1/health

// Change timeout (currently 30 seconds)
timeout 60 curl -f http://localhost:8080/api/health

// Add additional health checks
curl -f http://localhost:8080/api/health && \
curl -f http://localhost:3000/ && \
...
```

## Post-Rollback Actions

After a rollback occurs:

1. **Investigation**: Review logs to understand what failed
   ```bash
   # Check API Gateway logs
   docker-compose logs api-gateway
   
   # Check all service logs
   docker-compose logs
   ```

2. **Fix Issues**: Update code/configuration in your repository

3. **New Build**: Push fixes to trigger new Jenkins build
   ```bash
   git add .
   git commit -m "Fix deployment issue"
   git push origin aws
   ```

4. **Verify**: Monitor new build in Jenkins UI

## Rollback Scenarios

### Scenario 1: Container Crashes After Start
**Cause**: Application has startup errors  
**Detection**: Health check timeout  
**Action**: Automatic rollback triggered immediately  
**Fix**: Review error logs, fix code, push new build

### Scenario 2: Database Connection Issues
**Cause**: MongoDB/Kafka services not accessible  
**Detection**: Health check fails (dependencies report DOWN)  
**Action**: Automatic rollback triggered  
**Fix**: Verify credential configuration, check CURRENT_BUILD.txt, manually rollback with `/home/ubuntu/rollback.sh`

### Scenario 3: Manual Deployment Cancellation
**Cause**: Need to revert after deployment succeeded but new version has issues  
**Action**: Manual rollback with `rollback.sh`  
**Example**: 
```bash
/home/ubuntu/rollback.sh
# Confirms previous build number and rolls back
```

## Limitations & Considerations

⚠️ **Important Notes**:

1. **Rollback only restores docker-compose**: If you need to rollback database migrations, you must handle that separately
2. **No Automatic Retry**: If rollback occurs, pipeline fails - no automatic retry is attempted
3. **Build Number Tracking**: Rollback relies on CURRENT_BUILD.txt - don't delete or modify this file manually
4. **Backup Retention**: Old backups remain in `/home/ubuntu/deployments/` indefinitely (consider cleanup)

## Cleanup Backups (Optional)

To remove old backups and free disk space:

```bash
# Keep only the most recent 5 backups
ls -t /home/ubuntu/deployments/docker-compose-*.yml | tail -n +6 | xargs rm -f

# Or remove backups older than 7 days
find /home/ubuntu/deployments/ -name "*.yml" -mtime +7 -delete
```

## Troubleshooting

### "No deployment history found"
```
Error: No deployment history found (CURRENT_BUILD.txt not found)
```
**Cause**: This is the first deployment  
**Action**: No rollback possible yet. Future deployments will have backups.

### "No previous deployment found"
```
Error: No previous deployment found in /home/ubuntu/deployments/
```
**Cause**: Only one deployment exists  
**Action**: Deploy another version first, then rollback capability is available

### "Permission denied" running rollback script
```bash
# Make script executable
chmod +x /home/ubuntu/rollback.sh
```

### Health check not responding
```bash
# Check if API Gateway is running
docker-compose ps api-gateway

# View API Gateway logs
docker-compose logs api-gateway

# Test health endpoint manually
curl -v http://localhost:8080/api/health
```

## Monitoring Deployments

### View Current Deployment
```bash
cat /home/ubuntu/CURRENT_BUILD.txt
```

### View Service Status
```bash
docker-compose ps
docker-compose logs
```

### View Deployment History
```bash
ls -lh /home/ubuntu/deployments/
```

## Jenkins Email Notifications

- **Success**: Deployment successful, all health checks passed
- **Failure**: 
  - If automatic rollback triggered: "Build FAILED" + rollback details
  - If manual action needed: Instructions to investigate and fix

## Next Steps

1. **Monitor First Deployment**: Watch Jenkins build output and EC2 logs
2. **Verify Health Endpoint**: Ensure your API returns proper health status
3. **Test Rollback**: Deploy a test version and manually trigger rollback to verify it works
4. **Update Teams**: Inform team about rollback capability and procedures
