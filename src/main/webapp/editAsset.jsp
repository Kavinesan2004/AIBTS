<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    /* ADMIN SECURITY */
    if (session.getAttribute("user") == null
            || !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect("viewAssets.jsp");
        return;
    }

    int assetId = Integer.parseInt(request.getParameter("id"));
    int adminId = (Integer) session.getAttribute("user_id");

    /* UPDATE LOGIC */
    if ("POST".equalsIgnoreCase(request.getMethod())) {

        String category = request.getParameter("category");
        String status = request.getParameter("status");
        String reason = request.getParameter("reason");

        /* 1️⃣ Update Asset Core */
        PreparedStatement up = conn.prepareStatement(
                "UPDATE asset_core SET category=?, status=? WHERE asset_id=?");
        up.setString(1, category);
        up.setString(2, status);
        up.setInt(3, assetId);
        up.executeUpdate();
        /* 🔴 AUTO TRUST DROP IF LOST */
        if ("LOST".equals(status)) {

            /* Fetch previous trust score */
            PreparedStatement prev = conn.prepareStatement(
                    "SELECT current_trust_score FROM asset_core WHERE asset_id=?");
            prev.setInt(1, assetId);
            ResultSet prs = prev.executeQuery();

            int oldScore = 0;
            if (prs.next()) {
                oldScore = prs.getInt(1);
            }

            /* Force trust score to ZERO */
            PreparedStatement trustUpdate = conn.prepareStatement(
                    "UPDATE asset_core SET current_trust_score=0 WHERE asset_id=?");
            trustUpdate.setInt(1, assetId);
            trustUpdate.executeUpdate();

            /* Log trust collapse */
            PreparedStatement trustLog = conn.prepareStatement(
                    "INSERT INTO trust_score_log(asset_id,old_score,new_score,reason) VALUES(?,?,?,?)");
            trustLog.setInt(1, assetId);
            trustLog.setInt(2, oldScore);
            trustLog.setInt(3, 0);
            trustLog.setString(4, "Asset marked as LOST – trust invalidated");
            trustLog.executeUpdate();
        }

        /* 2️⃣ Decision Audit Log */
        PreparedStatement audit = conn.prepareStatement(
                "INSERT INTO decision_audit_log(asset_id,action_type,reason,performed_by) VALUES(?,?,?,?)");
        audit.setInt(1, assetId);
        audit.setString(2, "STATUS_UPDATE");
        audit.setString(3, "Status changed to " + status + " : " + reason);
        audit.setInt(4, adminId);
        audit.executeUpdate();

        response.sendRedirect("viewAssets.jsp");
        return;
    }

    /* FETCH CURRENT ASSET */
    PreparedStatement ps = conn.prepareStatement(
            "SELECT * FROM asset_core WHERE asset_id=?");
    ps.setInt(1, assetId);
    ResultSet rs = ps.executeQuery();
    rs.next();
%>

<!DOCTYPE html>
<html>
    <head>
        <title>Edit Asset | KN AIBTS</title>

        <style>
            body{
                margin:0;
                font-family:Segoe UI;
                background:#050a10;
                color:#f1f5f9;
                display:flex;
            }

            .sidebar{
                width:260px;
                background:#0f172a;
                padding:30px;
                height:100vh;
            }

            .sidebar a{
                display:block;
                color:#94a3b8;
                text-decoration:none;
                padding:12px;
                border-radius:6px;
                margin-bottom:6px;
            }

            .sidebar a:hover{
                background:#1e293b;
                color:#38bdf8;
            }

            .main{
                padding:50px;
                flex:1;
            }

            .card{
                background:#1e293b;
                padding:30px;
                border-radius:14px;
                max-width:520px;
                border:1px solid rgba(255,255,255,.08);
            }

            h2{
                margin-top:0;
                color:#38bdf8;
            }

            label{
                font-size:13px;
                color:#94a3b8;
                margin-top:16px;
                display:block;
            }

            input,select,textarea{
                width:100%;
                padding:12px;
                margin-top:6px;
                background:#020617;
                border:1px solid rgba(255,255,255,.15);
                border-radius:8px;
                color:white;
            }

            textarea{
                resize:none;
                height:70px;
            }

            button{
                margin-top:25px;
                width:100%;
                padding:14px;
                background:#38bdf8;
                border:none;
                border-radius:10px;
                font-weight:bold;
                cursor:pointer;
            }

            button:hover{
                background:#60a5fa;
            }

            .meta{
                font-size:13px;
                margin-bottom:20px;
                color:#cbd5f5;
            }
        </style>
    </head>

    <body>

        <div class="sidebar">
            <a href="assetDashboard.jsp">📊 Dashboard</a>
            <a href="viewAssets.jsp">📦 Assets</a>
            <a href="logout.jsp" style="color:#ef4444">Logout</a>
        </div>

        <div class="main">
            <div class="card">

                <h2>Edit Asset #<%=assetId%></h2>

                <div class="meta">
                    Trust Score: <b><%=rs.getInt("current_trust_score")%></b><br>
                    Current Status: <b><%=rs.getString("status")%></b>
                </div>

                <form method="post">

                    <label>Category</label>
                    <input name="category" value="<%=rs.getString("category")%>" required>

                    <label>Status</label>
                    <select name="status" required>
                        <option value="ACTIVE" <%= "ACTIVE".equals(rs.getString("status")) ? "selected" : ""%>>ACTIVE</option>
                        <option value="RETIRED" <%= "RETIRED".equals(rs.getString("status")) ? "selected" : ""%>>RETIRED</option>
                        <option value="LOST" <%= "LOST".equals(rs.getString("status")) ? "selected" : ""%>>LOST</option>
                    </select>

                    <label>Decision Reason (Mandatory)</label>
                    <textarea name="reason" placeholder="Why is this asset status being changed?" required></textarea>

                    <button>Update Asset Status</button>
                </form>

            </div>
        </div>

    </body>
</html>
