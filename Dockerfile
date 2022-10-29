# Stage 0 -build artifact from source
FROM maven:3.6-jdk-8 AS BUILD
WORKDIR /APP
COPY . .
RUN mvn package -DskipTests


FROM openjdk:18-alpine as RUN
WORKDIR /run
COPY --from=BUILD /app/target/demo-0.0.1-SNAPSHOT.jar demo.jar
ARG USER=devops
ENV HOME /home/$USER
RUN  adduser -D $USER && \
     chown $USER:$USER /run/demo.jar
USER $USER
EXPOSE 8080
CMD java  -jar /run/demo.jar
