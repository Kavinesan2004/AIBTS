<%-- 
    Document   : db
    Created on : Dec 24, 2025, 11:18:53 PM
    Author     : kavin
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>JSP Page</title>
    </head>
    <body>
        <<%@ page import="java.sql.*" %>
        <%
            String dbHost = System.getenv("DB_HOST");
            String dbUser = System.getenv("DB_USER");
            String dbPass = System.getenv("DB_PASS");
            String dbName = System.getenv("DB_NAME");

            Connection conn = DriverManager.getConnection(
                    "jdbc:mysql://" + dbHost + "/" + dbName,
                    dbUser,
                    dbPass
            );
        %>


    </body>
</html>
