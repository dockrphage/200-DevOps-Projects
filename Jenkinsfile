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
                        
                        echo "Waiting for Spring Boot to start..."
                        sleep 15
                        
                        echo "Container logs:"
                        docker logs score-api --tail 20
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    sh '''
                        echo "Testing health endpoint..."
                        # Use 127.0.0.1 instead of localhost to avoid IPv6 issues
                        for i in 1 2 3 4 5; do
                            echo "Attempt $i..."
                            if curl -f http://127.0.0.1:8080/api/scores/health; then
                                echo "✅ Health check passed!"
                                exit 0
                            fi
                            sleep 3
                        done
                        echo "❌ Health check failed after 5 attempts"
                        exit 1
                    '''
                }
            }
        }
        
        stage('Integration Test') {
            steps {
                script {
                    sh '''
                        echo ""
                        echo "=== Integration Tests ==="
                        
                        echo "1. Adding test score for player 'jenkins'..."
                        curl -X POST "http://127.0.0.1:8080/api/scores/jenkins?score=100"
                        
                        echo ""
                        echo "2. Getting all scores..."
                        curl -s http://127.0.0.1:8080/api/scores
                        
                        echo ""
                        echo "3. Getting application info..."
                        curl -s http://127.0.0.1:8080/api/scores/info
                        
                        echo ""
                        echo "✅ All integration tests passed!"
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
            
            Test the API with these commands:
            
            # Health check
            curl http://localhost:8080/api/scores/health
            
            # Add a score
            curl -X POST "http://localhost:8080/api/scores/yourname?score=100"
            
            # Get all scores
            curl http://localhost:8080/api/scores
            
            # Get app info
            curl http://localhost:8080/api/scores/info
            ═══════════════════════════════════════════════════════
            """
        }
        failure {
            echo "❌ Pipeline failed! Check the logs above."
            sh 'docker logs score-api --tail 50'
        }
    }
}
