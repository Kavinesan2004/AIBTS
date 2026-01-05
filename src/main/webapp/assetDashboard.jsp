<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>


<%
    // --- AUTHENTICATION CHECK ---
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int total = 0, high = 0, risk = 0, ghost = 0;

    try {
        Statement st = conn.createStatement();

        ResultSet r1 = st.executeQuery("SELECT COUNT(*) FROM asset_core");
        if (r1.next()) total = r1.getInt(1);

        ResultSet r2 = st.executeQuery("SELECT COUNT(*) FROM asset_core WHERE current_trust_score >= 80");
        if (r2.next()) high = r2.getInt(1);

        ResultSet r3 = st.executeQuery("SELECT COUNT(*) FROM asset_core WHERE current_trust_score < 50");
        if (r3.next()) risk = r3.getInt(1);

        // Ghost assets: Assets defined in core but having NO log entries
        ResultSet r4 = st.executeQuery(
            "SELECT COUNT(*) FROM asset_core a LEFT JOIN asset_usage_log u ON a.asset_id=u.asset_id WHERE u.asset_id IS NULL");
        if (r4.next()) ghost = r4.getInt(1);
        
    } catch(Exception e) {
        // Handle database errors silently or log them
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Command Center | KN AIBTS</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;500;700&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg-dark: #050a10;
            --sidebar-bg: rgba(15, 23, 42, 0.8);
            --primary: #38bdf8; /* Cyan */
            --accent: #6366f1; /* Indigo */
            --success: #10b981; /* Green */
            --warning: #f59e0b; /* Orange */
            --danger: #ef4444; /* Red */
            --text-main: #f1f5f9;
            --text-muted: #94a3b8;
            --border: rgba(255, 255, 255, 0.08);
            --card-bg: rgba(30, 41, 59, 0.4);
            --glass: blur(12px);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--bg-dark);
            color: var(--text-main);
            background: radial-gradient(circle at top left, #111827, #050a10 80%);
            min-height: 100vh;
            display: flex;
        }

        /* ===== SIDEBAR ===== */
        .sidebar {
            width: 260px;
            background: var(--sidebar-bg);
            backdrop-filter: var(--glass);
            border-right: 1px solid var(--border);
            height: 100vh;
            position: fixed;
            top: 0;
            left: 0;
            padding: 30px 20px;
            display: flex;
            flex-direction: column;
            z-index: 10;
        }

        .brand {
            font-family: 'Outfit', sans-serif;
            font-size: 24px;
            font-weight: 700;
            color: var(--text-main);
            margin-bottom: 40px;
            padding-left: 10px;
            background: linear-gradient(90deg, #fff, var(--primary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .nav-links {
            display: flex;
            flex-direction: column;
            gap: 8px;
            flex-grow: 1;
        }

        .nav-item {
            display: flex;
            align-items: center;
            padding: 12px 16px;
            color: var(--text-muted);
            text-decoration: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s;
            border: 1px solid transparent;
        }

        .nav-item:hover, .nav-item.active {
            background: rgba(56, 189, 248, 0.1);
            color: var(--primary);
            border-color: rgba(56, 189, 248, 0.2);
            box-shadow: 0 0 15px rgba(56, 189, 248, 0.1);
        }

        .nav-icon { margin-right: 12px; font-size: 18px; }

        .user-profile {
            padding: 15px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 12px;
            border: 1px solid var(--border);
            margin-top: auto;
        }

        .user-info { font-size: 12px; color: var(--text-muted); margin-bottom: 5px; }
        .user-name { font-weight: 600; color: var(--text-main); }
        .user-role { 
            display: inline-block; 
            margin-top: 4px;
            padding: 2px 8px; 
            background: var(--accent); 
            border-radius: 4px; 
            font-size: 10px; 
            text-transform: uppercase; 
        }

        /* ===== MAIN CONTENT ===== */
        .main-content {
            margin-left: 260px;
            flex: 1;
            padding: 40px;
            width: calc(100% - 260px);
        }

        .header-area {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 40px;
        }

        h1 {
            font-family: 'Outfit', sans-serif;
            font-size: 28px;
            font-weight: 500;
        }

        .date-badge {
            font-size: 13px;
            color: var(--text-muted);
            background: rgba(255, 255, 255, 0.05);
            padding: 6px 12px;
            border-radius: 20px;
            border: 1px solid var(--border);
        }

        /* ===== KPI GRID ===== */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 25px;
            margin-bottom: 40px;
        }

        .card {
            background: var(--card-bg);
            backdrop-filter: blur(10px);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 25px;
            position: relative;
            overflow: hidden;
            transition: transform 0.3s, box-shadow 0.3s;
            animation: fadeInUp 0.6s ease-out backwards;
        }

        /* Stagger animations */
        .card:nth-child(1) { animation-delay: 0.1s; border-top: 3px solid var(--primary); }
        .card:nth-child(2) { animation-delay: 0.2s; border-top: 3px solid var(--success); }
        .card:nth-child(3) { animation-delay: 0.3s; border-top: 3px solid var(--warning); }
        .card:nth-child(4) { animation-delay: 0.4s; border-top: 3px solid var(--danger); }

        .card:hover {
            transform: translateY(-5px);
            background: rgba(30, 41, 59, 0.7);
            box-shadow: 0 10px 30px -10px rgba(0,0,0,0.5);
        }

        .card-label {
            font-size: 13px;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
            display: block;
        }

        .card-value {
            font-family: 'Outfit', sans-serif;
            font-size: 42px;
            font-weight: 700;
            color: var(--text-main);
        }

        .card-icon {
            position: absolute;
            top: 20px;
            right: 20px;
            font-size: 24px;
            opacity: 0.5;
            filter: grayscale(100%);
            transition: all 0.3s;
        }

        .card:hover .card-icon {
            opacity: 1;
            filter: grayscale(0%);
            transform: scale(1.1);
        }

        /* ===== TABLE SECTION ===== */
        .table-section {
            background: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 25px;
            animation: fadeInUp 0.6s ease-out 0.5s backwards;
        }

        .section-title {
            font-family: 'Outfit', sans-serif;
            font-size: 18px;
            margin-bottom: 20px;
            color: var(--primary);
            display: flex;
            align-items: center;
        }

        .section-title::before {
            content: '';
            display: inline-block;
            width: 8px;
            height: 8px;
            background: var(--primary);
            border-radius: 50%;
            margin-right: 10px;
            box-shadow: 0 0 10px var(--primary);
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            text-align: left;
            padding: 15px;
            color: var(--text-muted);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
            border-bottom: 1px solid var(--border);
        }

        td {
            padding: 15px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.03);
            color: var(--text-main);
            font-size: 14px;
        }

        tr:last-child td { border-bottom: none; }

        tr:hover td {
            background: rgba(255, 255, 255, 0.02);
            color: white;
        }

        .status-badge {
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            background: rgba(255, 255, 255, 0.1);
        }

        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

    </style>
