pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'score-api'
        VERSION = "${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = 'localhost:5000'
        APP_DIR = 'DevO-Pro-01'  // Add this line
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    def gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.GIT_COMMIT = gitCommit
                    echo "Building commit: ${env.GIT_COMMIT}"
                }
            }
        }
        
        stage('Build with Maven') {
            steps {
                script {
                    dir("${env.APP_DIR}") {
                        sh '''
                            echo "Building in directory: $(pwd)"
                            echo "Maven version:"
                            mvn --version
                            echo "Files in directory:"
                            ls -la
                            echo "Starting build..."
                            mvn clean compile
                        '''
                    }
                }
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                dir("${env.APP_DIR}") {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit "${env.APP_DIR}/target/surefire-reports/*.xml"
                }
            }
        }
        
        stage('Package Application') {
            steps {
                dir("${env.APP_DIR}") {
                    sh 'mvn package -DskipTests'
                    sh 'ls -la target/'
                }
            }
        }
        
        stage('Copy Artifacts') {
            steps {
                script {
                    sh """
                        mkdir -p \${ARTIFACT_DIR}/\${BUILD_NUMBER}
                        cp ${APP_DIR}/target/app.jar \${ARTIFACT_DIR}/\${BUILD_NUMBER}/
                        echo "Build \${BUILD_NUMBER} from commit \${GIT_COMMIT}" > \${ARTIFACT_DIR}/\${BUILD_NUMBER}/build.info
                    """
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    dir("${env.APP_DIR}") {
                        sh "docker build -t ${IMAGE_NAME}:${VERSION} ."
                        sh "docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest"
                    }
                }
            }
        }
        
        stage('Deploy to Docker Host') {
            steps {
                script {
                    sh '''
                        # Stop and remove existing container
                        docker stop score-api 2>/dev/null || true
                        docker rm score-api 2>/dev/null || true
                        
                        # Run new container
                        docker run -d \
                            --name score-api \
                            -p 8080:8080 \
                            --restart unless-stopped \
                            ${IMAGE_NAME}:${VERSION}
                        
                        # Wait for container to start
                        sleep 10
                        
                        # Check if container is running
                        if docker ps | grep -q score-api; then
                            echo "Container is running"
                            docker logs score-api --tail 20
                        else
                            echo "Container failed to start"
                            docker logs score-api
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Integration Test') {
            steps {
                script {
                    sh '''
                        echo "Testing health endpoint..."
                        curl -f http://localhost:8080/api/scores/health || exit 1
                        
                        echo "Testing info endpoint..."
                        curl -s http://localhost:8080/api/scores/info
                        
                        echo "✅ Application deployed successfully!"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded! Application deployed successfully.'
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
        }
    }
}