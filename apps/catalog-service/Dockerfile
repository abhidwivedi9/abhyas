# Multi-stage build — same exit criteria as cart-service: image <200MB,
# non-root, clean Trivy scan. A full eclipse-temurin JRE alpine image is
# ~286MB on its own, well over budget — jlink builds a custom minimal JRE
# containing only the modules this app actually uses, which is the
# standard technique for shrinking Java runtime images.
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:21-jdk-alpine AS jlink
# Module set for a typical Spring Boot web app: base + reflection/AOT
# support, JMX, JNDI, HTTP client, JAAS/Kerberos (used transitively by
# some Spring auth paths), JDBC, XML, unsafe (Spring/Jackson use it), and
# elliptic-curve crypto (TLS). java.desktop is NOT about GUIs here — Spring's
# PropertyEditorSupport-based type conversion lives in java.beans, which is
# part of java.desktop; omitting it crashes startup (found by actually
# running the built image, not by guessing the "correct" minimal set).
RUN jlink \
    --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management,java.naming,java.net.http,java.security.jgss,java.sql,java.xml,jdk.unsupported,jdk.crypto.ec \
    --strip-debug --no-man-pages --no-header-files --compress=2 \
    --output /custom-jre

FROM alpine:3.21
RUN addgroup -S appuser && adduser -S appuser -G appuser
COPY --from=jlink /custom-jre /opt/java
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"
WORKDIR /app
COPY --from=builder --chown=appuser:appuser /build/target/catalog-service.jar app.jar

USER appuser
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD wget -q -O - http://localhost:8080/actuator/health | grep -q '"status":"UP"' || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
