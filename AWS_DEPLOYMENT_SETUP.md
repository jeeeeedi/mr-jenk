# AWS Deployment Setup Guide

## 🎯 Overview

This guide will help you set up automated deployment from Jenkins to your AWS EC2 instance at **51.21.198.139**.

## ✅ What's Been Configured

### 1. Files Updated

- ✅ **deploy.sh** - Automated deployment script created
- ✅ **Jenkinsfile** - Deploy stage now executes real deployment
- ✅ **docker-compose.yml** - Environment variables updated with AWS IP
- ✅ **buy-01-ui/src/environments/environment.prod.ts** - Frontend configured for AWS endpoints

### 2. Deployment Flow

```
Jenkins Pipeline Success → Build Docker Images → Transfer to AWS → Deploy Containers → Health Check
```

## 🚀 Setup Instructions

### Step 1: Prepare AWS EC2 Instance (51.21.198.139)

SSH into your deployment instance and install Docker:

```bash
# SSH into the instance
ssh -i ~/Downloads/lastreal.pem ec2-user@51.21.198.139

# Update system
sudo yum update -y

# Install Docker
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# IMPORTANT: Log out and back in for group changes to take effect
exit
```

### Step 2: Configure AWS Security Groups

Ensure your EC2 instance security group allows these inbound ports:

| Port | Service          | Protocol |
| ---- | ---------------- | -------- |
| 22   | SSH              | TCP      |
| 80   | HTTP             | TCP      |
| 443  | HTTPS            | TCP      |
| 4200 | Frontend HTTP    | TCP      |
| 4201 | Frontend HTTPS   | TCP      |
| 8080 | API Gateway      | TCP      |
| 8081 | User Service     | TCP      |
| 8082 | Product Service  | TCP      |
| 8083 | Media Service    | TCP      |
| 8761 | Eureka Dashboard | TCP      |

### Step 3: Configure Jenkins

#### Option A: SSH Key in Jenkins (Recommended)

1. **Copy SSH key to Jenkins server:**

```bash
# On your local machine
scp ~/Downloads/lastreal.pem jenkins-user@jenkins-server:/var/lib/jenkins/.ssh/
```

2. **On Jenkins server, set correct permissions:**

```bash
sudo chmod 600 /var/lib/jenkins/.ssh/lastreal.pem
sudo chown jenkins:jenkins /var/lib/jenkins/.ssh/lastreal.pem
```

3. **Update deploy.sh on Jenkins:**
   The script will automatically look for the key in the correct location when running from Jenkins.

#### Option B: Jenkins Credentials (Alternative)

1. Go to Jenkins → Manage Jenkins → Credentials
2. Click on "(global)" domain
3. Click "Add Credentials"
4. Select:
   - Kind: **SSH Username with private key**
   - ID: **aws-deploy-key**
   - Username: **ec2-user**
   - Private Key: Enter directly or from file (lastreal.pem)
5. Click "OK"

Then update the Jenkinsfile Deploy stage to use credentials:

```groovy
stage('Deploy') {
    steps {
        echo 'Deploying application to AWS...'
        sshagent(['aws-deploy-key']) {
            sh '''
                chmod +x deploy.sh
                ./deploy.sh
            '''
        }
    }
}
```

### Step 4: Install Required Plugins in Jenkins

Ensure these plugins are installed:

1. **SSH Agent Plugin** - For SSH key management
2. **Docker Pipeline Plugin** - For Docker commands
3. **Email Extension Plugin** - Already configured for notifications

Go to: **Manage Jenkins** → **Plugins** → **Available plugins**

### Step 5: Configure Jenkins Environment

1. Go to: **Manage Jenkins** → **System**
2. Add environment variables (if needed):
   - `AWS_DEPLOY_HOST`: 51.21.198.139
   - `AWS_DEPLOY_USER`: ec2-user

### Step 6: Test Manual Deployment

Before running through Jenkins, test the deployment script manually:

```bash
cd /Users/othmane.afilali/Desktop/mr-jenk

# Ensure SSH key has correct permissions
chmod 600 ~/Downloads/lastreal.pem

# Test SSH connection
ssh -i ~/Downloads/lastreal.pem ec2-user@51.21.198.139 "echo 'Connection successful'"

# Run deployment (this will take several minutes)
./deploy.sh
```

