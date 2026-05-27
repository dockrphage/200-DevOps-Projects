#!/bin/bash
cd ~/200Proj/DevO-Pro-01

echo "=== Checking Project Structure ==="
[ -f pom.xml ] && echo "✅ pom.xml exists" || echo "❌ pom.xml missing"
[ -f Dockerfile ] && echo "✅ Dockerfile exists" || echo "❌ Dockerfile missing"
[ -f Jenkinsfile ] && echo "✅ Jenkinsfile exists" || echo "❌ Jenkinsfile missing"
[ -d src/main/java/com/devops/demo ] && echo "✅ Java source directories exist" || echo "❌ Source directories missing"

echo -e "\n=== Checking pom.xml content ==="
head -5 pom.xml

echo -e "\n=== Checking Java files ==="
ls -la src/main/java/com/devops/demo/

echo -e "\n=== Testing Maven Build ==="
mvn clean compile -q && echo "✅ Maven build successful" || echo "❌ Maven build failed"
