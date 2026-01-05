<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    /* AUTH + ROLE CHECK */
    if (session.getAttribute("user") == null ||
        !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String message = "";

    /* CREATE USER */
    if ("POST".equalsIgnoreCase(request.getMethod()) &&
        request.getParameter("create") != null) {

        try {
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO users(username,password_hash,role,status) VALUES(?,?,?, 'ACTIVE')");
            ps.setString(1, request.getParameter("username"));
            ps.setString(2, request.getParameter("password")); // hash later
            ps.setString(3, request.getParameter("role"));
            ps.executeUpdate();

            message = "User created successfully";

        } catch (Exception e) {
            message = "Error: " + e.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>User Management | KN AIBTS</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@400;600;700&display=swap" rel="stylesheet">

    <style>
        :root{
            --primary:#38bdf8;
            --success:#10b981;
            --danger:#ef4444;
            --text:#f1f5f9;
            --muted:#94a3b8;
            --border:rgba(255,255,255,.08);
            --card:rgba(30,41,59,.45);
            --bg:#050a10;
        }

        *{box-sizing:border-box;margin:0;padding:0}

        body{
            font-family:Inter,sans-serif;
            background:radial-gradient(circle at top left,#111827,var(--bg) 80%);
            color:var(--text);
            display:flex;
            min-height:100vh;
        }

        /* ===== SIDEBAR ===== */
        .sidebar{
            width:260px;
            background:rgba(15,23,42,.85);
            padding:30px 20px;
            position:fixed;
            height:100vh;
        }

        .brand{
            font-family:Outfit,sans-serif;
            font-size:24px;
            font-weight:700;
            margin-bottom:40px;
            background:linear-gradient(90deg,#fff,var(--primary));
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
        }

        .sidebar a{
            display:block;
            padding:12px 16px;
            color:var(--muted);
            text-decoration:none;
            border-radius:8px;
            margin-bottom:8px;
        }

        .sidebar a.active,.sidebar a:hover{
            background:rgba(56,189,248,.12);
            color:var(--primary);
        }

        /* ===== MAIN ===== */
        .main{
            margin-left:260px;
            padding:40px;
            width:100%;
        }

        h1{
            font-family:Outfit,sans-serif;
            margin-bottom:10px;
        }

        .msg{
            margin-bottom:20px;
            color:var(--success);
        }
        .error{color:var(--danger)}

        /* ===== CARDS ===== */
        .card{
            background:var(--card);
            border:1px solid var(--border);
            border-radius:16px;
            padding:30px;
            max-width:520px;
            margin-bottom:40px;
        }

        label{
            font-size:13px;
            color:var(--muted);
            margin-top:15px;
            display:block;
        }

        input,select{
            width:100%;
            padding:12px;
            margin-top:8px;
            background:rgba(255,255,255,.05);
            border:1px solid var(--border);
            border-radius:8px;
            color:white;
        }

        button{
            width:100%;
            padding:14px;
            margin-top:25px;
            background:var(--primary);
            border:none;
            border-radius:10px;
            font-weight:600;
            cursor:pointer;
            color:#020617;
        }

        /* ===== TABLE ===== */
        .table-card{
            background:var(--card);
            border:1px solid var(--border);
            border-radius:16px;
            padding:25px;
            overflow-x:auto;
        }

        table{
            width:100%;
            border-collapse:collapse;
            min-width:600px;
        }

        th,td{
            padding:14px;
            border-bottom:1px solid rgba(255,255,255,.06);
            text-align:left;
        }

        th{
            font-size:12px;
            color:var(--muted);
            text-transform:uppercase;
        }

        tr:hover td{
            background:rgba(255,255,255,.03);
        }

        .status-active{color:var(--success);font-weight:700}
        .status-disabled{color:var(--danger);font-weight:700}

        .action a{
            padding:6px 14px;
            border-radius:20px;
            font-size:12px;
            text-decoration:none;
            font-weight:600;
        }

        .disable{background:rgba(239,68,68,.15);color:var(--danger)}
        .enable{background:rgba(16,185,129,.15);color:var(--success)}

        /* ===== RESPONSIVE ===== */
        @media(max-width:900px){
            .sidebar{display:none}
            .main{margin-left:0}
        }
    </style>
</head>

<body>

<!-- SIDEBAR -->
<div class="sidebar">
    <div class="brand">KN AIBTS</div>
    <a href="assetDashboard.jsp">📊 Dashboard</a>
    <a href="viewAssets.jsp">📦 Assets</a>
    <a href="register.jsp" class="active">👤 Users</a>
    <a href="auditLog.jsp">🛡 Audit Log</a>
    <a href="logout.jsp">🚪 Logout</a>
</div>

<div class="main">

    <h1>User Management</h1>

    <% if(!message.isEmpty()){ %>
        <div class="msg <%=message.startsWith("Error")?"error":""%>"><%=message%></div>
    <% } %>

    <!-- CREATE USER -->
    <div class="card">
        <h2>Create User</h2>
        <form method="post">
            <input type="hidden" name="create" value="1">

            <label>Username</label>
            <input name="username" required>

            <label>Password</label>
            <input type="password" name="password" required>

            <label>Role</label>
            <select name="role">
                <option>ADMIN</option>
                <option>USER</option>
                <option>AUDITOR</option>
            </select>

            <button>Create User</button>
        </form>
    </div>

    <!-- USER LIST -->
    <div class="table-card">
        <h2 style="margin-bottom:15px;font-family:Outfit">Registered Users</h2>

        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Username</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>

            <%
                Statement st = conn.createStatement();
                ResultSet rs = st.executeQuery(
                    "SELECT user_id, username, role, status FROM users ORDER BY user_id DESC");

                while(rs.next()){
                    int uid = rs.getInt("user_id");
                    String status = rs.getString("status");
            %>
                <tr>
                    <td>#<%=uid%></td>
                    <td><%=rs.getString("username")%></td>
                    <td><%=rs.getString("role")%></td>
                    <td class="<%= "ACTIVE".equals(status) ? "status-active" : "status-disabled"%>">
                        <%=status%>
                    </td>
                    <td class="action">
                        <a class="<%= "ACTIVE".equals(status) ? "disable" : "enable"%>"
                           href="toggleUser.jsp?user_id=<%=uid%>&status=<%= "ACTIVE".equals(status) ? "DISABLED" : "ACTIVE"%>">
                           <%= "ACTIVE".equals(status) ? "Disable" : "Enable"%>
                        </a>
                    </td>
                </tr>
            <%
                }
            %>

            </tbody>
        </table>
    </div>

</div>

</body>
</html>
