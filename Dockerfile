# Stage 1: Build stage (using the full JDK)
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
# Copy the built jar from the target folder
COPY target/app.jar app.jar

# Stage 2: Final runtime stage (using only the JRE for a smaller image)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
# Copy the jar from the build stage
COPY --from=builder /app/app.jar app.jar

# Expose the port your app runs on
EXPOSE 8080

# Run the jar file
ENTRYPOINT ["java", "-jar", "app.jar"]
