<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    /* Redirect if already logged in */
    if (session.getAttribute("user") != null) {
        response.sendRedirect("assetDashboard.jsp");
        return;
    }

    String error = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT user_id, username, role, status " +
                "FROM users WHERE username=? AND password_hash=?");

            ps.setString(1, username);
            ps.setString(2, password);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {

                if (!"ACTIVE".equals(rs.getString("status"))) {
                    error = "Your account has been disabled by administrator.";
                } else {

                    session.setAttribute("user", rs.getString("username"));
                    session.setAttribute("user_id", rs.getInt("user_id"));
                    session.setAttribute("role", rs.getString("role"));

                    String role = rs.getString("role");

                    if ("ADMIN".equals(role)) {
                        response.sendRedirect("assetDashboard.jsp");
                    } else if ("USER".equals(role)) {
                        response.sendRedirect("logUsage.jsp");
                    } else if ("AUDITOR".equals(role)) {
                        response.sendRedirect("auditLog.jsp");
                    } else {
                        error = "Unauthorized role.";
                    }
                    return;
                }

            } else {
                error = "Invalid username or password.";
            }

        } catch (Exception e) {
            error = "System error. Please try again.";
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Secure Login | KN AIBTS</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@400;600;700&display=swap" rel="stylesheet">

    <style>
        :root{
            --bg:#050a10;
            --card:rgba(15,23,42,.75);
            --primary:#38bdf8;
            --accent:#6366f1;
            --text:#f1f5f9;
            --muted:#94a3b8;
            --border:rgba(255,255,255,.08);
            --error:#ef4444;
        }

        *{box-sizing:border-box;margin:0;padding:0}

        body{
            font-family:Inter,sans-serif;
            background:
                radial-gradient(circle at top right,#1e293b,#050a10 65%);
            min-height:100vh;
            display:flex;
            align-items:center;
            justify-content:center;
            padding:20px;
            color:var(--text);
            position:relative;
        }

        /* HEADER */
        .top-bar{
            position:absolute;
            top:20px;
            right:20px;
        }

        .home-btn{
            text-decoration:none;
            padding:10px 18px;
            border-radius:30px;
            font-size:13px;
            font-weight:600;
            color:var(--text);
            border:1px solid var(--border);
            background:rgba(255,255,255,.04);
            transition:.3s;
        }

        .home-btn:hover{
            background:rgba(56,189,248,.15);
            border-color:var(--primary);
            color:var(--primary);
        }

        /* LOGIN CARD */
        .login-wrapper{
            width:100%;
            max-width:420px;
            animation:fadeUp .6s ease-out;
        }

        .login-card{
            background:var(--card);
            backdrop-filter:blur(14px);
            border:1px solid var(--border);
            border-radius:18px;
            padding:45px 40px;
            box-shadow:0 25px 50px rgba(0,0,0,.55);
            text-align:center;
        }

        .brand{
            font-family:Outfit,sans-serif;
            font-size:26px;
            font-weight:700;
            background:linear-gradient(90deg,#fff,var(--primary));
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
            margin-bottom:8px;
        }

        .subtitle{
            color:var(--muted);
            font-size:14px;
            margin-bottom:35px;
        }

        form{
            display:flex;
            flex-direction:column;
            gap:18px;
        }

        input{
            width:100%;
            padding:14px 16px;
            background:#020617;
            border:1px solid var(--border);
            border-radius:10px;
            color:white;
            font-size:15px;
            transition:.3s;
        }

        input:focus{
            outline:none;
            border-color:var(--primary);
            box-shadow:0 0 0 2px rgba(56,189,248,.25);
        }

        button{
            margin-top:10px;
            padding:14px;
            background:linear-gradient(90deg,var(--accent),var(--primary));
            border:none;
            border-radius:10px;
            color:white;
            font-weight:600;
            font-size:15px;
            cursor:pointer;
            transition:.3s;
        }

        button:hover{
            transform:translateY(-2px);
            box-shadow:0 10px 25px rgba(99,102,241,.35);
        }

        .error{
            margin-top:20px;
            padding:12px 14px;
            background:rgba(239,68,68,.15);
            border:1px solid rgba(239,68,68,.3);
            border-radius:10px;
            color:#fecaca;
            font-size:13px;
            animation:shake .3s ease-in-out;
        }

        .footer{
            margin-top:22px;
            font-size:12px;
            color:var(--muted);
        }

        @keyframes fadeUp{
            from{opacity:0;transform:translateY(20px)}
            to{opacity:1;transform:translateY(0)}
        }

        @keyframes shake{
            0%{transform:translateX(0)}
            25%{transform:translateX(-4px)}
            50%{transform:translateX(4px)}
            75%{transform:translateX(-4px)}
            100%{transform:translateX(0)}
        }

        @media(max-width:480px){
            .login-card{padding:35px 28px}
        }
    </style>
</head>

<body>

<!-- TOP BAR -->
<div class="top-bar">
    <a href="index.html" class="home-btn">← Back to Home</a>
</div>

<div class="login-wrapper">
    <div class="login-card">

        <div class="brand">KN AIBTS</div>
        <div class="subtitle">Secure Access Portal</div>

        <form method="post">
            <input type="text" name="username" placeholder="Username" required autocomplete="off">
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit">Login</button>
        </form>

        <% if(!error.isEmpty()){ %>
            <div class="error">⚠ <%= error %></div>
        <% } %>

        <div class="footer">
            © <%= java.time.Year.now() %> KN AIBTS • Asset Intelligence Platform
        </div>

    </div>
</div>

</body>
</html>