</head>

<body>

<div class="sidebar">
    <div class="brand">KN AIBTS</div>
    
    <div class="nav-links">
        <a href="assetDashboard.jsp" class="nav-item active"><span class="nav-icon">📊</span> Dashboard</a>
        <a href="viewAssets.jsp" class="nav-item"><span class="nav-icon">📦</span> Asset Inventory</a>
        <a href="assetDNA.jsp" class="nav-item"><span class="nav-icon">🧬</span> DNA Profile</a>
        <a href="assignmentHistory.jsp" class="nav-item"><span class="nav-icon">🔄</span> Assignments</a>
        <a href="depreciation.jsp" class="nav-item"><span class="nav-icon">📉</span> Silent Depreciation</a>
        <a href="trustScore.jsp" class="nav-item"><span class="nav-icon">🛡️</span> Trust Scores</a>
        <a href="ghostAssests.jsp" class="nav-item"><span class="nav-icon">👻</span> Ghost Detection</a>
        
        <% if ("ADMIN".equals(session.getAttribute("role"))) { %>
        <a href="register.jsp" class="nav-item"><span class="nav-icon">👤</span> Create User</a>
        <% } %>
    </div>

    <div class="user-profile">
        <div class="user-info">Logged in as</div>
        <div class="user-name"><%= session.getAttribute("user") %></div>
        <div class="user-role"><%= session.getAttribute("role") %></div>
        <div style="margin-top: 10px;">
            <a href="logout.jsp" style="color: var(--danger); font-size: 12px; text-decoration: none;">Logout ➔</a>
        </div>
    </div>
</div>

<div class="main-content">
    
    <div class="header-area">
        <h1>Operational Overview</h1>
        <span class="date-badge">System Status: ONLINE</span>
    </div>

    <div class="kpi-grid">
        <div class="card">
            <span class="card-label">Total Assets</span>
            <div class="card-value"><%= total %></div>
            <div class="card-icon">📦</div>
        </div>

        <div class="card">
            <span class="card-label" style="color: var(--success);">High Trust</span>
            <div class="card-value" style="color: var(--success);"><%= high %></div>
            <div class="card-icon">✅</div>
        </div>

        <div class="card">
            <span class="card-label" style="color: var(--warning);">At Risk</span>
            <div class="card-value" style="color: var(--warning);"><%= risk %></div>
            <div class="card-icon">⚠️</div>
        </div>

        <div class="card">
            <span class="card-label" style="color: var(--danger);">Ghost Assets</span>
            <div class="card-value" style="color: var(--danger);"><%= ghost %></div>
            <div class="card-icon">👻</div>
        </div>
    </div>

    <div class="table-section">
        <div class="section-title">Audit Log Stream</div>
        
        <table>
            <thead>
                <tr>
                    <th>Asset ID</th>
                    <th>Action Type</th>
                    <th>Timestamp</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <%
                    try {
                        Statement st2 = conn.createStatement();
                        ResultSet rs = st2.executeQuery(
                            "SELECT asset_id, action_type, performed_on FROM decision_audit_log ORDER BY performed_on DESC LIMIT 5");
                        
                        while (rs.next()) {
                %>
                <tr>
                    <td style="font-family: monospace; color: var(--primary);">#<%= rs.getInt(1) %></td>
                    <td><%= rs.getString(2) %></td>
                    <td style="color: var(--text-muted);"><%= rs.getTimestamp(3) %></td>
                    <td><span class="status-badge">LOGGED</span></td>
                </tr>
                <% 
                        }
                    } catch (Exception e) {
                        out.println("<tr><td colspan='4'>Error loading logs</td></tr>");
                    }
                %>
            </tbody>
        </table>
    </div>

</div>

</body>
</html>