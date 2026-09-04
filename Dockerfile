# syntax=docker/dockerfile:1
#
# Dockerfile for Jenkinsfile examples 04 and 05.
#
# Both pipelines run `docker build .` in the checked-out app workspace
# (github.com/hjtechai/simple-java-maven-app — a Spring Boot app), so this
# file must sit in that repo's ROOT, named exactly `Dockerfile`.
#
#   * example 04 — builds the image and runs a container smoke test
#                  (`curl http://<daemon-host>:8080/`), so the image MUST
#                  start a long-running HTTP server on port 8080.
#   * example 05 — same image, then tags it (git SHA + build number) and
#                  pushes it to a registry.
#
# Multi-stage: a fat Maven/JDK layer builds the jar, then only the jar is
# copied onto a small JRE base so the pushed image stays lean.

########################  build stage  ########################
FROM maven:3.9.11-eclipse-temurin-21 AS build
WORKDIR /src

# Resolve dependencies first so this layer is cached until pom.xml changes.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

# Then build. Tests already ran in the pipeline's "Build & Test" stage.
COPY src ./src
RUN mvn -B -q clean package -DskipTests

########################  runtime stage  #####################
FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app

# Don't run the app as root.
RUN groupadd --system app && useradd --system --gid app --home /app app
USER app

# Spring Boot repackages the executable jar in place and leaves the plain
# one as *.jar.original, so this glob matches exactly one file.
COPY --from=build --chown=app:app /src/target/*.jar app.jar

EXPOSE 8080
ENV JAVA_OPTS=""

# Cheap liveness probe with no extra packages: open a TCP socket to 8080.
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
    CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/8080' || exit 1

# `exec` so the JVM is PID 1 and receives SIGTERM on `docker stop`.
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
