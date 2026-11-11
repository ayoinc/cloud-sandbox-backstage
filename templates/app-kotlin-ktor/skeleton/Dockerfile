FROM eclipse-temurin:25-jdk AS build
WORKDIR /src

# Dependencies are downloaded in their own layer, reused until the build
# files change.
COPY gradlew settings.gradle.kts build.gradle.kts gradle.properties ./
COPY gradle ./gradle
RUN ./gradlew --no-daemon dependencies > /dev/null

COPY src ./src
RUN ./gradlew --no-daemon buildFatJar

# No shell and no package manager: the image holds the JRE and the JAR. Health
# is checked by the orchestrator's HTTP probes.
FROM gcr.io/distroless/java25-debian13:nonroot AS production
WORKDIR /app

ENV PORT=${{ values.port }}

COPY --from=build /src/build/libs/app.jar ./app.jar

USER 65532:65532

EXPOSE ${{ values.port }}

ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "--enable-native-access=ALL-UNNAMED", "-jar", "/app/app.jar"]
