

A **complete base application** (a simple Spring Boot REST API) and a **DevOps pipeline** enhanced with modern practices you can discuss in interviews. This is an excellent hands-on plan for a DevOps interview. A laptop (i7 11th gen, 16GB RAM) with Vagrant, Kubernetes, and Docker is perfect for this.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Ubuntu Laptop (Host)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   Jenkins    │  │  Docker Host │  │     Kubernetes       │   │
│  │   Container  │  │   (Daemon)   │  │     (Optional)       │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│         ↑                 ↑                      ↑               │
│         │                 │                      │               │
│  ┌──────┴─────────────────┴──────────────────────┴──────┐        │
│  │              GitHub (Your Repo)                       │        │
│  └──────────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

## Base Application: Simple Score API (Java + Spring Boot)

Create this application to demonstrate real CI/CD concepts.

```java
// src/main/java/com/devops/demo/DemoApplication.java
package com.devops.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

```java
// src/main/java/com/devops/demo/ScoreController.java
package com.devops.demo;

import org.springframework.web.bind.annotation.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/scores")
public class ScoreController {
    
    private Map<String, Integer> scores = new ConcurrentHashMap<>();
    
    @GetMapping
    public Map<String, Integer> getAllScores() {
        return scores;
    }
    
    @PostMapping("/{player}")
    public String addScore(@PathVariable String player, @RequestParam int score) {
        scores.put(player, scores.getOrDefault(player, 0) + score);
        return "Score added for " + player + ". Total: " + scores.get(player);
    }
    
    @GetMapping("/health")
    public String health() {
        return "OK";
    }
    
    @GetMapping("/info")
    public Map<String, String> info() {
        return Map.of(
            "version", System.getProperty("app.version", "1.0.0"),
            "environment", System.getProperty("spring.profiles.active", "default"),
            "hostname", System.getenv().getOrDefault("HOSTNAME", "unknown")
        );
    }
}
```

```xml
<!-- pom.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.1.5</version>
    </parent>
    
    <groupId>com.devops</groupId>
    <artifactId>score-api</artifactId>
    <version>${revision}</version>
    <packaging>jar</packaging>
    
    <properties>
        <revision>1.0.0</revision>
        <java.version>17</java.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
        <finalName>app</finalName>
    </build>
</project>
```

```dockerfile
# Dockerfile
FROM openjdk:17-jdk-slim AS builder
WORKDIR /app
COPY target/app.jar app.jar

FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=builder /app/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```yaml
# docker-compose.yml (for local testing)
version: '3.8'
services:
  score-api:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/scores/health"]
      interval: 10s
      timeout: 5s
      retries: 5
```

## Step-by-Step Implementation Guide

### Step 1: Setup Jenkins Server

```bash
# Create Jenkins Docker network
docker network create devops-network

# Run Jenkins with Docker-in-Docker (DinD) approach
docker run -d \
  --name jenkins \
  --network devops-network \
  -p 8081:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  -e DOCKER_HOST=unix:///var/run/docker.sock \
  jenkins/jenkins:lts-jdk17

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
# Visit http://localhost:8081
```

### Step 2: Integrate GitHub with Jenkins

```bash
# Generate SSH key for Jenkins
docker exec -it jenkins ssh-keygen -t rsa -b 4096 -C "jenkins@devops" -f ~/.ssh/id_rsa -N ""

# Get public key to add to GitHub
docker exec -it jenkins cat ~/.ssh/id_rsa.pub
```

**In Jenkins UI:**
1. Install plugins: GitHub, Pipeline, Credentials Binding
2. Manage Jenkins → Credentials → Add SSH key
3. Create new Pipeline job with SCM pointing to your GitHub repo

### Step 3: Integrate Maven with Jenkins

```bash
# Install Maven in Jenkins container
docker exec -it jenkins bash -c "
  apt-get update && \
  apt-get install -y maven && \
  mvn --version
"

# Or use Maven Jenkins Plugin with auto-installation
```

**Jenkins Global Tool Configuration:**
- Name: `maven-3.9`
- Install automatically from Apache

### Step 4: Setup Docker Host

```bash
# Docker is already running on your laptop
# Verify:
docker info

# Create a directory for artifacts
mkdir -p ~/devops-artifacts

# Set up Docker registry for local images
docker run -d \
  --name registry \
  -p 5000:5000 \
  -v registry_data:/var/lib/registry \
  registry:2
```

### Step 5: Integrate Docker with Jenkins

```bash
# Grant Jenkins permission to use Docker
sudo usermod -aG docker $USER
newgrp docker

# Or use Docker pipeline plugin
# In Jenkins, install: Docker Pipeline, Docker Commons
```

### Step 6: Create Jenkins Job (Pipeline as Code)

Create `Jenkinsfile` in your repository:

```groovy
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
```

### Step 7: Update Dockerfile for Artifact Copy

Your Dockerfile already handles this. For production, enhance it:

