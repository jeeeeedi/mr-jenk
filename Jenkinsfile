pipeline {
    agent any
    
    triggers {
        pollSCM('* * * * *')  // Poll every minute for changes
    }

    environment {
        TEAM_EMAIL = 'othmane.afilali@gritlab.ax,jedi.reston@gritlab.ax'
        EMAIL_JEDI = 'jedi.reston@gritlab.ax'
        EMAIL_OZZY = 'othmane.afilali@gritlab.ax'
        
        // Local deployment flag
        DEPLOY_TARGET = 'local'
    }

    stages {
        stage('Setup Environment') {
            steps {
                script {
                    // Dynamically detect tool paths
                    env.MAVEN_HOME = sh(script: 'mvn -v 2>/dev/null | grep "Maven home" | cut -d: -f2 | xargs || echo "/opt/homebrew/Cellar/maven/3.9.11/libexec"', returnStdout: true).trim()
                    env.JAVA_HOME = sh(script: 'java -XshowSettings:properties -version 2>&1 | grep "java.home" | cut -d= -f2 | xargs || echo ""', returnStdout: true).trim()
                    env.NODE_PATH = sh(script: 'which node | xargs dirname || echo "/opt/homebrew/bin"', returnStdout: true).trim()
                    env.CHROME_BIN = sh(script: '''
                        if [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
                            echo "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
                        elif [ -f "/usr/bin/google-chrome" ]; then
                            echo "/usr/bin/google-chrome"
                        elif [ -f "/usr/bin/chromium-browser" ]; then
                            echo "/usr/bin/chromium-browser"
                        else
                            echo "chrome"
                        fi
                    ''', returnStdout: true).trim()
                    
                    // Update PATH
                    env.PATH = "${env.MAVEN_HOME}/bin:${env.NODE_PATH}:/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
                    
                    echo "=== Detected Environment ==="
                    echo "MAVEN_HOME: ${env.MAVEN_HOME}"
                    echo "JAVA_HOME: ${env.JAVA_HOME}"
                    echo "NODE_PATH: ${env.NODE_PATH}"
                    echo "CHROME_BIN: ${env.CHROME_BIN}"
                    echo "============================"
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Backend') {
            steps {
                echo 'Building backend services...'
                sh 'mvn clean install -DskipTests'
            }
        }
        
        stage('Test Backend') {
            steps {
                echo 'Running JUnit tests...'
                sh '''
                    set -e
                    mvn test
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
                        set -e
                        npm test -- --watch=false --browsers=ChromeHeadless
                        if [ $? -ne 0 ]; then
                            echo "❌ Frontend tests FAILED! Pipeline will STOP here."
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Deploy to Local Server') {
            steps {
                echo 'Deploying application to LOCAL SERVER...'
                script {
                    sh '''
                        echo "============================================"
                        echo "   LOCAL SERVER DEPLOYMENT"
                        echo "============================================"
                        
                        # Pre-deployment cleanup
                        echo "Pre-deployment cleanup to free disk space..."
                        docker images --format "{{.Repository}}:{{.Tag}}" | grep "buy01-pipeline.*:build-" | xargs -r docker rmi -f || true
                        docker image prune -a -f --filter "until=30m"
                        docker builder prune -f
                        echo "✓ Pre-deployment cleanup completed"
                        
                        # Build all Docker images with build number tags
                        echo "Building Docker images with build #${BUILD_NUMBER}..."
                        
                        docker build -t buy01-pipeline-service-registry:build-${BUILD_NUMBER} ./service-registry
                        docker build -t buy01-pipeline-api-gateway:build-${BUILD_NUMBER} ./api-gateway
                        docker build -t buy01-pipeline-user-service:build-${BUILD_NUMBER} ./user-service
                        docker build -t buy01-pipeline-product-service:build-${BUILD_NUMBER} ./product-service
                        docker build -t buy01-pipeline-media-service:build-${BUILD_NUMBER} ./media-service
                        docker build -t buy01-pipeline-frontend:build-${BUILD_NUMBER} ./buy-01-ui
                        
                        # Tag as latest
                        docker tag buy01-pipeline-service-registry:build-${BUILD_NUMBER} buy01-pipeline-service-registry:latest
                        docker tag buy01-pipeline-api-gateway:build-${BUILD_NUMBER} buy01-pipeline-api-gateway:latest
                        docker tag buy01-pipeline-user-service:build-${BUILD_NUMBER} buy01-pipeline-user-service:latest
                        docker tag buy01-pipeline-product-service:build-${BUILD_NUMBER} buy01-pipeline-product-service:latest
                        docker tag buy01-pipeline-media-service:build-${BUILD_NUMBER} buy01-pipeline-media-service:latest
                        docker tag buy01-pipeline-frontend:build-${BUILD_NUMBER} buy01-pipeline-frontend:latest
                        
                        echo "✓ All Docker images built with build-${BUILD_NUMBER} tags"
                        
                        # Make scripts executable
                        chmod +x deploy-local.sh
                        chmod +x rollback-local.sh
                        
                        # Stop existing containers
                        echo "Stopping existing containers..."
                        docker-compose -f docker-compose-local.yml down --remove-orphans || true
                        
                        # Start containers
                        echo "Starting containers with Docker Compose..."
                        docker-compose -f docker-compose-local.yml up -d
                        
                        # Health checks
                        echo "Running health checks..."
                        echo "Waiting for services to initialize (up to 2 minutes)..."
                        
                        HEALTH_CHECK_FAILED=0
                        MAX_RETRIES=24
                        RETRY_DELAY=5
                        
                        # Check Service Registry
                        echo -n "Checking Service Registry..."
                        RETRY=0
                        while [ $RETRY -lt $MAX_RETRIES ]; do
                            if curl -f -s http://localhost:8761 > /dev/null 2>&1; then
                                echo " ✓ healthy"
                                break
                            fi
                            RETRY=$((RETRY + 1))
                            echo -n "."
                            sleep $RETRY_DELAY
                        done
                        if [ $RETRY -eq $MAX_RETRIES ]; then
                            echo " ❌ failed"
                            HEALTH_CHECK_FAILED=1
                        fi
                        
                        # Check API Gateway
                        echo -n "Checking API Gateway..."
                        RETRY=0
                        while [ $RETRY -lt $MAX_RETRIES ]; do
                            if curl -f -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
                                echo " ✓ healthy"
                                break
                            fi
                            RETRY=$((RETRY + 1))
                            echo -n "."
                            sleep $RETRY_DELAY
                        done
                        if [ $RETRY -eq $MAX_RETRIES ]; then
                            echo " ❌ failed"
                            HEALTH_CHECK_FAILED=1
                        fi
                        
                        # Check Frontend
                        echo -n "Checking Frontend..."
                        RETRY=0
                        while [ $RETRY -lt $MAX_RETRIES ]; do
                            if curl -f -s http://localhost:4200 > /dev/null 2>&1; then
                                echo " ✓ healthy"
                                break
                            fi
                            RETRY=$((RETRY + 1))
                            echo -n "."
                            sleep $RETRY_DELAY
                        done
                        if [ $RETRY -eq $MAX_RETRIES ]; then
                            echo " ❌ failed"
                            HEALTH_CHECK_FAILED=1
                        fi
                        
                        if [ $HEALTH_CHECK_FAILED -eq 1 ]; then
                            echo "❌ Health checks failed! Initiating rollback..."
                            ./rollback-local.sh || true
                            exit 1
                        fi
                        
                        echo "✅ LOCAL DEPLOYMENT SUCCESSFUL!"
                        echo ""
                        echo "🌐 Application URLs:"
                        echo "   Frontend:         http://localhost:4200"
                        echo "   API Gateway:      http://localhost:8080"
                        echo "   Service Registry: http://localhost:8761"
                        echo ""
                        
                        # Post-deployment cleanup
                        docker image prune -a -f --filter "until=30m"
                        docker builder prune -f --filter "until=30m"
                        docker volume prune -f
                        echo "✓ Post-deployment cleanup completed"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '=========================================='
            echo '✅ Pipeline completed successfully!'
            echo '   Application deployed to LOCAL SERVER'
            echo '=========================================='
            
            emailext(
                subject: "✅ LOCAL DEPLOY SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>✅ Build Successful</h2>
                    <p><strong>Build:</strong> ${env.JOB_NAME} #${env.BUILD_NUMBER}</p>
                    <p><strong>Status:</strong> Deployed to Local Server</p>
                    <h3>Application URLs:</h3>
                    <ul>
                        <li>Frontend: <a href="http://localhost:4200">http://localhost:4200</a></li>
                        <li>API Gateway: <a href="http://localhost:8080">http://localhost:8080</a></li>
                        <li>Service Registry: <a href="http://localhost:8761">http://localhost:8761</a></li>
                    </ul>
                    <p><a href="${env.BUILD_URL}">View Build Details</a></p>
                """,
                to: "${EMAIL_OZZY}",
                mimeType: 'text/html'
            )
        }
        failure {
            echo '=========================================='
            echo '❌ Pipeline failed!'
            echo '=========================================='
            
            emailext(
                subject: "❌ LOCAL DEPLOY FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>❌ Build Failed</h2>
                    <p><strong>Build:</strong> ${env.JOB_NAME} #${env.BUILD_NUMBER}</p>
                    <p><strong>Status:</strong> FAILED</p>
                    <p>Please check the console output for details.</p>
                    <p><a href="${env.BUILD_URL}console">View Console Output</a></p>
                """,
                to: "${env.TEAM_EMAIL}",
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
