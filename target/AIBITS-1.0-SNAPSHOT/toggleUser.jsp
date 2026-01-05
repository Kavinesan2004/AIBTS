<%@ page import="java.sql.*" %>
<%@ include file="db.jsp" %>

<%
    /* AUTH + ROLE CHECK */
    if (session.getAttribute("user") == null ||
        !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String uidParam = request.getParameter("user_id");
    String newStatus = request.getParameter("status");

    if (uidParam == null || newStatus == null) {
        response.sendRedirect("register.jsp");
        return;
    }

    int userId = Integer.parseInt(uidParam);
    int adminId = (Integer) session.getAttribute("user_id");

    try {
        /* UPDATE USER STATUS */
        PreparedStatement ps = conn.prepareStatement(
            "UPDATE users SET status=? WHERE user_id=?");
        ps.setString(1, newStatus);
        ps.setInt(2, userId);
        ps.executeUpdate();

        /* AUDIT LOG (NO asset_id ? this is USER ACTION) */
        PreparedStatement audit = conn.prepareStatement(
            "INSERT INTO decision_audit_log(action_type,reason,performed_by) VALUES(?,?,?)");
        audit.setString(1, "USER_" + newStatus);
        audit.setString(2, "Admin changed user status");
        audit.setInt(3, adminId);
        audit.executeUpdate();

    } catch (Exception e) {
        e.printStackTrace();
    }

    response.sendRedirect("register.jsp");
%>
