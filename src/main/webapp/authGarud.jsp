<%@ page import="java.sql.*" %>
<%@ include file="db.jsp" %>

<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Integer uid = (Integer) session.getAttribute("user_id");

    PreparedStatement ps = conn.prepareStatement(
        "SELECT status FROM users WHERE user_id=?");
    ps.setInt(1, uid);
    ResultSet rs = ps.executeQuery();

    if (!rs.next() || !"ACTIVE".equals(rs.getString("status"))) {
        session.invalidate();   // ? AUTO LOGOUT
        response.sendRedirect("login.jsp?disabled=1");
        return;
    }
%>
