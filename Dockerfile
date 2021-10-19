FROM tomcat:9.0.41-jdk8-openjdk
COPY target/simple-app.war webapps/simple-app.war
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=6s --start-period=10s --retries=3 CMD curl -f http://localhost:8080/simple-app/index.jsp || exit 1