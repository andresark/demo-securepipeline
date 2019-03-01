FROM tomcat:8.5-jre8-alpine
ADD sample.war /usr/local/tomcat/webapps/
CMD ["catalina.sh", "run"]
