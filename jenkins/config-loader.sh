# Deployment Configuration
# Source this file before running deployment scripts

# AWS Configuration
export AWS_DEPLOY_HOST="${AWS_DEPLOY_HOST:-13.61.234.232}"
export AWS_DEPLOY_USER="${AWS_DEPLOY_USER:-ec2-user}"
export AWS_DEPLOY_PATH="/home/${AWS_DEPLOY_USER}/buy-01-app"

# SSH Key Location (Jenkins)
export AWS_SSH_KEY="${AWS_SSH_KEY:-/var/lib/jenkins/.ssh/aws-deploy-key.pem}"

# Fallback SSH Key Location (Local)
if [ ! -f "$AWS_SSH_KEY" ] && [ -f "$HOME/Downloads/lastreal.pem" ]; then
    export AWS_SSH_KEY="$HOME/Downloads/lastreal.pem"
fi

# MongoDB Credentials (Load from secrets or environment)
export MONGO_ROOT_USERNAME="${MONGO_ROOT_USERNAME:-admin}"
export MONGO_ROOT_PASSWORD="${MONGO_ROOT_PASSWORD:?MONGO_ROOT_PASSWORD must be set}"

# API URLs
export API_GATEWAY_URL="${API_GATEWAY_URL:-http://${AWS_DEPLOY_HOST}:8080}"

# Validate configuration
if [ ! -f "$AWS_SSH_KEY" ]; then
    echo "❌ Error: SSH key not found at $AWS_SSH_KEY"
    echo "Please set AWS_SSH_KEY environment variable or place key in expected location"
    exit 1
fi
