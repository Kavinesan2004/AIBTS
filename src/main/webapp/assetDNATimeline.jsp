<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String assetFilter = request.getParameter("asset_id");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Asset DNA Timeline | KN AIBTS</title>
        <meta charset="UTF-8">

        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;500;700&display=swap" rel="stylesheet">

        <style>
            :root{
                --bg:#050a10;
                --card:rgba(30,41,59,.4);
                --border:rgba(255,255,255,.08);
                --primary:#38bdf8;
                --text:#f1f5f9;
                --muted:#94a3b8;
            }

            *{
                box-sizing:border-box;
                margin:0;
                padding:0
            }

            body{
                font-family:'Inter',sans-serif;
                background:radial-gradient(circle at top left,#111827,#050a10 80%);
                color:var(--text);
                display:flex;
                min-height:100vh;
            }

            .sidebar{
                width:260px;
                background:rgba(15,23,42,.8);
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

            .sidebar a{
                display:block;
                padding:12px 16px;
                color:var(--muted);
                text-decoration:none;
                border-radius:8px;
                margin-bottom:8px;
            }

            .sidebar a:hover,.active{
                background:rgba(56,189,248,.1);
                color:var(--primary);
            }

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
                margin-bottom:30px;
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

            th{
                padding:14px;
                font-size:12px;
                color:var(--muted);
                text-transform:uppercase;
                border-bottom:1px solid var(--border);
                text-align:left;
            }

            td{
                padding:14px;
                border-bottom:1px solid rgba(255,255,255,.04);
                font-family:monospace;
            }

            tr:hover td{
                background:rgba(255,255,255,.03);
            }

            .event{
                font-family:'Inter',sans-serif;
                font-weight:600;
                color:var(--primary);
            }

            .filter{
                margin-bottom:20px;
            }

            input{
                padding:10px;
                width:200px;
                border-radius:8px;
                border:1px solid var(--border);
                background:#020617;
                color:white;
            }

            button{
                padding:10px 16px;
                border:none;
                border-radius:8px;
                margin-left:8px;
                background:var(--primary);
                color:black;
                font-weight:600;
                cursor:pointer;
            }
        </style>
    </head>

    <body>

        <!-- SIDEBAR -->
        <div class="sidebar">
            <div class="brand">KN AIBTS</div>
            <a href="assetDashboard.jsp">📊 Dashboard</a>
            <a href="trustScore.jsp">🛡 Trust Score</a>
            <a href="assetDNATimeline.jsp" class="active">🧬 Asset DNA</a
            <a href="logout.jsp">🚪 Logout</a>

        </div>

        <!-- MAIN -->
        <div class="main">
            <h1>Asset DNA Timeline</h1>
            <p class="subtitle">
                Immutable behavioral fingerprint of assets based on usage & events.
            </p>

            <!-- FILTER -->
            <div class="filter">
                <form method="get">
                    <input type="number" name="asset_id" placeholder="Filter by Asset ID"
                           value="<%= assetFilter != null ? assetFilter : ""%>">
                    <button>Filter</button>
                </form>
            </div>

            <div class="card">
                <table>
                    <thead>
                        <tr>
                            <th>Asset</th>
                            <th>DNA Hash</th>
                            <th>Trigger Event</th>
                            <th>Generated On</th>
                        </tr>
                    </thead>
                    <tbody>

                        <%
                            try {
                                String sql
                                        = "SELECT asset_id, dna_hash, trigger_event, generated_on "
                                        + "FROM asset_dna_history ";

                                if (assetFilter != null && !assetFilter.trim().isEmpty()) {
                                    sql += "WHERE asset_id=? ";
                                }

                                sql += "ORDER BY generated_on DESC";

                                PreparedStatement ps = conn.prepareStatement(sql);

                                if (assetFilter != null && !assetFilter.trim().isEmpty()) {
                                    ps.setInt(1, Integer.parseInt(assetFilter));
                                }

                                ResultSet rs = ps.executeQuery();

                                boolean hasData = false;

                                while (rs.next()) {
                                    hasData = true;
                        %>
                        <tr>
                            <td>#<%= rs.getInt("asset_id")%></td>
                            <td><%= rs.getString("dna_hash")%></td>
                            <td class="event"><%= rs.getString("trigger_event")%></td>
                            <td><%= rs.getTimestamp("generated_on")%></td>
                            <td>
                                <a href="assetDNADiff.jsp?asset_id=<%=rs.getInt("asset_id")%>"
                                   style="color:#38bdf8;text-decoration:none;font-weight:600">
                                    🔬 Analyze Diff
                                </a>
                            </td>

                        </tr>
                        <%
                            }

                            if (!hasData) {
                        %>
                        <tr>
                            <td colspan="4" style="color:var(--muted);text-align:center">
                                No DNA records found
                            </td>
                        </tr>
                        <%
                            }
                        } catch (Exception e) {
                        %>
                        <tr>
                            <td colspan="4" style="color:red">
                                Error loading DNA timeline: <%= e.getMessage()%>
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
