pipeline {
    agent any
    
    tools {
        maven 'maven-3.9'
    }
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        IMAGE_NAME = 'score-api'
        VERSION = "${env.BUILD_NUMBER}"
        ARTIFACT_DIR = '/var/jenkins_home/artifacts'
    }
    
    stages {
        stage('SCM Checkout') {
            steps {
                checkout scm
                script {
                    def gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.GIT_COMMIT = gitCommit
                }
            }
        }
        
        stage('Build with Maven') {
            steps {
                sh 'mvn clean compile'
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Package Application') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }
        
        stage('Copy Artifacts') {
            steps {
                sh '''
                    mkdir -p ${ARTIFACT_DIR}/${BUILD_NUMBER}
                    cp target/app.jar ${ARTIFACT_DIR}/${BUILD_NUMBER}/
                    echo "Build ${BUILD_NUMBER} from commit ${GIT_COMMIT}" > ${ARTIFACT_DIR}/${BUILD_NUMBER}/build.info
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${VERSION}")
                    docker.build("${IMAGE_NAME}:latest")
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry("http://${DOCKER_REGISTRY}", 'docker-registry-creds') {
                        docker.image("${IMAGE_NAME}:${VERSION}").push()
                        docker.image("${IMAGE_NAME}:latest").push()
                    }
                }
            }
        }
        
        stage('Deploy to Docker Host') {
            steps {
                script {
                    sh '''
                        # Stop existing container if running
                        docker stop score-api || true
                        docker rm score-api || true
                        
                        # Run new container
                        docker run -d \
                            --name score-api \
                            --network devops-network \
                            -p 8080:8080 \
                            -e "SPRING_PROFILES_ACTIVE=production" \
                            -e "HOSTNAME=${HOSTNAME}" \
                            --restart unless-stopped \
                            ${DOCKER_REGISTRY}/${IMAGE_NAME}:${VERSION}
                        
                        # Wait for health check
                        sleep 10
                        curl -f http://localhost:8080/api/scores/health
                    '''
                }
            }
        }
        
        stage('Integration Test') {
            steps {
                script {
                    def response = sh(script: '''
                        curl -s http://localhost:8080/api/scores/info
                    ''', returnStdout: true).trim()
                    echo "Service Info: ${response}"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded! Application deployed successfully.'
            // Optional: Send Slack/Email notification
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
        }
        always {
            cleanWs()
        }
    }
}
