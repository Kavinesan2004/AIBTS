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
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Assignment Memory | KN AIBTS</title>
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
            --success: #10b981; 
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

        /* ===== SIDEBAR (Same as Dashboard) ===== */
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
            animation: fadeInUp 0.6s ease-out;
        }

        h1 { font-family: 'Outfit', sans-serif; font-size: 28px; font-weight: 500; }
        .subtitle { color: var(--text-muted); font-size: 14px; margin-top: 5px; }

        /* ===== CARDS ===== */
        .card {
            background: var(--card-bg);
            backdrop-filter: blur(10px);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 30px;
            margin-bottom: 30px;
            animation: fadeInUp 0.6s ease-out backwards;
        }
        
        .card:nth-child(2) { animation-delay: 0.1s; } /* Stagger animation */

        .card-header {
            margin-bottom: 25px;
            border-bottom: 1px solid var(--border);
            padding-bottom: 15px;
        }

        .card-title {
            font-family: 'Outfit', sans-serif;
            font-size: 18px;
            color: var(--primary);
            display: flex;
            align-items: center;
        }

        .card-title::before {
            content: ''; width: 6px; height: 24px; background: var(--accent);
            border-radius: 4px; margin-right: 12px;
        }

        /* ===== FORMS ===== */
        form { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .full-width { grid-column: span 2; }

        label {
            display: block;
            margin-bottom: 8px;
            color: var(--text-muted);
            font-size: 13px;
        }

        input, select {
            width: 100%;
            padding: 12px 16px;
            background: rgba(5, 10, 16, 0.5);
            border: 1px solid var(--border);
            border-radius: 8px;
            color: white;
            font-family: 'Inter', sans-serif;
            outline: none;
            transition: 0.3s;
        }

        /* Dark Mode Select Dropdown */
        select option { background-color: #0f172a; color: white; }

        input:focus, select:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 2px rgba(56, 189, 248, 0.2);
        }

        input[type="submit"] {
            background: linear-gradient(90deg, var(--accent), var(--primary));
            color: white;
            font-weight: 600;
            border: none;
            cursor: pointer;
            margin-top: 10px;
            transition: transform 0.2s;
        }

        input[type="submit"]:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(99, 102, 241, 0.4);
        }

        /* ===== TABLE ===== */
        table { width: 100%; border-collapse: collapse; }
        
        th {
            text-align: left; padding: 15px; color: var(--text-muted);
            font-size: 12px; text-transform: uppercase; letter-spacing: 1px;
            border-bottom: 1px solid var(--border);
        }

        td {
            padding: 15px; border-bottom: 1px solid rgba(255, 255, 255, 0.03);
            color: var(--text-main); font-size: 14px;
        }

        tr:hover td { background: rgba(255, 255, 255, 0.02); }

        /* ===== ALERTS ===== */
        .alert {
            padding: 15px; border-radius: 8px; margin-top: 20px; grid-column: span 2;
            font-size: 14px; display: flex; align-items: center;
        }
        .alert-success { background: rgba(16, 185, 129, 0.1); border: 1px solid rgba(16, 185, 129, 0.3); color: #6ee7b7; }
        .alert-error { background: rgba(239, 68, 68, 0.1); border: 1px solid rgba(239, 68, 68, 0.3); color: #fca5a5; }

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
            <a href="viewAssets.jsp" class="nav-item"><span class="nav-icon">📦</span> Asset Inventory</a>
            <a href="assetDNA.jsp" class="nav-item"><span class="nav-icon">🧬</span> DNA Profile</a>
            <a href="assignmentHistory.jsp" class="nav-item active"><span class="nav-icon">🔄</span> Assignments</a>
            <a href="depreciation.jsp" class="nav-item"><span class="nav-icon">📉</span> Silent Depreciation</a>
            <a href="trustScore.jsp" class="nav-item"><span class="nav-icon">🛡️</span> Trust Scores</a>
            <a href="ghostAssests.jsp" class="nav-item"><span class="nav-icon">👻</span> Ghost Detection</a>
            <% if ("ADMIN".equals(role)) { %>
            <a href="register.jsp" class="nav-item"><span class="nav-icon">👤</span> Create User</a>
            <% } %>
        </div>
    </div>

    <div class="main-content">
        
        <div class="header-area">
            <div>
                <h1>Assignment Neural Chain</h1>
                <div class="subtitle">Track custody and operational responsibility</div>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <div class="card-title">Initiate Asset Transfer</div>
            </div>

            <% if ("ADMIN".equals(role)) { %>
                <form method="post">
                    <div>
                        <label>Asset ID / Tag</label>
                        <input type="number" name="asset_id" placeholder="Enter Asset ID..." required>
                    </div>

                    <div>
                        <label>Assign To User</label>
                        <select name="user_id" required>
                            <option value="" disabled selected>Select an operator...</option>
                            <%
                                try {
                                    ResultSet usersRS = conn.createStatement()
                                        .executeQuery("SELECT user_id, username FROM users WHERE role='USER'");
                                    while (usersRS.next()) {
                            %>
                            <option value="<%=usersRS.getInt("user_id")%>">
                                <%=usersRS.getString("username")%>
                            </option>
                            <%      }
                                } catch(Exception e) {} 
                            %>
                        </select>
                    </div>

                    <div class="full-width">
                        <label>Operational Purpose</label>
                        <input type="text" name="purpose" placeholder="Reason for assignment (e.g., Remote Site Alpha)" required>
                    </div>

                    <div class="full-width">
                        <input type="submit" value="Authorize Assignment">
                    </div>
                </form>

                <%
                    // --- PROCESS FORM SUBMISSION ---
                    if ("POST".equalsIgnoreCase(request.getMethod())) {
                        try {
                            int assetId = Integer.parseInt(request.getParameter("asset_id"));
                            int assignedTo = Integer.parseInt(request.getParameter("user_id"));
                            String purpose = request.getParameter("purpose");
                            int performedBy = (Integer) session.getAttribute("user_id");

                            // 1. Insert into Assignment Chain
                            PreparedStatement assignPS = conn.prepareStatement(
                                "INSERT INTO assignment_chain(asset_id,user_id,purpose,assigned_on) VALUES(?,?,?,NOW())");
                            assignPS.setInt(1, assetId);
                            assignPS.setInt(2, assignedTo);
                            assignPS.setString(3, purpose);
                            assignPS.executeUpdate();

                            // 2. Log in Decision Audit
                            PreparedStatement auditPS = conn.prepareStatement(
                                "INSERT INTO decision_audit_log(asset_id,action_type,reason,performed_by) VALUES(?,?,?,?)");
                            auditPS.setInt(1, assetId);
                            auditPS.setString(2, "ASSET_ASSIGNED");
                            auditPS.setString(3, "Assigned to user ID " + assignedTo + " for " + purpose);
                            auditPS.setInt(4, performedBy);
                            auditPS.executeUpdate();

                            out.println("<div class='alert alert-success'>✔ Asset successfully assigned and logged in the immutable ledger.</div>");

                        } catch (Exception e) {
                            out.println("<div class='alert alert-error'>⚠ Assignment Failed: " + e.getMessage() + "</div>");
                        }
                    }
                %>

            <% } else { %>
                <div style="text-align: center; padding: 20px; color: var(--text-muted);">
                    🔒 <b>Read-Only Mode:</b> Only Administrators can initiate asset transfers.
                </div>
            <% } %>
        </div>

        <div class="card">
            <div class="card-header">
                <div class="card-title">Immutable Assignment Ledger</div>
            </div>

            <table>
                <thead>
                    <tr>
                        <th>Asset ID</th>
                        <th>Assigned To</th>
                        <th>Purpose / Mission</th>
                        <th>Date Assigned</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try {
                            ResultSet rs = conn.createStatement().executeQuery(
                                "SELECT a.asset_id, u.username, a.purpose, a.assigned_on " +
                                "FROM assignment_chain a " +
                                "JOIN users u ON a.user_id = u.user_id " +
                                "ORDER BY a.assigned_on DESC");

                            while (rs.next()) {
                    %>
                    <tr>
                        <td style="color: var(--primary); font-family: monospace;">#<%= rs.getInt("asset_id") %></td>
                        <td style="font-weight: 600;"><%= rs.getString("username") %></td>
                        <td style="color: var(--text-muted);"><%= rs.getString("purpose") %></td>
                        <td><%= rs.getTimestamp("assigned_on") %></td>
                    </tr>
                    <% 
                            }
                        } catch(Exception e) {
                            out.println("<tr><td colspan='4'>Error loading history.</td></tr>");
                        }
                    %>
                </tbody>
            </table>
        </div>

    </div>

</body>
</html>