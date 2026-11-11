FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /build
COPY src ./src
RUN javac -d classes src/main/java/app/Main.java && \
    jar --create --file app.jar --main-class app.Main -C classes .

# Built by the pipeline with --target test: runs the unit tests.
FROM build AS test
RUN javac -cp classes -d test-classes src/test/java/app/MainTest.java && \
    java -ea -cp classes:test-classes app.MainTest

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /build/app.jar ./

ENV PORT=8080

USER 10001:10001

EXPOSE 8080

CMD ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
