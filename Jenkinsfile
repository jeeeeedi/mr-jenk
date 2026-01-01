pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'Maven'
        PATH = "${MAVEN_HOME}/bin:${env.PATH}"
    }

    stages {
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
                sh 'mvn test'
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
                    // Using ChromeHeadless for CI environment
                    sh 'npm test -- --watch=false --browsers=ChromeHeadless'
                }
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                // Example deployment command
                // sh './deploy.sh'
                echo 'Simulating deployment to production environment...'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
            // mail to: 'team@example.com', subject: "Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "Build was successful. Check it out at ${env.BUILD_URL}"
        }
        failure {
            echo 'Pipeline failed!'
            // mail to: 'team@example.com', subject: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}", body: "Build failed. Check the logs at ${env.BUILD_URL}"
        }
    }
}
