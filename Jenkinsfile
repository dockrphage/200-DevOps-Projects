pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'score-api'
        VERSION = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Workspace contents:"
                sh 'ls -la'
            }
        }
        
        stage('Build with Maven') {
            steps {
                // No need for dir() - we're already in the root
                sh 'mvn clean compile'
            }
        }
        
        stage('Package Application') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${VERSION} ."
                sh "docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest"
            }
        }
        
        stage('Deploy to Docker Host') {
            steps {
                script {
                    sh '''
                        docker stop score-api 2>/dev/null || true
                        docker rm score-api 2>/dev/null || true
                        docker run -d --name score-api -p 8080:8080 ${IMAGE_NAME}:${VERSION}
                        sleep 10
                        echo "Testing deployment..."
                        curl -f http://localhost:8080/api/scores/health
                    '''
                }
            }
        }
        
        stage('Integration Test') {
            steps {
                script {
                    sh '''
                        echo "Adding test score..."
                        curl -X POST "http://localhost:8080/api/scores/test?score=100"
                        
                        echo "Getting all scores..."
                        curl -s http://localhost:8080/api/scores
                        
                        echo "✅ Application deployed successfully!"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo """
            ═══════════════════════════════════════════════════════
            ✅ PIPELINE SUCCESSFUL!
            ═══════════════════════════════════════════════════════
            Application is running at: http://localhost:8080
            API Endpoints:
            - GET  /api/scores/health
            - GET  /api/scores/info  
            - GET  /api/scores
            - POST /api/scores/{player}?score={value}
            ═══════════════════════════════════════════════════════
            """
        }
        failure {
            echo "❌ Pipeline failed! Check the logs above."
        }
    }
}
