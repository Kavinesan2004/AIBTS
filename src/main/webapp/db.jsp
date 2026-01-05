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
            Connection conn = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(
                        "jdbc:mysql://localhost:3306/aibts",
                        "root",
                        "Kavi@2004"
                );
            } catch (Exception e) {
                out.println("DB Error: " + e.getMessage());
            }
        %>

    </body>
</html>
