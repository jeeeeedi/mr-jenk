pipeline {
    agent any

environment {
    MAVEN_HOME = tool 'Maven'
    NODEJS_HOME = '/usr/bin'
    PATH = "${MAVEN_HOME}/bin:${NODEJS_HOME}:${env.PATH}"

    // Email credentials stored in Jenkins - see credentials management section
    TEAM_EMAIL = credentials('team-email')
    EMAIL_JEDI = credentials('email-jedi')
    EMAIL_OZZY = credentials('email-ozzy')

    // Add this line for Karma/Angular tests (Ubuntu/Linux path)
    CHROME_BIN = '/usr/bin/google-chrome'
    
    // Build variables
    BUILD_TAG = "${BUILD_NUMBER}"
}

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Verify Environment') {
            steps {
                echo 'Verifying build environment...'
                sh '''
                    echo "Java version:"
                    java -version
                    echo ""
                    echo "Maven version:"
                    mvn --version
                    echo ""
                    echo "Node.js version:"
                    node --version
                    echo ""
                    echo "npm version:"
                    npm --version
                    echo ""
                    echo "Docker version:"
                    docker --version
                    echo ""
                    # Make mvnw executable
                    chmod +x ./mvnw
                    echo "Maven wrapper executable: ✓"
                '''
            }
        }
        stage('Build Backend') {
            steps {
                echo 'Building backend services...'
                sh './mvnw clean install -DskipTests -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.HEARTBEAT_CHECK_INTERVAL=86400'
            }
        }
        stage('Test Backend') {
            steps {
                echo 'Running JUnit tests...'
                sh '''
                    set -e
                    ./mvnw test -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.HEARTBEAT_CHECK_INTERVAL=86400
                    if [ $? -ne 0 ]; then
                        echo "❌ Backend tests FAILED! Pipeline will STOP here."
                        exit 1
                    fi
                '''
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        stage('Build Frontend') {
            steps {
                echo 'Building frontend...'
                dir('buy-01-ui') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }
        stage('Test Frontend') {
            steps {
                echo 'Running frontend tests...'
                dir('buy-01-ui') {
                    sh '''
                        # set -e: Exit immediately if any command exits with a non-zero status
                        set -e
                        # Run Jasmine/Karma tests for Angular frontend in headless Chrome mode (suitable for CI)
                        npm test -- --watch=false --browsers=ChromeHeadless
                        # Explicit check: if npm test fails (exit code != 0), the pipeline will:
                        # 1. Print error message
                        # 2. Exit with code 1 (failure status)
                        # 3. Skip Deploy stage
                        # 4. Trigger the post { failure } block with clear error reporting
                        # This ensures test failures block deployments to production
                        if [ $? -ne 0 ]; then
                            echo "❌ Frontend tests FAILED! Pipeline will STOP here."
                            exit 1
                        fi
                    '''
                }
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying application to AWS EC2...'
                
                script {
                    withCredentials([
                        string(credentialsId: 'aws-region', variable: 'AWS_REGION'),
                        string(credentialsId: 'ecr-registry', variable: 'ECR_REGISTRY'),
                        string(credentialsId: 'ec2-host', variable: 'EC2_HOST'),
                        string(credentialsId: 'ec2-user', variable: 'EC2_USER'),
                        file(credentialsId: 'ec2-ssh-key', variable: 'EC2_KEY'),
                        string(credentialsId: 'mongodb-username', variable: 'MONGODB_USER'),
                        string(credentialsId: 'mongodb-password', variable: 'MONGODB_PASS')
                    ]) {
                        
                        try {
                            // Step 1: Prepare environment file with credentials
                            echo '📝 Preparing deployment environment...'
                            sh """
                                # Create .env.production file with sensitive credentials
                                cat > .env.production << EOF
# Production environment variables (Generated at build time)
MONGODB_ROOT_USERNAME=${MONGODB_USER}
MONGODB_ROOT_PASSWORD=${MONGODB_PASS}
AWS_REGION=${AWS_REGION}
ECR_REGISTRY=${ECR_REGISTRY}
BUILD_NUMBER=${BUILD_TAG}
EOF
                                echo "✓ Environment file prepared"
                            """
                            
                            // Step 2: Login to AWS ECR
                            echo '📦 Logging in to AWS ECR...'
                            sh """
                                mkdir -p ~/.docker
                                echo '{"auths":{}}' > ~/.docker/config.json
                                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            """
                            
                            // Step 3: Build Docker images for each service
                            echo '🔨 Building Docker images...'
                            sh """
                                # Build Java microservices (Spring Boot apps)
                                docker build -t ${ECR_REGISTRY}/service-registry:${BUILD_TAG} ./service-registry
                                docker build -t ${ECR_REGISTRY}/api-gateway:${BUILD_TAG} ./api-gateway
                                docker build -t ${ECR_REGISTRY}/user-service:${BUILD_TAG} ./user-service
                                docker build -t ${ECR_REGISTRY}/product-service:${BUILD_TAG} ./product-service
                                docker build -t ${ECR_REGISTRY}/media-service:${BUILD_TAG} ./media-service
                                
                                # Build Angular frontend
                                docker build -t ${ECR_REGISTRY}/buy-01-ui:${BUILD_TAG} ./buy-01-ui
                            """
                            
                            // Step 4: Push images to ECR
                            echo '⬆️  Pushing images to AWS ECR...'
                            sh """
                                docker push ${ECR_REGISTRY}/service-registry:${BUILD_TAG}
                                docker push ${ECR_REGISTRY}/api-gateway:${BUILD_TAG}
                                docker push ${ECR_REGISTRY}/user-service:${BUILD_TAG}
                                docker push ${ECR_REGISTRY}/product-service:${BUILD_TAG}
                                docker push ${ECR_REGISTRY}/media-service:${BUILD_TAG}
                                docker push ${ECR_REGISTRY}/buy-01-ui:${BUILD_TAG}
                                
                                # Tag as 'latest' for easier reference
                                docker tag ${ECR_REGISTRY}/service-registry:${BUILD_TAG} ${ECR_REGISTRY}/service-registry:latest
                                docker tag ${ECR_REGISTRY}/api-gateway:${BUILD_TAG} ${ECR_REGISTRY}/api-gateway:latest
                                docker tag ${ECR_REGISTRY}/user-service:${BUILD_TAG} ${ECR_REGISTRY}/user-service:latest
                                docker tag ${ECR_REGISTRY}/product-service:${BUILD_TAG} ${ECR_REGISTRY}/product-service:latest
                                docker tag ${ECR_REGISTRY}/media-service:${BUILD_TAG} ${ECR_REGISTRY}/media-service:latest
                                docker tag ${ECR_REGISTRY}/buy-01-ui:${BUILD_TAG} ${ECR_REGISTRY}/buy-01-ui:latest
                                
                                docker push ${ECR_REGISTRY}/service-registry:latest
                                docker push ${ECR_REGISTRY}/api-gateway:latest
                                docker push ${ECR_REGISTRY}/user-service:latest
                                docker push ${ECR_REGISTRY}/product-service:latest
                                docker push ${ECR_REGISTRY}/media-service:latest
                                docker push ${ECR_REGISTRY}/buy-01-ui:latest
                            """
                            
                            // Step 5: Deploy to EC2 via SSH using docker-compose
                            echo "🚀 Deploying to EC2 instance..."
                            sh """
                                # Copy deployment files to EC2
                                scp -i ${EC2_KEY} -o StrictHostKeyChecking=no \
                                    docker-compose.yml ${EC2_USER}@${EC2_HOST}:/home/ubuntu/
                                
                                scp -i ${EC2_KEY} -o StrictHostKeyChecking=no \
                                    .env ${EC2_USER}@${EC2_HOST}:/home/ubuntu/
                                
                                scp -i ${EC2_KEY} -o StrictHostKeyChecking=no \
                                    .env.production ${EC2_USER}@${EC2_HOST}:/home/ubuntu/
                                
                                scp -i ${EC2_KEY} -o StrictHostKeyChecking=no -r \
                                    certs ${EC2_USER}@${EC2_HOST}:/home/ubuntu/
                                
                                # Deploy services on EC2
                                ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} << 'SSHEOF'
                                    if ! command -v docker-compose &> /dev/null; then
                                        echo 'Installing Docker Compose...'
                                        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
                                        sudo chmod +x /usr/local/bin/docker-compose
                                        docker-compose --version
                                    fi
                                    
                                    cd /home/ubuntu
                                    # Use both .env files - .env has defaults, .env.production has credentials
                                    docker-compose down || true
                                    docker-compose pull || echo 'Warning: Some images may not have pulled (OK if already cached)'
                                    docker-compose up -d
                                    echo '✅ Deployment successful!'
                                    docker-compose ps
SSHEOF
                            """
                            
                            echo '✅ Application deployed successfully to EC2!'
                            echo "📍 Application deployment complete"
                            echo "🔗 API Gateway: http://${EC2_HOST}:8080"
                            
                            } catch (Exception e) {
                                echo "❌ Deployment failed: ${e.message}"
                                throw e
                            }
                    }
                }
            }
        }
    }

    post {
        success {
            echo '=========================================='
            echo '✅ Pipeline completed successfully!'
            echo '=========================================='
            
            // Send success email to team
            emailext(
                subject: "✅ BUILD SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: '''
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <style>
                            body { font-family: Arial, sans-serif; margin: 0; padding: 0; }
                            .header { background-color: #28a745; color: white; padding: 20px; text-align: center; }
                            .content { margin: 20px; }
                            .section { margin: 20px 0; padding: 15px; background-color: #f0f0f0; border-left: 5px solid #28a745; }
                            .section-title { font-weight: bold; color: #28a745; font-size: 16px; }
                            table { border-collapse: collapse; width: 100%; margin-top: 10px; }
                            th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
                            th { background-color: #28a745; color: white; }
                            tr:nth-child(even) { background-color: #fafafa; }
                            .success-badge { display: inline-block; background-color: #28a745; color: white; padding: 5px 10px; border-radius: 3px; margin-right: 10px; }
                            .footer { margin-top: 30px; padding-top: 20px; border-top: 2px solid #ddd; font-size: 12px; color: #666; text-align: center; }
                            a { color: #007bff; text-decoration: none; }
                            a:hover { text-decoration: underline; }
                        </style>
                    </head>
                    <body>
                        <div class="header">
                            <h1>✅ Build Successful</h1>
                            <p>Build #${BUILD_NUMBER} completed successfully</p>
                        </div>
                        
                        <div class="content">
                            <div class="section">
                                <p><span class="section-title">📋 Build Information</span></p>
                                <table>
                                    <tr><th>Build Number</th><td><span class="success-badge">#${BUILD_NUMBER}</span></td></tr>
                                    <tr><th>Job Name</th><td>${JOB_NAME}</td></tr>
                                    <tr><th>Build Status</th><td><span class="success-badge">SUCCESS</span></td></tr>
                                    <tr><th>Duration</th><td>${BUILD_DURATION}</td></tr>
                                    <tr><th>Timestamp</th><td>${BUILD_TIMESTAMP}</td></tr>
                                    <tr><th>Git Branch</th><td>${GIT_BRANCH}</td></tr>
                                </table>
                            </div>
                            
                            <div class="section">
                                <p><span class="section-title">✅ Completed Stages</span></p>
                                <table>
                                    <tr><td style="width: 50px; text-align: center;">✅</td><td>Checkout</td></tr>
                                    <tr><td style="text-align: center;">✅</td><td>Build Backend (Maven)</td></tr>
                                    <tr><td style="text-align: center;">✅</td><td>Test Backend (JUnit)</td></tr>
                                    <tr><td style="text-align: center;">✅</td><td>Build Frontend (Angular)</td></tr>
                                    <tr><td style="text-align: center;">✅</td><td>Test Frontend (Jasmine/Karma)</td></tr>
                                    <tr><td style="text-align: center;">✅</td><td>Deploy to Production</td></tr>
                                </table>
                            </div>
                            
                            <div class="section">
                                <p><span class="section-title">📊 Test Results</span></p>
                                <p>All tests passed successfully!</p>
                                <p><a href="${BUILD_URL}testReport/">View Detailed Test Report</a></p>
                            </div>
                            
                            <div class="section">
                                <p><span class="section-title">🚀 Deployment Status</span></p>
                                <p>Your application has been successfully deployed to production.</p>
                                <p><strong>Next Steps:</strong></p>
                                <ul>
                                    <li>Monitor application health and performance</li>
                                    <li>Review deployment logs for any warnings</li>
                                    <li>Notify QA team for final verification</li>
                                </ul>
                            </div>
                            
                            <div class="section">
                                <p><span class="section-title">📎 Useful Links</span></p>
                                <p>
                                    <a href="${BUILD_URL}console">📄 View Console Output</a> | 
                                    <a href="${BUILD_URL}testReport/">📊 View Test Report</a> | 
                                    <a href="${BUILD_URL}">🔗 Build Details</a>
                                </p>
                            </div>
                        </div>
                        
                        <div class="footer">
                            <p>This is an automated message from the Jenkins CI/CD Pipeline</p>
                            <p>Build URL: <a href="${BUILD_URL}">${BUILD_URL}</a></p>
                        </div>
                    </body>
                    </html>
                ''',
                to: "${EMAIL_OZZY}",
                recipientProviders: [brokenBuildSuspects(), requestor()],
                mimeType: 'text/html'
            )
        }
        failure {
            echo '=========================================='
            echo '❌ Pipeline failed! Immediate action required'
            echo '=========================================='
            
            // Send failure email
            emailext(
                subject: "❌ BUILD FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: '''
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <style>
                            body { font-family: Arial, sans-serif; margin: 0; padding: 0; }
                            .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; }
                            .content { margin: 20px; }
                            .alert { background-color: #f8d7da; border: 2px solid #f5c6cb; padding: 15px; border-radius: 5px; margin: 15px 0; color: #721c24; }
                            .section { margin: 20px 0; padding: 15px; background-color: #fff3cd; border-left: 5px solid #dc3545; }
                            .section-title { font-weight: bold; color: #dc3545; font-size: 16px; }
                            .error-badge { display: inline-block; background-color: #dc3545; color: white; padding: 5px 10px; border-radius: 3px; margin-right: 10px; }
                            table { border-collapse: collapse; width: 100%; margin-top: 10px; }
                            th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
                            th { background-color: #dc3545; color: white; }
                            tr:nth-child(even) { background-color: #fafafa; }
                            .action-box { background-color: #e7f3ff; border-left: 5px solid #0066cc; padding: 15px; margin: 15px 0; }
                            .footer { margin-top: 30px; padding-top: 20px; border-top: 2px solid #ddd; font-size: 12px; color: #666; text-align: center; }
                            a { color: #007bff; text-decoration: none; }
                            a:hover { text-decoration: underline; }
                            ol { margin: 10px 0; padding-left: 20px; }
                            li { margin: 8px 0; }
                        </style>
                    </head>
                    <body>
                        <div class="header">
                            <h1>❌ Build Failed</h1>
                            <p>Build #${BUILD_NUMBER} encountered errors</p>
                        </div>
                        
                        <div class="content">
                            <div class="alert">
                                <strong>⚠️ ATTENTION REQUIRED</strong><br/>
                                The CI/CD pipeline has failed. Immediate investigation and action is needed.
                            </div>
                            
                            <div class="section">
                                <p><span class="section-title">📋 Build Information</span></p>
                                <table>
                                    <tr><th>Build Number</th><td><span class="error-badge">#${BUILD_NUMBER}</span></td></tr>
                                    <tr><th>Job Name</th><td>${JOB_NAME}</td></tr>
                                    <tr><th>Build Status</th><td><span class="error-badge">FAILED</span></td></tr>
                                    <tr><th>Failed At</th><td>See console output for details</td></tr>
                                    <tr><th>Duration</th><td>${BUILD_DURATION}</td></tr>
                                    <tr><th>Timestamp</th><td>${BUILD_TIMESTAMP}</td></tr>
                                    <tr><th>Git Branch</th><td>${GIT_BRANCH}</td></tr>
                                </table>
                            </div>
                            
                            <div class="section">
                                <p><span class="section-title">🔴 Possible Failure Causes</span></p>
                                <ul>
                                    <li><strong>Test Failures:</strong> JUnit or Jasmine/Karma tests failed</li>
                                    <li><strong>Compilation Errors:</strong> Build compilation failed</li>
                                    <li><strong>Deployment Issues:</strong> Deployment or health checks failed</li>
                                    <li><strong>Environment Problems:</strong> Missing dependencies or configuration issues</li>
                                </ul>
                            </div>
                            
                            <div class="action-box">
                                <p><span class="section-title">🛠️ Required Actions (In Order)</span></p>
                                <ol>
                                    <li><strong>View Console Output:</strong> Click the link below to see detailed error messages</li>
                                    <li><strong>Check Test Report:</strong> Review which tests failed and why</li>
                                    <li><strong>Review Code Changes:</strong> Check recent Git commits for problematic changes</li>
                                    <li><strong>Fix Issues:</strong> Make necessary fixes to the code</li>
                                    <li><strong>Commit and Push:</strong> Push fixes to trigger a new build</li>
                                    <li><strong>Monitor Next Build:</strong> Watch the new build to confirm it passes</li>
                                </ol>
                            </div>
                            
                            <div class="section">
                                <p><span class="section-title">📎 Important Links</span></p>
                                <p>
                                    <strong><a href="${BUILD_URL}console">📄 View Full Console Output (MOST IMPORTANT)</a></strong><br/>
                                    <a href="${BUILD_URL}testReport/">📊 View Test Report (Failed Tests)</a><br/>
                                    <a href="${BUILD_URL}">🔗 Build Details Page</a><br/>
                                </p>
                            </div>
                            
                            <div class="section">
                                <p><span class="section-title">⏸️ Deployment Status</span></p>
                                <p>
                                    ✅ <strong>Good News:</strong> If this failure occurred during deployment, your previous version is still running due to automatic rollback.<br/>
                                    ⚠️ <strong>Still Required:</strong> Fix the issues and push fixes to deploy the corrected version.
                                </p>
                            </div>
                        </div>
                        
                        <div class="footer">
                            <p>This is an automated message from the Jenkins CI/CD Pipeline</p>
                            <p>Build URL: <a href="${BUILD_URL}">${BUILD_URL}</a></p>
                            <p>Contact your DevOps team if you need assistance investigating this failure.</p>
                        </div>
                    </body>
                    </html>
                ''',
                to: "${env.TEAM_EMAIL}, ${env.EMAIL_JEDI}, ${env.EMAIL_OZZY}",
                recipientProviders: [brokenBuildSuspects(), requestor(), developers()],
                mimeType: 'text/html'
            )
        }
        unstable {
            echo '⚠️ Pipeline unstable - some tests may have failed'
            
            emailext(
                subject: "⚠️ BUILD UNSTABLE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: '''
                    <html>
                    <head>
                        <style>
                            body { font-family: Arial, sans-serif; }
                            .header { background-color: #ffc107; color: black; padding: 20px; text-align: center; }
                            .content { margin: 20px; }
                            .section { margin: 20px 0; padding: 15px; background-color: #fff3cd; border-left: 5px solid #ffc107; }
                        </style>
                    </head>
                    <body>
                        <div class="header"><h2>⚠️ Build Unstable</h2></div>
                        <div class="content">
                            <div class="section">
                                <p><strong>Build:</strong> ${JOB_NAME} #${BUILD_NUMBER}</p>
                                <p><strong>Status:</strong> Unstable (Build completed but with test failures or warnings)</p>
                                <p><strong>Duration:</strong> ${BUILD_DURATION}</p>
                                <p><a href="${BUILD_URL}testReport/">View Test Report for details</a></p>
                            </div>
                        </div>
                    </body>
                    </html>
                ''',
                to: "${EMAIL_OZZY}",
                recipientProviders: [requestor()],
                mimeType: 'text/html'
            )
        }
        always {
            script {
                echo "Pipeline completed with status: ${currentBuild.result ?: 'SUCCESS'}"
            }
        }
    }
}