```dockerfile
# Enhanced Dockerfile with multi-stage and security
FROM openjdk:17-jdk-slim AS builder
WORKDIR /build
COPY target/app.jar app.jar

FROM openjdk:17-jre-slim
RUN addgroup --system appgroup && \
    adduser --system --no-create-home --ingroup appgroup appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /build/app.jar app.jar

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/scores/health || exit 1

ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=${SPRING_PROFILE}", "app.jar"]
```

### Step 8: Automate Build and Deployment

Create a webhook trigger or use Poll SCM. For complete automation, create a GitHub Actions webhook:

```bash
# On your laptop, create a webhook receiver (optional, for GitHub)
# Install ngrok to expose Jenkins to GitHub
docker run -it --rm ngrok/ngrok:latest http host.docker.internal:8081
# Add the ngrok URL to GitHub webhooks with /github-webhook/ endpoint
```

Or use Poll SCM in Jenkins (for simplicity):
- Jenkins job → Configure → Build Triggers → Poll SCM
- Schedule: `H/5 * * * *` (every 5 minutes)

## Interview Practice Scenarios

### Scenario 1: Canary Deployment
```groovy
// Add to your pipeline
stage('Canary Deployment') {
    when { branch 'main' }
    steps {
        sh '''
            docker run -d --name score-api-canary \
                -p 8081:8080 \
                ${DOCKER_REGISTRY}/${IMAGE_NAME}:${VERSION}
            
            # Run smoke tests against canary
            curl -f http://localhost:8081/api/scores/health
        '''
    }
}
```

### Scenario 2: Rollback Capability
```bash
# Manual rollback command
docker stop score-api && docker rm score-api
docker run -d --name score-api -p 8080:8080 localhost:5000/score-api:${PREVIOUS_VERSION}
```

### Scenario 3: Blue-Green Deployment
```groovy
stage('Blue-Green Deployment') {
    steps {
        sh '''
            # Check current active environment
            if docker ps | grep -q "score-api-blue"; then
                DEPLOY_COLOR="green"
                OLD_COLOR="blue"
            else
                DEPLOY_COLOR="blue"
                OLD_COLOR="green"
            fi
            
            docker run -d --name score-api-${DEPLOY_COLOR} \
                -p 80${DEPLOY_COLOR == "blue" ? 80 : 81}:8080 \
                ${DOCKER_REGISTRY}/${IMAGE_NAME}:${VERSION}
            
            # Wait and test
            curl -f http://localhost:80${DEPLOY_COLOR == "blue" ? 80 : 81}/api/scores/health
            
            # Switch traffic
            docker stop score-api-proxy || true
            docker run -d --name score-api-proxy -p 8080:80 \
                -e UPSTREAM=http://score-api-${DEPLOY_COLOR}:8080 \
                nginx
            
            # Remove old
            docker stop score-api-${OLD_COLOR} && docker rm score-api-${OLD_COLOR}
        '''
    }
}
```

## Validation Script

```bash
#!/bin/bash
# test-pipeline.sh - Validate your entire setup

echo "1. Testing Jenkins..."
curl -s http://localhost:8081/login | grep -q "jenkins" && echo "✓ Jenkins OK"

echo "2. Testing Application..."
curl -s http://localhost:8080/api/scores/health | grep -q "OK" && echo "✓ App OK"

echo "3. Testing API Endpoints..."
curl -X POST "http://localhost:8080/api/scores/alice?score=100"
curl -s http://localhost:8080/api/scores | grep -q "alice" && echo "✓ Score stored"

echo "4. Testing Docker Registry..."
curl -s http://localhost:5000/v2/_catalog | grep -q "score-api" && echo "✓ Registry OK"

echo "5. Testing Jenkins Pipeline..."
curl -X POST http://localhost:8081/job/score-api/build?token=YOUR_TOKEN

echo "All systems operational!"
```

## Interview Talking Points

1. **Why Jenkins over GitHub Actions?** - Jenkins offers more plugins, runs anywhere, and has extensive pipeline libraries
2. **Artifact versioning strategy** - Using build numbers + Git commit SHA
3. **Security considerations** - Docker socket mounting vs Docker-in-Docker, secrets management
4. **Scaling approach** - Jenkins agents, Docker swarm, Kubernetes deployment (next step)
5. **Monitoring** - Health checks, logs with `docker logs`, Prometheus metrics via actuator

## Next-Level Kubernetes Integration (Bonus)

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: score-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: score-api
  template:
    metadata:
      labels:
        app: score-api
    spec:
      containers:
      - name: app
        image: localhost:5000/score-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "k8s"
```

To deploy to Kubernetes from Jenkins:
```groovy
stage('Deploy to Kubernetes') {
    steps {
        sh '''
            kubectl set image deployment/score-api \
                app=localhost:5000/score-api:${VERSION} \
                --record
            kubectl rollout status deployment/score-api
        '''
    }
}
```

This complete setup will give you deep, practical knowledge to discuss in interviews - from basic CI/CD to advanced deployment strategies. Practice explaining each component and why you made specific architectural choices.