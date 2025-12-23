# Build stage
FROM eclipse-temurin:${{ values.javaVersion }}-jdk-alpine AS builder

WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN apk add --no-cache maven && \
    mvn clean package -DskipTests

# Production stage
FROM eclipse-temurin:${{ values.javaVersion }}-jre-alpine

WORKDIR /app

RUN addgroup -g 1001 -S spring && \
    adduser -S spring -u 1001

COPY --from=builder /app/target/*.jar app.jar

USER spring

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

EXPOSE ${{ values.serverPort }}

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${{ values.serverPort }}/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
