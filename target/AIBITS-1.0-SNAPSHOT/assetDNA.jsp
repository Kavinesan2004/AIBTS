<%@ page import="java.sql.*" %>
<%@ page import="java.security.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String dnaResult = "";
    String error = "";
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Asset DNA Engine | KN AIBTS</title>
    <meta charset="UTF-8">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;500;700&display=swap" rel="stylesheet">

    <style>
        :root{
            --bg-dark:#050a10;
            --sidebar-bg:rgba(15,23,42,.8);
            --primary:#38bdf8;
            --danger:#ef4444;
            --text-main:#f1f5f9;
            --text-muted:#94a3b8;
            --border:rgba(255,255,255,.08);
            --card-bg:rgba(30,41,59,.4);
            --glass:blur(12px);
        }

        *{margin:0;padding:0;box-sizing:border-box;}

        body{
            font-family:'Inter',sans-serif;
            background:radial-gradient(circle at top left,#111827,#050a10 80%);
            color:var(--text-main);
            display:flex;
            min-height:100vh;
        }

        /* SIDEBAR */
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

        .nav-item{
            display:block;
            padding:12px 16px;
            border-radius:8px;
            color:var(--text-muted);
            text-decoration:none;
            margin-bottom:8px;
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

        /* MAIN */
        .main-content{
            margin-left:260px;
            padding:40px;
            width:calc(100% - 260px);
        }

        h1{
            font-family:'Outfit',sans-serif;
            font-weight:500;
            margin-bottom:10px;
        }

        .subtitle{
            color:var(--text-muted);
            max-width:800px;
            margin-bottom:30px;
        }

        .card{
            background:var(--card-bg);
            border:1px solid var(--border);
            border-radius:16px;
            padding:30px;
            max-width:700px;
            animation:fadeInUp .6s ease-out;
        }

        label{
            font-size:13px;
            color:var(--text-muted);
            margin-top:15px;
            display:block;
        }

        input{
            width:100%;
            padding:12px;
            margin-top:8px;
            background:rgba(255,255,255,.05);
            border:1px solid var(--border);
            border-radius:8px;
            color:white;
        }

        button{
            margin-top:25px;
            padding:14px;
            width:100%;
            background:var(--primary);
            border:none;
            border-radius:10px;
            font-weight:600;
            cursor:pointer;
        }

        button:hover{
            box-shadow:0 0 20px rgba(56,189,248,.4);
        }

        .dna-box{
            margin-top:25px;
            padding:18px;
            background:rgba(0,0,0,.4);
            border-radius:10px;
            font-family:monospace;
            font-size:13px;
            word-break:break-all;
            border:1px dashed rgba(56,189,248,.3);
        }

        .error{
            color:var(--danger);
            margin-top:20px;
        }

        @keyframes fadeInUp{
            from{opacity:0;transform:translateY(20px)}
            to{opacity:1;transform:translateY(0)}
        }
    </style>
</head>

<body>

<!-- SIDEBAR -->
<div class="sidebar">
    <div class="brand">KN AIBTS</div>

    <a href="assetDashboard.jsp" class="nav-item">Dashboard</a>
    <a href="assetDNA.jsp" class="nav-item active">Asset DNA</a>
    <a href="assetDNATimeline.jsp" class="nav-item ">DNA Timeline</a>

    <a href="trustScore.jsp" class="nav-item"> Trust Score</a>
    <a href="depreciation.jsp" class="nav-item"> Depreciation</a>

    <div class="user-profile">
        <div style="font-size:12px;color:var(--text-muted)">Logged in as</div>
        <div style="font-weight:600"><%=session.getAttribute("user")%></div>
        <div style="margin-top:10px">
            <a href="logout.jsp" style="color:var(--danger);font-size:12px;text-decoration:none">Logout ➔</a>
        </div>
    </div>
</div>

<!-- MAIN -->
<div class="main-content">

    <h1>Asset DNA Engine</h1>
    <p class="subtitle">
        Asset DNA is a cryptographic fingerprint derived from
        <b>usage behavior, misuse patterns, and operational history</b>.
        Any change mutates the DNA.
    </p>

    <div class="card">

        <form method="post">
            <label>Asset ID</label>
            <input type="number" name="aid" required>
            <button type="submit">Generate Asset DNA</button>
        </form>

        <%
            if ("POST".equalsIgnoreCase(request.getMethod())) {
                try {
                    int assetId = Integer.parseInt(request.getParameter("aid"));

                    PreparedStatement ps = conn.prepareStatement(
                        "SELECT purchase_source FROM asset_core WHERE asset_id=?");
                    ps.setInt(1, assetId);
                    ResultSet rs = ps.executeQuery();

                    if (!rs.next()) {
                        error = "Asset not found";
                    } else {

                        String purchaseSource = rs.getString("purchase_source");

                        PreparedStatement ps2 = conn.prepareStatement(
                            "SELECT SUM(usage_hours), " +
                            "SUM(CASE WHEN misuse_flag=1 THEN 1 ELSE 0 END) " +
                            "FROM asset_usage_log WHERE asset_id=?");
                        ps2.setInt(1, assetId);
                        ResultSet rs2 = ps2.executeQuery();

                        int usage = 0, misuse = 0;
                        if (rs2.next()) {
                            usage = rs2.getInt(1);
                            misuse = rs2.getInt(2);
                        }

                        String dnaSource = assetId+"|"+purchaseSource+"|"+usage+"|"+misuse;

                        MessageDigest md = MessageDigest.getInstance("SHA-256");
                        byte[] hash = md.digest(dnaSource.getBytes("UTF-8"));

                        StringBuilder dna = new StringBuilder();
                        for (byte b : hash) dna.append(String.format("%02x", b));

                        PreparedStatement ins = conn.prepareStatement(
                            "INSERT INTO asset_dna_history(asset_id,dna_hash,trigger_event) VALUES(?,?,?)");
                        ins.setInt(1, assetId);
                        ins.setString(2, dna.toString());
                        ins.setString(3, "MANUAL_GENERATION");
                        ins.executeUpdate();

                        dnaResult = dna.toString();
                    }
                } catch (Exception e) {
                    error = e.getMessage();
                }
            }
        %>

        <% if(!dnaResult.isEmpty()){ %>
            <div class="dna-box"><%= dnaResult %></div>
        <% } %>

        <% if(!error.isEmpty()){ %>
            <div class="error"><%= error %></div>
        <% } %>

    </div>

</div>

</body>
</html>
