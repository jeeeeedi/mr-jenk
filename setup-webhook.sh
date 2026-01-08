#!/bin/bash
# GitHub Webhook Setup Helper Script
# Run this after Jenkins is started

set -e

echo "================================================"
echo "  GitHub Webhook Setup for Jenkins"
echo "================================================"
echo ""

# Check if Jenkins is running
echo "Step 1: Checking if Jenkins is running..."
JENKINS_PORT=8080
if lsof -i -P | grep LISTEN | grep -q ":${JENKINS_PORT}"; then
    echo "✅ Jenkins is running on port ${JENKINS_PORT}"
else
    echo "❌ Jenkins is NOT running on port ${JENKINS_PORT}"
    echo ""
    echo "Please start Jenkins first:"
    echo "  - Docker: docker start jenkins (or your container name)"
    echo "  - Service: brew services start jenkins-lts"
    echo "  - Manual: java -jar jenkins.war"
    echo ""
    exit 1
fi

echo ""
echo "Step 2: Starting ngrok tunnel..."
echo ""
echo "⚠️  IMPORTANT: Keep this terminal window open!"
echo "   The tunnel will stay active while this runs."
echo ""
echo "Press Ctrl+C to stop the tunnel later"
echo ""
echo "Starting in 3 seconds..."
sleep 3

echo ""
echo "================================================"
echo "  🚀 NGROK TUNNEL ACTIVE"
echo "================================================"
echo ""
echo "COPY THE HTTPS URL SHOWN BELOW!"
echo "Format: https://xxxxx.ngrok.io"
echo ""
echo "Then follow these steps:"
echo ""
echo "1. Go to your GitHub repo → Settings → Webhooks → Add webhook"
echo "2. Paste: https://YOUR-NGROK-URL/github-webhook/"
echo "3. Content type: application/json"
echo "4. Events: Just the push event"
echo "5. Active: ✓ Checked"
echo "6. Click 'Add webhook'"
echo ""
echo "================================================"
echo ""

# Start ngrok
ngrok http ${JENKINS_PORT}
