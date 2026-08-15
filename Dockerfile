FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY target/PMS.jar pms.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "pms.jar"]