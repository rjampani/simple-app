<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<%@ page import="java.net.InetAddress" %>
<!DOCTYPE html>
<html>
    <head>
        <title>Simple Applicaiton</title>
    </head>
    <body style="margin: 10px 100px auto; padding: 10px 50px; font-size: 25px;">
    	<div style="margin: 20px 20px auto; padding: 20px 20px; width: 50%">
	        <h1>Simple Applicaiton Home Page</h1>
	        <hr/>
	        <br/><br/><br/><br/><br/><br/><br/>
	        <hr style="clear: both;"/>
	        Server IP: <%=request.getLocalAddr()%><br/>
	        Server HostName: <%=request.getLocalName()%><br/>
        </div>
    </body>
</html>