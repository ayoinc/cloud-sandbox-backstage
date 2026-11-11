FROM ${{ values.baseImage }} AS build
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

ENV PORT=${{ values.port }}

USER 10001:10001

EXPOSE ${{ values.port }}
{%- if values.includeHealthcheck %}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:${{ values.port }}/health"]
{%- endif %}

CMD ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
