<%@ page import="java.sql.*" %>
<%@ include file="db.jsp" %>

<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String assetParam = request.getParameter("asset_id");
    Integer assetId = null;

    try {
        if (assetParam != null && !assetParam.trim().isEmpty()) {
            assetId = Integer.parseInt(assetParam);
        }
    } catch (Exception e) {
        assetId = null;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>DNA Diff Analyzer | KN AIBTS</title>
    <meta charset="UTF-8">

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;600&display=swap" rel="stylesheet">

    <style>
        :root{
            --bg:#050a10;
            --card:rgba(30,41,59,.4);
            --border:rgba(255,255,255,.08);
            --primary:#38bdf8;
            --text:#f1f5f9;
            --muted:#94a3b8;
            --good:#10b981;
            --warn:#f59e0b;
            --bad:#ef4444;
        }

        *{box-sizing:border-box;margin:0;padding:0}

        body{
            font-family:'Inter',sans-serif;
            background:radial-gradient(circle at top left,#111827,#050a10 80%);
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
            border-right:1px solid var(--border);
        }

        .brand{
            font-family:'Outfit',sans-serif;
            font-size:24px;
            font-weight:600;
            margin-bottom:40px;
            background:linear-gradient(90deg,#fff,var(--primary));
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
        }

        .sidebar a{
            display:block;
            padding:12px 16px;
            border-radius:8px;
            text-decoration:none;
            color:var(--muted);
            margin-bottom:8px;
        }

        .sidebar a:hover,
        .sidebar a.active{
            background:rgba(56,189,248,.1);
            color:var(--primary);
        }

        /* ===== MAIN ===== */
        .main{
            margin-left:260px;
            padding:40px;
            width:calc(100% - 260px);
        }

        h1{
            font-family:'Outfit',sans-serif;
            margin-bottom:10px;
        }

        .subtitle{
            color:var(--muted);
            margin-bottom:25px;
        }

        .card{
            background:var(--card);
            border:1px solid var(--border);
            border-radius:16px;
            padding:25px;
        }

        table{
            width:100%;
            border-collapse:collapse;
        }

        th,td{
            padding:14px;
            border-bottom:1px solid rgba(255,255,255,.08);
            text-align:left;
        }

        th{
            font-size:12px;
            color:var(--muted);
            text-transform:uppercase;
        }

        .hash{
            font-family:monospace;
            font-size:11px;
            word-break:break-all;
        }

        .safe{color:var(--good);font-weight:700}
        .warn{color:var(--warn);font-weight:700}
        .risk{color:var(--bad);font-weight:800}

        .error{
            color:var(--bad);
            background:rgba(239,68,68,.15);
            padding:15px;
            border-radius:10px;
            border:1px solid rgba(239,68,68,.3);
            max-width:600px;
        }
    </style>
</head>

<body>

<!-- ===== SIDEBAR ===== -->
<div class="sidebar">
    <div class="brand">KN AIBTS</div>

    <a href="assetDashboard.jsp">Dashboard</a>
    <a href="trustScore.jsp"> Trust Score</a>
    <a href="assetDNATimeline.jsp"> Asset DNA Timeline</a>
    <a href="assetDNADiff.jsp?asset_id=<%= assetId != null ? assetId : "" %>" class="active">
         DNA Diff Analyzer
    </a>
    <a href="logout.jsp">Logout</a>
</div>

<!-- ===== MAIN ===== -->
<div class="main">

    <h1>DNA Diff Analyzer</h1>
    <p class="subtitle">
        Compares <b>DNA mutations over time</b> and detects behavioral risk patterns.
    </p>

<% if (assetId == null) { %>

    <div class="error">
        ? <b>No Asset Selected</b><br><br>
        Open this page from <b>Asset DNA Timeline</b><br>
        or use:<br>
        <code>?asset_id=12</code>
    </div>

<% } else { %>

    <p>Analyzing Asset ID: <b>#<%=assetId%></b></p>

    <div class="card">
        <table>
            <thead>
                <tr>
                    <th>Version</th>
                    <th>Trigger Event</th>
                    <th>DNA Hash</th>
                    <th>Generated On</th>
                    <th>Risk Level</th>
                </tr>
            </thead>
            <tbody>

<%
    PreparedStatement ps = conn.prepareStatement(
        "SELECT dna_hash, trigger_event, generated_on " +
        "FROM asset_dna_history WHERE asset_id=? ORDER BY generated_on ASC");
    ps.setInt(1, assetId);
    ResultSet rs = ps.executeQuery();

    Timestamp prevTime = null;
    int version = 1;

    while(rs.next()){
        String hash = rs.getString("dna_hash");
        String event = rs.getString("trigger_event");
        Timestamp time = rs.getTimestamp("generated_on");

        String risk = "SAFE";
        String cls = "safe";

        if(prevTime != null){
            long diffMin = (time.getTime() - prevTime.getTime()) / (1000 * 60);

            if(event.contains("MISUSE") || event.contains("LOCK")){
                risk = "HIGH RISK";
                cls = "risk";
            } else if(diffMin < 30){
                risk = "WARNING (Rapid Mutation)";
                cls = "warn";
            }
        }
%>
                <tr>
                    <td>DNA-<%=version++%></td>
                    <td><%=event%></td>
                    <td class="hash"><%=hash%></td>
                    <td><%=time%></td>
                    <td class="<%=cls%>"><%=risk%></td>
                </tr>
<%
        prevTime = time;
    }
%>

            </tbody>
        </table>
    </div>

<% } %>

</div>

</body>
</html>
