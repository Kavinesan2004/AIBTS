<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int totalAssets = 0;
    int highTrustAssets = 0;
    int atRiskAssets = 0;
    int ghostAssets = 0;

    try {
        Statement st = conn.createStatement();

        ResultSet rs1 = st.executeQuery("SELECT COUNT(*) FROM asset_core");
        if (rs1.next()) totalAssets = rs1.getInt(1);

        ResultSet rs2 = st.executeQuery(
            "SELECT COUNT(*) FROM asset_core WHERE current_trust_score >= 80");
        if (rs2.next()) highTrustAssets = rs2.getInt(1);

        ResultSet rs3 = st.executeQuery(
            "SELECT COUNT(*) FROM asset_core WHERE current_trust_score < 50");
        if (rs3.next()) atRiskAssets = rs3.getInt(1);

        ResultSet rs4 = st.executeQuery(
            "SELECT COUNT(*) FROM asset_core a " +
            "LEFT JOIN asset_usage_log u ON a.asset_id = u.asset_id " +
            "WHERE u.asset_id IS NULL");
        if (rs4.next()) ghostAssets = rs4.getInt(1);

    } catch (Exception e) {
        out.println("Home Dashboard Error: " + e.getMessage());
    }
%>

<!DOCTYPE html>
<html>
    <head>
        <title>Asset Intelligence Platform</title>

        <style>
            body{
                margin:0;
                font-family:"Segoe UI", Arial, sans-serif;
                background:#f4f6f8;
            }

            /* HEADER */
            .header{
                background:#0f1f2e;
                color:white;
                padding:15px 30px;
                display:flex;
                justify-content:space-between;
                align-items:center;
            }

            .header h1{
                font-size:20px;
                margin:0;
                letter-spacing:1px;
            }

            .header span{
                font-size:13px;
                color:#9bb3c8;
            }

            /* SIDEBAR */
            .sidebar{
                width:230px;
                background:#1b2f44;
                height:100vh;
                position:fixed;
                top:60px;
                left:0;
                padding-top:20px;
            }

            .sidebar a{
                display:block;
                color:#cfd8e3;
                padding:14px 25px;
                text-decoration:none;
                font-size:14px;
            }

            .sidebar a:hover{
                background:#2c4560;
                color:white;
            }

            /* MAIN */
            .main{
                margin-left:230px;
                padding:30px;
            }

            /* KPI CARDS */
            .cards{
                display:grid;
                grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
                gap:20px;
            }

            .card{
                background:white;
                padding:20px;
                border-radius:8px;
                box-shadow:0 4px 10px rgba(0,0,0,0.08);
            }

            .card h3{
                margin:0;
                font-size:14px;
                color:#666;
            }

            .card p{
                font-size:28px;
                margin:10px 0 0;
                color:#0f1f2e;
                font-weight:bold;
            }

            /* SECTION */
            .section{
                margin-top:35px;
                background:white;
                padding:25px;
                border-radius:8px;
                box-shadow:0 4px 10px rgba(0,0,0,0.08);
            }

            .section h2{
                margin-top:0;
                font-size:18px;
                color:#0f1f2e;
            }
        </style>
    </head>

    <body>

        <!-- HEADER -->
        <div class="header">
            <h1>KN AIBTS</h1>
            <span>
                User: <b><%=session.getAttribute("user")%></b> |
                Role: <b><%=session.getAttribute("role")%></b>
            </span>
        </div>

        <!-- SIDEBAR -->
        <div class="sidebar">
            <a href="assetDashboard.jsp">📊 Dashboard</a>
            <a href="assetDNA.jsp">🧬 Asset DNA</a>
            <a href="trustScore.jsp">🔐 Trust Scores</a>
            <a href="assignmentHistory.jsp">🔗 Assignment Memory</a>
            <a href="depreciation.jsp">📉 Silent Depreciation</a>
            <a href="ghostAssests.jsp">👻 Ghost Assets</a>
            <a href="auditLog.jsp">🛡 Audit Trail</a>
            <a href="logout.jsp">🚪 Logout</a>
        </div>

        <!-- MAIN -->
        <div class="main">

            <!-- KPI CARDS -->
            <div class="cards">
                <div class="card">
                    <h3>Total Assets</h3>
                    <p><%= totalAssets %></p>
                </div>
                <div class="card">
                    <h3>High Trust Assets</h3>
                    <p><%= highTrustAssets %></p>
                </div>
                <div class="card">
                    <h3>At-Risk Assets</h3>
                    <p><%= atRiskAssets %></p>
                </div>
                <div class="card">
                    <h3>Ghost Assets</h3>
                    <p><%= ghostAssets %></p>
                </div>
            </div>

            <!-- INTELLIGENCE SECTION -->
            <div class="section">
                <h2>Operational Intelligence Summary</h2>
                <p>
                    This platform evaluates assets based on <b>behavior, trust decay,
                        and operational usage</b> rather than static inventory records.
                </p>
                <p>
                    Assets with declining trust or abnormal usage patterns are
                    automatically highlighted to support <b>proactive decision-making</b>.
                </p>
            </div>

        </div>

    </body>
</html>
