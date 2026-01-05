<%@ page import="java.sql.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    /* Admin-only access check */
    if (session.getAttribute("user") == null || !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String role = (String) session.getAttribute("role");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Initialize Asset | KN AIBTS</title>
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
            display: flex;
            justify-content: center;
            align-items: flex-start;
        }

        .form-container {
            width: 100%;
            max-width: 800px;
            margin-top: 20px;
            animation: fadeInUp 0.6s ease-out;
        }

        .header-area { margin-bottom: 30px; }
        h1 { font-family: 'Outfit', sans-serif; font-size: 28px; font-weight: 500; color: white; }
        .subtitle { color: var(--text-muted); font-size: 14px; margin-top: 5px; }

        /* ===== CARD & FORM ===== */
        .card {
            background: var(--card-bg);
            backdrop-filter: blur(10px);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 20px 50px -10px rgba(0,0,0,0.5);
        }

        form {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 25px;
        }

        .full-width { grid-column: span 2; }

        label {
            display: block;
            margin-bottom: 8px;
            color: var(--text-muted);
            font-size: 13px;
            font-weight: 500;
        }

        input {
            width: 100%;
            padding: 14px 16px;
            background: rgba(5, 10, 16, 0.5);
            border: 1px solid var(--border);
            border-radius: 8px;
            color: white;
            font-family: 'Inter', sans-serif;
            outline: none;
            transition: 0.3s;
        }

        /* Fixes date picker icon color in dark mode */
        input[type="date"] {
            color-scheme: dark;
        }

        input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 2px rgba(56, 189, 248, 0.2);
            background: rgba(5, 10, 16, 0.8);
        }

        button {
            width: 100%;
            padding: 14px;
            background: linear-gradient(90deg, var(--accent), var(--primary));
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            font-family: 'Outfit', sans-serif;
            margin-top: 10px;
        }

        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(99, 102, 241, 0.3);
        }

        /* ===== ALERTS ===== */
        .alert {
            grid-column: span 2;
            padding: 15px;
            border-radius: 8px;
            margin-top: 10px;
            display: flex;
            align-items: center;
            font-size: 14px;
            animation: fadeInUp 0.3s ease-out;
        }

        .alert-success {
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.3);
            color: #6ee7b7;
        }

        .alert-error {
            background: rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.3);
            color: #fca5a5;
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
            <a href="assetDashboard.jsp" class="nav-item"><span class="nav-icon">📊</span> Dashboard</a>
            <a href="viewAssets.jsp" class="nav-item"><span class="nav-icon">📦</span> Asset Inventory</a>
            <a href="addAsset.jsp" class="nav-item active"><span class="nav-icon">➕</span> Add Asset</a> 
            <a href="assignmentHistory.jsp" class="nav-item"><span class="nav-icon">🔄</span> Assignments</a>
            <a href="logout.jsp" class="nav-item" style="color: var(--danger); margin-top: auto;"><span class="nav-icon">🚪</span> Logout</a>
        </div>
    </div>

    <div class="main-content">
        
        <div class="form-container">
            <div class="header-area">
                <h1>Initialize New Asset</h1>
                <div class="subtitle">Register hardware into the neural tracking core.</div>
            </div>

            <div class="card">
                <form method="post">
                    
                    <div class="full-width">
                        <label>Asset Tag / Serial ID</label>
                        <input type="text" name="asset_tag" placeholder="e.g. KN-LPT-2025-X01" required autocomplete="off">
                    </div>

                    <div>
                        <label>Category</label>
                        <input type="text" name="category" placeholder="e.g. Laptop, Server, Drone" list="categories">
                        <datalist id="categories">
                            <option value="Laptop">
                            <option value="Workstation">
                            <option value="Server">
                            <option value="Mobile Device">
                            <option value="Network Gear">
                        </datalist>
                    </div>

                    <div>
                        <label>Purchase Date</label>
                        <input type="date" name="purchase_date" required>
                    </div>

                    <div class="full-width">
                        <label>Vendor / Source</label>
                        <input type="text" name="purchase_source" placeholder="e.g. Dell Enterprise, Amazon Business">
                    </div>

                    <div class="full-width">
                        <button type="submit">Register Asset to Ledger</button>
                    </div>

                    <%
                        if ("POST".equalsIgnoreCase(request.getMethod())) {
                            try {
                                PreparedStatement ps = conn.prepareStatement(
                                        "INSERT INTO asset_core(asset_tag, category, purchase_source, purchase_date) VALUES(?,?,?,?)");

                                ps.setString(1, request.getParameter("asset_tag"));
                                ps.setString(2, request.getParameter("category"));
                                ps.setString(3, request.getParameter("purchase_source"));
                                ps.setString(4, request.getParameter("purchase_date"));

                                int rows = ps.executeUpdate();
                                if(rows > 0){
                                    out.println("<div class='alert alert-success'>✔ Asset successfully initialized and tracking started.</div>");
                                }

                            } catch (Exception e) {
                                out.println("<div class='alert alert-error'>⚠ Registration Error: " + e.getMessage() + "</div>");
                            }
                        }
                    %>
                </form>
            </div>
        </div>
    </div>

</body>
</html>