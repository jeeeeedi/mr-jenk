/*
 * =============================================================================
 * Jenkins CI/CD Pipeline - Local Deployment
 * =============================================================================
 * 
 * This pipeline builds, tests, and deploys the Buy01 application locally.
 * 
 * Structure:
 *   - jenkins/email-templates/  : HTML email templates
 *   - jenkins/scripts/          : Reusable shell scripts
 * 
 * Stages:
 *   1. Setup Environment  - Detect tools (Maven, Node, Chrome)
 *   2. Checkout           - Pull latest code from SCM
 *   3. Build Backend      - Compile Java services with Maven
 *   4. Test Backend       - Run JUnit tests
 *   5. Build Frontend     - Build Angular app
 *   6. Test Frontend      - Run Jasmine/Karma tests
 *   7. Deploy             - Build Docker images and deploy locally
 * =============================================================================
 */

pipeline {
    agent any
    
    triggers {
        githubPush()  // Trigger builds on GitHub push events via webhook
        
        // ===== WEBHOOK SETUP (Already configured!) =====
        // This pipeline now uses GitHub webhooks for instant builds.
        // Webhook instructions are at the bottom of this file.
    }

    environment {
        TEAM_EMAIL     = 'othmane.afilali@gritlab.ax,jedi.reston@gritlab.ax'
        DEPLOY_TARGET  = 'local'
        // CHROME_BIN is dynamically detected in detectEnvironment() function
    }

    stages {
        // =====================================================================
        // STAGE 1: Setup Environment
        // Dynamically detect tool paths for portability across machines
        // =====================================================================
        stage('Setup Environment') {
            steps {
                script {
                    detectEnvironment()
                }
            }
        }
        
        // =====================================================================
        // STAGE 2: Checkout
        // =====================================================================
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // =====================================================================
        // STAGE 3: Build Backend
        // =====================================================================
        stage('Build Backend') {
            steps {
                echo 'Building backend services...'
                sh './mvnw clean install -DskipTests'
            }
        }
        
        // =====================================================================
        // STAGE 4: Test Backend (JUnit)
        // =====================================================================
        stage('Test Backend') {
            steps {
                echo 'Running JUnit tests...'
                sh './mvnw test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        // =====================================================================
        // STAGE 5: Build Frontend
        // =====================================================================
        stage('Build Frontend') {
            steps {
                echo 'Building frontend...'
                dir('buy-01-ui') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }
        
        // =====================================================================
        // STAGE 6: Test Frontend (Jasmine/Karma)
        // =====================================================================
        stage('Test Frontend') {
            steps {
                echo 'Running frontend tests...'
                dir('buy-01-ui') {
                    sh 'npm test -- --watch=false --browsers=ChromeHeadlessCI'
                }
            }
        }
        
        // =====================================================================
        // STAGE 7: Deploy to Local Server
        // =====================================================================
        stage('Deploy') {
            steps {
                echo 'Deploying application to LOCAL SERVER...'
                script {
                    deployToLocal()
                }
            }
        }
    }

    // =========================================================================
    // POST-BUILD ACTIONS
    // =========================================================================
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            sendEmail('success')
        }
        failure {
            echo '❌ Pipeline failed!'
            sendEmail('failure')
        }
        unstable {
            echo '⚠️ Pipeline unstable'
            sendEmail('unstable')
        }
        always {
            echo "Pipeline completed with status: ${currentBuild.result ?: 'SUCCESS'}"
        }
    }
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Detects and configures environment paths for Maven, Java, Node, and Chrome
 */
def detectEnvironment() {
    env.MAVEN_HOME = sh(script: '''
        mvn -v 2>/dev/null | grep "Maven home" | cut -d: -f2 | xargs || echo "/opt/homebrew/Cellar/maven/3.9.11/libexec"
    ''', returnStdout: true).trim()
    
    env.JAVA_HOME = sh(script: '''
        java -XshowSettings:properties -version 2>&1 | grep "java.home" | cut -d= -f2 | xargs || echo ""
    ''', returnStdout: true).trim()
    
    env.NODE_PATH = sh(script: '''
        which node | xargs dirname || echo "/opt/homebrew/bin"
    ''', returnStdout: true).trim()
    
    env.CHROME_BIN = sh(script: '''
        if [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
            echo "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        elif [ -f "/usr/bin/google-chrome" ]; then
            echo "/usr/bin/google-chrome"
        elif [ -f "/usr/bin/chromium-browser" ]; then
            echo "/usr/bin/chromium-browser"
        elif [ -f "/usr/bin/chromium" ]; then
            echo "/usr/bin/chromium"
        else
            echo "google-chrome"
        fi
    ''', returnStdout: true).trim()
    
    env.PATH = "${env.MAVEN_HOME}/bin:${env.NODE_PATH}:/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
    
    echo """
    ==============================================
    ✓ Environment Configured
    ==============================================
    MAVEN_HOME: ${env.MAVEN_HOME}
    JAVA_HOME:  ${env.JAVA_HOME}
    NODE_PATH:  ${env.NODE_PATH}
    CHROME_BIN: ${env.CHROME_BIN}
    ==============================================
    """
}

/**
 * Deploys the application to the local Docker environment
 */
def deployToLocal() {
    sh '''
        echo "============================================"
        echo "   LOCAL SERVER DEPLOYMENT"
        echo "============================================"
        
        # Make scripts executable
        chmod +x jenkins/scripts/*.sh
        chmod +x deploy-local.sh rollback-local.sh
        
        # Pre-deployment cleanup
        ./jenkins/scripts/cleanup-docker.sh
        
        # Build Docker images
        ./jenkins/scripts/build-docker-images.sh ${BUILD_NUMBER}
        
        # Stop existing containers
        echo "Stopping existing containers..."
        docker compose -f docker-compose-local.yml down --remove-orphans || true
        
        # Start containers
        echo "Starting containers..."
        docker compose -f docker-compose-local.yml up -d
        
        # Run health checks
        ./jenkins/scripts/health-check.sh || {
            echo "❌ Health checks failed! Initiating rollback..."
            ./rollback-local.sh || true
            exit 1
        }
        
        echo "✅ LOCAL DEPLOYMENT SUCCESSFUL!"
        
        # Post-deployment cleanup
        ./jenkins/scripts/cleanup-docker.sh --volumes
    '''
}

/**
 * Sends email notification based on build status
 * @param status - 'success', 'failure', or 'unstable'
 */
def sendEmail(String status) {
    def subjectPrefix = [
        'success' : '✅ BUILD SUCCESS',
        'failure' : '❌ BUILD FAILED',
        'unstable': '⚠️ BUILD UNSTABLE'
    ]
    
    def recipients = [
        'success' : [requestor()],
        'failure' : [brokenBuildSuspects(), requestor(), developers()],
        'unstable': [requestor()]
    ]
    
    def template = readFile("jenkins/email-templates/${status}.html")
    
    emailext(
        subject: "${subjectPrefix[status]}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        body: template,
        to: env.TEAM_EMAIL,
        recipientProviders: recipients[status],
        mimeType: 'text/html'
    )
}

// =============================================================================
// GITHUB WEBHOOK SETUP INSTRUCTIONS
// =============================================================================
//
// Follow these steps to enable instant builds on git push (instead of polling):
//
// 1. INSTALL NGROK (if not already installed)
//    macOS:  brew install ngrok
//    Linux:  Download from https://ngrok.com/download
//
// 2. CREATE NGROK ACCOUNT & GET AUTH TOKEN
//    - Sign up: https://dashboard.ngrok.com/signup
//    - Get token: https://dashboard.ngrok.com/get-started/your-authtoken
//    - Configure: ngrok config add-authtoken YOUR_TOKEN_HERE
//
// 3. START NGROK TUNNEL
//    Run: ngrok http 8081
//    (Replace 8081 with your Jenkins port if different)
//    
//    You'll see output like:
//    Forwarding    https://abc123.ngrok.io -> http://localhost:8081
//                  ^^^^^^^^^^^^^^^^^^^^^^^^
//                  Copy this HTTPS URL!
//
// 4. CONFIGURE GITHUB WEBHOOK
//    a. Go to your GitHub repository
//    b. Click: Settings → Webhooks → Add webhook
//    c. Fill in:
//       Payload URL:    https://abc123.ngrok.io/github-webhook/
//                       (Use YOUR ngrok URL + /github-webhook/)
//       Content type:   application/json
//       Secret:         (leave empty)
//       SSL:            Enable SSL verification
//       Events:         ☑ Just the push event
//       Active:         ☑ Checked
//    d. Click "Add webhook"
//
// 5. VERIFY WEBHOOK
//    - GitHub will send a test ping
//    - Check webhook settings - you should see a green checkmark
//    - If it fails, verify ngrok is running and URL is correct
//
// 6. KEEP NGROK RUNNING
//    Option A: Run in foreground (simple, but stops when terminal closes)
//              ngrok http 8081
//    
//    Option B: Run in background (survives terminal close)
//              nohup ngrok http 8081 > /tmp/ngrok.log 2>&1 &
//              tail -f /tmp/ngrok.log  # to view the URL
//    
//    Option C: Use screen/tmux (best for long-running)
//              screen -S ngrok
//              ngrok http 8081
//              Ctrl+A, then D  # detach
//              screen -r ngrok # reattach later
//
// 7. TEST IT!
//    - Make a change to your code
//    - Git commit and push
//    - Jenkins should trigger a build automatically!
//    - Check Jenkins console for "Started by GitHub push"
//
// TROUBLESHOOTING:
// - Webhook shows red X: Check ngrok is running, URL is correct
// - Build not triggering: Check Jenkins logs for webhook events
// - ngrok URL changed: Update GitHub webhook URL (free tier gets new URL on restart)
//
// =============================================================================
