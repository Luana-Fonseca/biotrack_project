FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q clean package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/biotrack-api.jar app.jar
# Render assigns the port to listen on via $PORT at runtime (it is not always 8080),
# so server.port in application.yml reads it from there instead of a fixed value.
ENTRYPOINT ["java", "-jar", "app.jar"]
