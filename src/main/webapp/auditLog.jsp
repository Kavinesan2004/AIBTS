<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>
<%@ include file="authGuard.jsp" %>


<%
    if (session.getAttribute("user") == null ||
       (!"AUDITOR".equals(session.getAttribute("role")) &&
        !"ADMIN".equals(session.getAttribute("role")))) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Audit & Intelligence Console | KN AIBTS</title>
    <meta charset="UTF-8">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;500;700&display=swap" rel="stylesheet">

    <style>
        :root{
            --bg-dark:#050a10;
            --sidebar-bg:rgba(15,23,42,.8);
            --primary:#38bdf8;
            --accent:#6366f1;
            --danger:#ef4444;
            --text-main:#f1f5f9;
            --text-muted:#94a3b8;
            --border:rgba(255,255,255,.08);
            --card-bg:rgba(30,41,59,.4);
            --glass:blur(12px);
        }

        *{margin:0;padding:0;box-sizing:border-box}

        body{
            font-family:'Inter',sans-serif;
            background:radial-gradient(circle at top left,#111827,#050a10 80%);
            color:var(--text-main);
            display:flex;
            min-height:100vh;
        }

        /* ===== SIDEBAR ===== */
        .sidebar{
            width:260px;
            background:var(--sidebar-bg);
            backdrop-filter:var(--glass);
            border-right:1px solid var(--border);
            padding:30px 20px;
            position:fixed;
            height:100vh;
        }

        .brand{
            font-family:'Outfit',sans-serif;
            font-size:24px;
            font-weight:700;
            margin-bottom:40px;
            background:linear-gradient(90deg,#fff,var(--primary));
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
        }

        .nav-links{display:flex;flex-direction:column;gap:8px}

        .nav-item{
            padding:12px 16px;
            border-radius:8px;
            color:var(--text-muted);
            text-decoration:none;
            transition:.3s;
        }

        .nav-item:hover,.nav-item.active{
            background:rgba(56,189,248,.1);
            color:var(--primary);
            border:1px solid rgba(56,189,248,.2);
        }

        .user-profile{
            margin-top:auto;
            padding:15px;
            border-radius:12px;
            border:1px solid var(--border);
            background:rgba(255,255,255,.03);
        }

        /* ===== MAIN ===== */
        .main-content{
            margin-left:260px;
            padding:40px;
            width:calc(100% - 260px);
        }

        h1{
            font-family:'Outfit',sans-serif;
            font-size:28px;
            font-weight:500;
            margin-bottom:10px;
        }

        .subtitle{
            color:var(--text-muted);
            margin-bottom:35px;
            max-width:800px;
        }

        /* ===== CARD ===== */
        .card{
            background:var(--card-bg);
            border:1px solid var(--border);
            border-radius:16px;
            padding:25px;
            margin-bottom:35px;
            animation:fadeInUp .5s ease-out;
        }

        .card h3{
            font-family:'Outfit',sans-serif;
            font-size:18px;
            margin-bottom:10px;
            color:var(--primary);
        }

        .card p{
            font-size:13px;
            color:var(--text-muted);
            margin-bottom:15px;
        }

        /* ===== TABLE ===== */
        table{
            width:100%;
            border-collapse:collapse;
            font-size:13px;
        }

        th{
            text-align:left;
            padding:14px;
            color:var(--text-muted);
            border-bottom:1px solid var(--border);
            text-transform:uppercase;
            font-size:11px;
            letter-spacing:1px;
        }

        td{
            padding:14px;
            border-bottom:1px solid rgba(255,255,255,.05);
        }

        tr:hover td{
            background:rgba(255,255,255,.03);
        }

        .badge{
            padding:4px 10px;
            border-radius:12px;
            font-size:11px;
            background:rgba(255,255,255,.08);
        }

        .danger{color:var(--danger)}
        .ok{color:#22c55e}

        @keyframes fadeInUp{
            from{opacity:0;transform:translateY(15px)}
            to{opacity:1;transform:translateY(0)}
        }
    </style>
</head>

<body>

<!-- ===== SIDEBAR ===== -->
<div class="sidebar">
    <div class="brand">KN AIBTS</div>

    <div class="nav-links">
        <a href="auditLog.jsp" class="nav-item active">🛡 Audit Console</a>
    </div>

    <div class="user-profile">
        <div style="font-size:12px;color:var(--text-muted)">Logged in as</div>
        <div style="font-weight:600"><%=session.getAttribute("user")%></div>
        <div style="margin-top:5px;font-size:11px;background:var(--accent);display:inline-block;padding:2px 8px;border-radius:4px">
            <%=session.getAttribute("role")%>
        </div>
        <div style="margin-top:10px">
            <a href="logout.jsp" style="color:var(--danger);font-size:12px;text-decoration:none">Logout ➔</a>
        </div>
    </div>
</div>

<!-- ===== MAIN ===== -->
<div class="main-content">

    <h1>Audit & Intelligence Console</h1>
    <p class="subtitle">
        Read-only command center providing <b>forensic transparency</b> across
        assets, users, decisions, behavior, trust evolution, and depreciation.
    </p>

    <!-- ================= DECISION AUDIT LOG ================= -->
    <div class="card">
        <h3>Decision Audit Log</h3>
        <table>
            <tr><th>Asset</th><th>Action</th><th>Reason</th><th>Timestamp</th></tr>
            <%
                ResultSet rs = conn.createStatement().executeQuery(
                    "SELECT asset_id,action_type,reason,performed_on FROM decision_audit_log ORDER BY performed_on DESC");
                while(rs.next()){
            %>
            <tr>
                <td>#<%=rs.getInt(1)%></td>
                <td><%=rs.getString(2)%></td>
                <td><%=rs.getString(3)%></td>
                <td><%=rs.getTimestamp(4)%></td>
            </tr>
            <% } %>
        </table>
    </div>

    <!-- ================= ASSETS ================= -->
    <div class="card">
        <h3>Asset Registry Snapshot</h3>
        <table>
            <tr><th>ID</th><th>Category</th><th>Status</th><th>Trust</th></tr>
            <%
                ResultSet a = conn.createStatement().executeQuery(
                    "SELECT asset_id,category,status,current_trust_score FROM asset_core");
                while(a.next()){
            %>
            <tr>
                <td>#<%=a.getInt(1)%></td>
                <td><%=a.getString(2)%></td>
                <td><span class="badge"><%=a.getString(3)%></span></td>
                <td class="<%=a.getInt(4)<50?"danger":"ok"%>"><%=a.getInt(4)%></td>
            </tr>
            <% } %>
        </table>
    </div>

    <!-- ================= ASSIGNMENTS ================= -->
    <div class="card">
        <h3>Assignment Chain Memory</h3>
        <table>
            <tr><th>Asset</th><th>User</th><th>Purpose</th><th>Date</th></tr>
            <%
                ResultSet as = conn.createStatement().executeQuery(
                    "SELECT a.asset_id,u.username,a.purpose,a.assigned_on " +
                    "FROM assignment_chain a JOIN users u ON a.user_id=u.user_id ORDER BY a.assigned_on DESC");
                while(as.next()){
            %>
            <tr>
                <td>#<%=as.getInt(1)%></td>
                <td><%=as.getString(2)%></td>
                <td><%=as.getString(3)%></td>
                <td><%=as.getTimestamp(4)%></td>
            </tr>
            <% } %>
        </table>
    </div>

    <!-- ================= USAGE ================= -->
    <div class="card">
        <h3>Usage Logs</h3>
        <table>
            <tr><th>Asset</th><th>User</th><th>Usage</th><th>Idle</th><th>Misuse</th></tr>
            <%
                ResultSet u = conn.createStatement().executeQuery(
                    "SELECT l.asset_id,us.username,l.usage_hours,l.idle_hours,l.misuse_flag " +
                    "FROM asset_usage_log l JOIN users us ON l.user_id=us.user_id");
                while(u.next()){
            %>
            <tr>
                <td>#<%=u.getInt(1)%></td>
                <td><%=u.getString(2)%></td>
                <td><%=u.getInt(3)%></td>
                <td><%=u.getInt(4)%></td>
                <td class="<%=u.getInt(5)==1?"danger":"ok"%>">
                    <%=u.getInt(5)==1?"YES":"NO"%>
                </td>
            </tr>
            <% } %>
        </table>
    </div>

</div>

</body>
</html>
