<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    // --- AUTHENTICATION CHECK ---
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String role = (String) session.getAttribute("role");
    
    // --- SEARCH LOGIC ---
    String q = request.getParameter("q");
    String sql = "SELECT * FROM asset_core";
    
    // Note: In production, consider using PreparedStatement to prevent SQL Injection
    if (q != null && !q.trim().isEmpty()) {
        // Sanitize simple single quotes to avoid breaking the query
        String safeQ = q.replace("'", ""); 
        sql += " WHERE asset_id LIKE '%" + safeQ + "%' OR category LIKE '%" + safeQ + "%' OR status LIKE '%" + safeQ + "%'";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Asset Inventory | KN AIBTS</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;500;700&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg-dark: #050a10;
            --sidebar-bg: rgba(15, 23, 42, 0.8);
            --primary: #38bdf8;
            --accent: #6366f1;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
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
            background: linear-gradient(90deg, #fff, var(--primary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 40px;
            padding-left: 10px;
        }

        .nav-links { display: flex; flex-direction: column; gap: 8px; flex-grow: 1; }

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
        }

        .nav-item:hover, .nav-item.active {
            background: rgba(56, 189, 248, 0.1);
            color: var(--primary);
            box-shadow: 0 0 15px rgba(56, 189, 248, 0.1);
        }

        .nav-icon { margin-right: 12px; font-size: 18px; }

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
            margin-bottom: 30px;
        }

        h1 { font-family: 'Outfit', sans-serif; font-size: 28px; font-weight: 500; }
        .subtitle { color: var(--text-muted); font-size: 14px; margin-top: 5px; }

        /* ===== SEARCH BAR ===== */
        .search-container {
            display: flex;
            gap: 10px;
            margin-bottom: 25px;
            max-width: 600px;
        }

        .search-input {
            flex: 1;
            padding: 12px 20px;
            border-radius: 50px;
            background: rgba(5, 10, 16, 0.5);
            border: 1px solid var(--border);
            color: white;
            font-family: 'Inter', sans-serif;
            outline: none;
            transition: all 0.3s;
        }

        .search-input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 15px rgba(56, 189, 248, 0.15);
        }

        .search-btn {
            padding: 12px 25px;
            border-radius: 50px;
            border: 1px solid var(--border);
            background: rgba(255, 255, 255, 0.05);
            color: var(--text-main);
            cursor: pointer;
            transition: all 0.3s;
        }

        .search-btn:hover {
            background: var(--primary);
            color: black;
            border-color: var(--primary);
        }

        /* ===== TABLE CARD ===== */
        .card {
            background: var(--card-bg);
            backdrop-filter: blur(10px);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 25px;
            animation: fadeInUp 0.6s ease-out;
            overflow-x: auto;
        }

        table { width: 100%; border-collapse: collapse; }

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
            vertical-align: middle;
        }

        tr:hover td { background: rgba(255, 255, 255, 0.02); }

        /* Status Badge */
        .badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge-active { background: rgba(16, 185, 129, 0.15); color: var(--success); border: 1px solid rgba(16, 185, 129, 0.2); }
        .badge-retired { background: rgba(239, 68, 68, 0.15); color: var(--danger); border: 1px solid rgba(239, 68, 68, 0.2); }
        .badge-maintenance { background: rgba(245, 158, 11, 0.15); color: var(--warning); border: 1px solid rgba(245, 158, 11, 0.2); }

        /* Action Buttons */
        .btn-action {
            display: inline-block;
            padding: 6px 12px;
            font-size: 12px;
            border-radius: 6px;
            text-decoration: none;
            transition: all 0.2s;
            margin-right: 5px;
        }

        .btn-edit { background: rgba(99, 102, 241, 0.1); color: var(--accent); }
        .btn-edit:hover { background: var(--accent); color: white; }

        .btn-delete { background: rgba(239, 68, 68, 0.1); color: var(--danger); }
        .btn-delete:hover { background: var(--danger); color: white; }

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
            <a href="assetDashboard.jsp" class="nav-item"><span class="nav-icon">📊</span> Dashboard</a>
            <a href="viewAssets.jsp" class="nav-item active"><span class="nav-icon">📦</span> Asset Inventory</a>
            <% if ("ADMIN".equals(role)) { %>
                <a href="addAsset.jsp" class="nav-item"><span class="nav-icon">➕</span> Add Asset</a>
            <% } %>
            <a href="assetDNA.jsp" class="nav-item"><span class="nav-icon">🧬</span> DNA Profile</a>
            <a href="assignmentHistory.jsp" class="nav-item"><span class="nav-icon">🔄</span> Assignments</a>
            <a href="trustScore.jsp" class="nav-item"><span class="nav-icon">🛡️</span> Trust Scores</a>
            <a href="logout.jsp" class="nav-item" style="color: var(--danger); margin-top: auto;"><span class="nav-icon">🚪</span> Logout</a>
        </div>
    </div>

    <div class="main-content">
        
        <div class="header-area">
            <div>
                <h1>Global Asset Inventory</h1>
                <div class="subtitle">Real-time database of all registered hardware entities.</div>
            </div>
        </div>

        <form method="get" class="search-container">
            <input type="text" name="q" class="search-input" placeholder="Search by ID, Category, or Status..." value="<%= (q != null) ? q : "" %>">
            <button type="submit" class="search-btn">Search Database</button>
        </form>

        <div class="card">
            <table>
                <thead>
                    <tr>
                        <th>Asset ID</th>
                        <th>Category</th>
                        <th>Status</th>
                        <th>Trust Score</th>
                        <th>Action Protocol</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try {
                            Statement st = conn.createStatement();
                            ResultSet rs = st.executeQuery(sql);
                            
                            while (rs.next()) {
                                int id = rs.getInt("asset_id");
                                String category = rs.getString("category");
                                String status = rs.getString("status");
                                int trust = rs.getInt("current_trust_score");

                                // Determine Badge Style
                                String badgeClass = "badge-active"; // default
                                if("Retired".equalsIgnoreCase(status)) badgeClass = "badge-retired";
                                if("Maintenance".equalsIgnoreCase(status)) badgeClass = "badge-maintenance";

                                // Determine Trust Color
                                String trustColor = "#94a3b8"; // grey
                                if(trust >= 80) trustColor = "#10b981"; // green
                                if(trust < 50) trustColor = "#ef4444"; // red
                    %>
                    <tr>
                        <td style="font-family: monospace; color: var(--primary);">#<%= id %></td>
                        <td><%= category %></td>
                        <td><span class="badge <%= badgeClass %>"><%= status %></span></td>
                        <td style="font-weight: 700; color: <%= trustColor %>;"><%= trust %>%</td>
                        <td>
                            <% if ("ADMIN".equals(role)) { %>
                                <a href="editAsset.jsp?id=<%= id %>" class="btn-action btn-edit">Edit</a>
                                <a href="deleteAsset.jsp?id=<%= id %>" class="btn-action btn-delete">Retire</a>
                            <% } else { %>
                                <span style="font-size: 12px; color: var(--text-muted);">View Only</span>
                            <% } %>
                        </td>
                    </tr>
                    <% 
                            }
                        } catch(Exception e) {
                            out.println("<tr><td colspan='5' style='text-align:center; color: var(--danger);'>Error loading data: " + e.getMessage() + "</td></tr>");
                        }
                    %>
                </tbody>
            </table>
        </div>

    </div>

</body>
</html>