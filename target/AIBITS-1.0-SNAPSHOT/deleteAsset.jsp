<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    /* ADMIN CHECK */
    if (session.getAttribute("user") == null ||
        !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect("viewAssets.jsp");
        return;
    }

    int assetId = Integer.parseInt(request.getParameter("id"));
    int adminId = (Integer) session.getAttribute("user_id");

    if ("POST".equalsIgnoreCase(request.getMethod())) {

        String reason = request.getParameter("reason");

        /* ===== SOFT DELETE ASSET ===== */
        PreparedStatement up = conn.prepareStatement(
            "UPDATE asset_core SET " +
            "status='DELETED', " +
            "deleted_flag=1, " +
            "deleted_on=NOW(), " +
            "deleted_reason=?, " +
            "current_trust_score=0 " +
            "WHERE asset_id=?");
        up.setString(1, reason);
        up.setInt(2, assetId);
        up.executeUpdate();

        /* ===== AUDIT LOG ===== */
        PreparedStatement audit = conn.prepareStatement(
            "INSERT INTO decision_audit_log " +
            "(asset_id, action_type, reason, performed_by) " +
            "VALUES (?,?,?,?)");
        audit.setInt(1, assetId);
        audit.setString(2, "ASSET_DELETED");
        audit.setString(3, reason);
        audit.setInt(4, adminId);
        audit.executeUpdate();

        response.sendRedirect("viewAssets.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Delete Asset | KN AIBTS</title>
    <meta charset="UTF-8">

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@400;600&display=swap" rel="stylesheet">

    <style>
        :root{
            --bg-dark:#050a10;
            --danger:#ef4444;
            --danger-soft:rgba(239,68,68,.15);
            --text-main:#f1f5f9;
            --text-muted:#94a3b8;
            --border:rgba(255,255,255,.08);
            --card-bg:rgba(30,41,59,.5);
        }

        *{margin:0;padding:0;box-sizing:border-box}

        body{
            font-family:'Inter',sans-serif;
            background:radial-gradient(circle at top left,#111827,#050a10 80%);
            color:var(--text-main);
            display:flex;
            min-height:100vh;
        }

        .sidebar{
            width:260px;
            background:rgba(15,23,42,.85);
            border-right:1px solid var(--border);
            padding:30px 20px;
            position:fixed;
            height:100vh;
        }

        .sidebar a{
            display:block;
            padding:12px 16px;
            border-radius:8px;
            text-decoration:none;
            color:var(--text-muted);
            margin-bottom:8px;
        }

        .sidebar a:hover{
            background:var(--danger-soft);
            color:var(--danger);
        }

        .main{
            margin-left:260px;
            padding:60px;
            width:calc(100% - 260px);
        }

        .card{
            background:var(--card-bg);
            border:1px solid rgba(239,68,68,.3);
            border-left:6px solid var(--danger);
            border-radius:16px;
            padding:35px;
            max-width:540px;
        }

        h1{
            font-family:'Outfit',sans-serif;
            color:var(--danger);
            margin-bottom:12px;
        }

        .warning{
            background:var(--danger-soft);
            padding:14px;
            border-radius:10px;
            margin-bottom:25px;
            font-size:14px;
            border:1px solid rgba(239,68,68,.3);
        }

        .meta{
            font-size:13px;
            color:var(--text-muted);
            margin-bottom:25px;
        }

        textarea{
            width:100%;
            height:80px;
            padding:12px;
            background:#020617;
            border:1px solid rgba(239,68,68,.4);
            border-radius:10px;
            color:white;
        }

        button{
            margin-top:25px;
            width:100%;
            padding:15px;
            background:linear-gradient(90deg,#ef4444,#dc2626);
            border:none;
            border-radius:12px;
            font-weight:600;
            color:white;
            cursor:pointer;
        }

        .cancel{
            margin-top:15px;
            text-align:center;
        }

        .cancel a{
            color:var(--text-muted);
            font-size:13px;
            text-decoration:none;
        }
    </style>
</head>

<body>

<div class="sidebar">
    <a href="assetDashboard.jsp">📊 Dashboard</a>
    <a href="viewAssets.jsp">📦 Asset Inventory</a>
    <a href="logout.jsp" style="color:#ef4444">Logout</a>
</div>

<div class="main">
    <div class="card">

        <h1>Delete Asset</h1>

        <div class="warning">
            ⚠️ This will permanently remove the asset from all operations.  
            Usage, DNA, depreciation & audit history will be preserved.
        </div>

        <div class="meta">
            <b>Asset ID:</b> #<%=assetId%><br>
            <b>Deleted By:</b> <%=session.getAttribute("user")%>
        </div>

        <form method="post">
            <textarea name="reason" placeholder="Reason for deleting this asset (mandatory)" required></textarea>
            <button>Confirm Asset Deletion</button>
        </form>

        <div class="cancel">
            <a href="viewAssets.jsp">← Cancel</a>
        </div>

    </div>
</div>

</body>
</html>