### Step 7: Trigger Jenkins Pipeline

1. Commit and push your changes:

```bash
cd /Users/othmane.afilali/Desktop/mr-jenk
git add .
git commit -m "Configure AWS deployment pipeline"
git push
```

2. Jenkins will automatically trigger the pipeline
3. Watch the console output for each stage
4. Deployment will happen automatically after tests pass

## 🌐 Accessing Your Deployed Application

Once deployment succeeds:

- **Frontend (HTTPS)**: https://51.21.198.139:4201
- **Frontend (HTTP)**: http://51.21.198.139:4200
- **API Gateway**: http://51.21.198.139:8080
- **Eureka Dashboard**: http://51.21.198.139:8761
- **User Service**: http://51.21.198.139:8081
- **Product Service**: http://51.21.198.139:8082
- **Media Service**: http://51.21.198.139:8083

## 🔍 Troubleshooting

### Issue: Permission denied (publickey)

**Solution:**

```bash
# Ensure SSH key has correct permissions
chmod 600 ~/Downloads/lastreal.pem

# Test connection
ssh -i ~/Downloads/lastreal.pem ec2-user@51.21.198.139
```

### Issue: Docker command not found on AWS

**Solution:**

```bash
# SSH into AWS and check
ssh -i ~/Downloads/lastreal.pem ec2-user@51.21.198.139
docker --version

# If not installed, run Step 1 again
```

### Issue: Services not starting

**Solution:**

```bash
# SSH into AWS and check logs
ssh -i ~/Downloads/lastreal.pem ec2-user@51.21.198.139
cd /home/ec2-user/buy-01-app
docker-compose logs -f
```

### Issue: Health check fails

**Solution:**

```bash
# Services need 1-2 minutes to start
# Check running containers
ssh -i ~/Downloads/lastreal.pem ec2-user@51.21.198.139
docker ps

# Check specific service logs
docker logs buy-01-api-gateway
docker logs buy-01-service-registry
```

### Issue: Frontend can't reach backend

**Solution:**

- Verify security group allows ports 8080-8083
- Check if API Gateway is responding: `curl http://51.21.198.139:8080/actuator/health`
- Verify CORS configuration in API Gateway

## 📊 Monitoring Deployment

### Check Deployment Status

```bash
ssh -i ~/Downloads/lastreal.pem ec2-user@51.21.198.139

# View all running containers
docker ps

# View service logs
cd /home/ec2-user/buy-01-app
docker-compose logs -f

# View specific service
docker logs buy-01-api-gateway -f
```

### Check Service Health

```bash
# Eureka Dashboard
curl http://51.21.198.139:8761

# API Gateway Health
curl http://51.21.198.139:8080/actuator/health

# All registered services
curl http://51.21.198.139:8761/eureka/apps
```

## 🔄 Re-deploying

Every successful Jenkins pipeline build will automatically deploy to AWS. To manually re-deploy:

```bash
cd /Users/othmane.afilali/Desktop/mr-jenk
./deploy.sh
```

## 📧 Email Notifications

Jenkins is configured to send emails on:

- ✅ **Success**: Deployment completed successfully
- ❌ **Failure**: Build or deployment failed
- ⚠️ **Unstable**: Tests failed but build completed

Check your email after each pipeline run.

## 🎉 Next Steps

1. Set up a domain name (optional) and point it to 51.21.198.139
2. Configure SSL/TLS certificates with Let's Encrypt
3. Set up AWS CloudWatch for monitoring
4. Configure automated backups for MongoDB data
5. Set up log aggregation (ELK stack or CloudWatch Logs)
6. Implement blue-green deployment for zero-downtime updates

## 📝 Notes

- First deployment may take 5-10 minutes as Docker images are transferred
- Subsequent deployments will be faster (~3-5 minutes)
- Services take 1-2 minutes to fully start after containers are up
- MongoDB data persists in the `./uploads` directory on AWS instance
- Always test in development before deploying to production

---

**Need Help?** Check Jenkins console output or AWS instance logs for detailed error messages.
