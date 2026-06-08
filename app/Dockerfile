FROM gradle:8-jdk17-alpine AS builder

ENV GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx512m -Dorg.gradle.daemon=false -Dorg.gradle.workers.max=1"
WORKDIR /workspace
COPY settings.gradle build.gradle ./
COPY src ./src
RUN gradle clean bootJar --no-daemon --no-parallel --max-workers=1

FROM eclipse-temurin:17-jre-alpine

ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=60.0"
RUN addgroup -S spring && adduser -S spring -G spring
WORKDIR /app
COPY --from=builder /workspace/build/libs/*.jar app.jar
RUN mkdir -p /logs && chown -R spring:spring /logs /app

USER spring
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
