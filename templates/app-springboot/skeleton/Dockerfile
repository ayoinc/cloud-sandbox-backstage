FROM maven:3.9-eclipse-temurin-${{ values.javaVersion }} AS builder
WORKDIR /app
COPY pom.xml ./
COPY src ./src
RUN mvn --batch-mode --no-transfer-progress package -DskipTests

FROM eclipse-temurin:${{ values.javaVersion }}-jre-alpine
WORKDIR /app

RUN addgroup -g 1001 -S spring && \
    adduser -S spring -u 1001 -G spring

COPY --from=builder /app/target/*.jar app.jar

USER 1001:1001

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0"

EXPOSE ${{ values.serverPort }}

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:${{ values.serverPort }}/actuator/health"]

# The shell expands JAVA_OPTS; exec makes the JVM receive stop signals.
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
