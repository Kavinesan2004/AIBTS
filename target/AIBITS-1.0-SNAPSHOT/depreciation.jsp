<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Silent Depreciation | KN AIBTS</title>
        <meta charset="UTF-8">

        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;500;700&display=swap" rel="stylesheet">

        <style>
            :root {
                --bg-dark: #050a10;
                --sidebar-bg: rgba(15, 23, 42, 0.8);
                --primary: #38bdf8;
                --success: #10b981;
                --warning: #f59e0b;
                --danger: #ef4444;
                --text-main: #f1f5f9;
                --text-muted: #94a3b8;
                --border: rgba(255, 255, 255, 0.08);
                --card-bg: rgba(30, 41, 59, 0.4);
                --glass: blur(12px);
            }

            *{
                box-sizing:border-box;
                margin:0;
                padding:0;
            }

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

            .nav-links{
                display:flex;
                flex-direction:column;
                gap:8px;
            }
            .nav-item{
                padding:12px 16px;
                border-radius:8px;
                text-decoration:none;
                color:var(--text-muted);
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
                margin-bottom:30px;
            }

            /* TABLE SECTION */
            .table-section{
                background:var(--card-bg);
                backdrop-filter:blur(10px);
                border:1px solid var(--border);
                border-radius:16px;
                padding:25px;
                animation:fadeInUp .6s ease-out;
            }

            .section-title{
                font-family:'Outfit',sans-serif;
                font-size:18px;
                margin-bottom:20px;
                color:var(--primary);
            }

            table{
                width:100%;
                border-collapse:collapse;
            }

            th{
                padding:14px;
                font-size:12px;
                color:var(--text-muted);
                text-transform:uppercase;
                border-bottom:1px solid var(--border);
                text-align:left;
            }

            td{
                padding:14px;
                border-bottom:1px solid rgba(255,255,255,.03);
            }

            tr:hover td{
                background:rgba(255,255,255,.03);
            }

            .low{
                color:var(--success);
                font-weight:600;
            }
            .medium{
                color:var(--warning);
                font-weight:600;
            }
            .high{
                color:var(--danger);
                font-weight:700;
            }

            @keyframes fadeInUp{
                from{
                    opacity:0;
                    transform:translateY(20px)
                }
                to{
                    opacity:1;
                    transform:translateY(0)
                }
            }
        </style>
    </head>

    <body>

        <!-- SIDEBAR -->
        <div class="sidebar">
            <div class="brand">KN AIBTS</div>

            <div class="nav-links">
                <a href="assetDashboard.jsp" class="nav-item">📊 Dashboard</a>
                <a href="depreciation.jsp" class="nav-item active">📉 Silent Depreciation</a>
                <a href="trustScore.jsp" class="nav-item">🛡 Trust Score</a>
                <a href="ghostAssests.jsp" class="nav-item">👻 Ghost Assets</a>
            </div>

            <div class="user-profile">
                <div style="font-size:12px;color:var(--text-muted)">Logged in as</div>
                <div style="font-weight:600"><%=session.getAttribute("user")%></div>
                <div style="margin-top:5px;font-size:11px;background:var(--primary);display:inline-block;padding:2px 8px;border-radius:4px">
                    <%=session.getAttribute("role")%>
                </div>
                <div style="margin-top:10px">
                    <a href="logout.jsp" style="color:var(--danger);font-size:12px;text-decoration:none">Logout ➔</a>
                </div>
            </div>
        </div>

        <!-- MAIN -->
        <div class="main-content">

            <h1>Silent Depreciation Engine</h1>
            <p class="subtitle">
                Asset value degradation calculated from <b>real usage behavior</b>, not time.
            </p>

            <div class="table-section">
                <div class="section-title">Depreciation Intelligence</div>

                <table>
                    <thead>
                        <tr>
                            <th>Asset</th>
                            <th>Usage Hours</th>
                            <th>Idle Hours</th>
                            <th>Misuse Events</th>
                            <th>Depreciation Score</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                PreparedStatement ps = conn.prepareStatement(
                                        "SELECT d.asset_id, "
                                        + "d.usage_weight, d.idle_weight, d.misuse_weight, d.calculated_value "
                                        + "FROM depreciation_engine d "
                                        + "JOIN ( "
                                        + "   SELECT asset_id, MAX(calculated_on) latest "
                                        + "   FROM depreciation_engine GROUP BY asset_id "
                                        + ") x ON d.asset_id=x.asset_id AND d.calculated_on=x.latest"
                                );

                                ResultSet rs = ps.executeQuery();

                                while (rs.next()) {
                                    int assetId = rs.getInt("asset_id");
                                    double usageW = rs.getDouble("usage_weight");
                                    double idleW = rs.getDouble("idle_weight");
                                    double misuseW = rs.getDouble("misuse_weight");
                                    double dep = rs.getDouble("calculated_value");

                                    String cls = dep > 150 ? "high" : dep > 70 ? "medium" : "low";
                        %>
                        <tr>
                            <td style="font-family:monospace;color:var(--primary)">#<%=assetId%></td>
                            <td><%=String.format("%.2f", usageW / 0.6)%></td>
                            <td><%=String.format("%.2f", idleW / 0.2)%></td>
                            <td><%=String.format("%.0f", misuseW / 15)%></td>
                            <td class="<%=cls%>"><%=String.format("%.2f", dep)%></td>
                        </tr>
                        <%
                                }
                            } catch (Exception e) {
                                out.println("<tr><td colspan='5'>Error loading depreciation data</td></tr>");
                            }
                        %>
                    </tbody>

                </table>
            </div>

        </div>

    </body>
</html>
