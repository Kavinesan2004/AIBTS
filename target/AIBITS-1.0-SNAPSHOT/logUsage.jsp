<%@ page import="java.sql.*" %>
<%@ page import="java.security.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String msg = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        try {
            int assetId = Integer.parseInt(request.getParameter("asset_id"));
            int userId  = (Integer) session.getAttribute("user_id");
            int usage   = Integer.parseInt(request.getParameter("usage_hours"));
            int misuse  = Integer.parseInt(request.getParameter("misuse_flag"));

            /* ===== VALIDATE USAGE ===== */
            if (usage < 0 || usage > 24) {
                msg = "Usage hours must be between 0 and 24";
            } else {

                int idle = 24 - usage;   // ✅ AUTO IDLE CALCULATION

                /* ===== ASSET CHECK ===== */
                PreparedStatement chk = conn.prepareStatement(
                    "SELECT status FROM asset_core WHERE asset_id=?");
                chk.setInt(1, assetId);
                ResultSet crs = chk.executeQuery();

                if (!crs.next()) {
                    msg = "Invalid Asset ID";
                } else if (!"ACTIVE".equals(crs.getString("status"))) {
                    msg = "Usage blocked. Asset is not ACTIVE.";
                } else {

                    /* ===== ASSIGNMENT CHECK ===== */
                    PreparedStatement asg = conn.prepareStatement(
                        "SELECT user_id FROM assignment_chain " +
                        "WHERE asset_id=? ORDER BY assigned_on DESC LIMIT 1");
                    asg.setInt(1, assetId);
                    ResultSet ars = asg.executeQuery();

                    if (!ars.next()) {
                        msg = "Asset not assigned.";
                    } else if (ars.getInt("user_id") != userId) {
                        msg = "You are not assigned to this asset.";
                    } else {

                        /* ===== AUTO MISUSE RULE (OPTIONAL) ===== */
                        if (usage == 0 && idle > 8) {
                            misuse = 1; // ghost / hoarding behavior
                        }

                        /* ===== INSERT USAGE LOG ===== */
                        PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO asset_usage_log(asset_id,user_id,usage_hours,idle_hours,misuse_flag) " +
                            "VALUES (?,?,?,?,?)");
                        ps.setInt(1, assetId);
                        ps.setInt(2, userId);
                        ps.setInt(3, usage);
                        ps.setInt(4, idle);
                        ps.setInt(5, misuse);
                        ps.executeUpdate();

                        /* ===== USER TRUST DECAY ===== */
                        if (misuse == 1) {
                            PreparedStatement ut = conn.prepareStatement(
                                "UPDATE users SET user_trust_score = GREATEST(user_trust_score - 10,0) WHERE user_id=?");
                            ut.setInt(1, userId);
                            ut.executeUpdate();
                        }

                        /* ===== CUMULATIVE DATA ===== */
                        PreparedStatement sum = conn.prepareStatement(
                            "SELECT SUM(usage_hours) u, " +
                            "SUM(idle_hours) i, " +
                            "SUM(CASE WHEN misuse_flag=1 THEN 1 ELSE 0 END) m " +
                            "FROM asset_usage_log WHERE asset_id=?");
                        sum.setInt(1, assetId);
                        ResultSet sr = sum.executeQuery();

                        int totalUsage = 0, totalIdle = 0, misuseCnt = 0;
                        if (sr.next()) {
                            totalUsage = sr.getInt("u");
                            totalIdle  = sr.getInt("i");
                            misuseCnt  = sr.getInt("m");
                        }

                        /* ===== SILENT DEPRECIATION ===== */
                        double usageW  = totalUsage * 0.6;
                        double idleW   = totalIdle * 0.2;
                        double misuseW = misuseCnt * 15;
                        double depreciation = usageW + idleW + misuseW;

                        PreparedStatement dep = conn.prepareStatement(
                            "INSERT INTO depreciation_engine " +
                            "(asset_id,usage_weight,idle_weight,misuse_weight,calculated_value) " +
                            "VALUES (?,?,?,?,?)");
                        dep.setInt(1, assetId);
                        dep.setDouble(2, usageW);
                        dep.setDouble(3, idleW);
                        dep.setDouble(4, misuseW);
                        dep.setDouble(5, depreciation);
                        dep.executeUpdate();

                        /* ===== ASSET DNA AUTO EVOLUTION ===== */
                        String dnaSource =
                            assetId + "|" +
                            totalUsage + "|" +
                            misuseCnt + "|" +
                            depreciation;

                        MessageDigest md = MessageDigest.getInstance("SHA-256");
                        byte[] hash = md.digest(dnaSource.getBytes("UTF-8"));

                        StringBuilder dnaHash = new StringBuilder();
                        for (byte b : hash) dnaHash.append(String.format("%02x", b));

                        PreparedStatement dna = conn.prepareStatement(
                            "INSERT INTO asset_dna_history(asset_id,dna_hash,trigger_event) VALUES (?,?,?)");
                        dna.setInt(1, assetId);
                        dna.setString(2, dnaHash.toString());
                        dna.setString(3, misuse == 1 ? "MISUSE_EVENT" : "USAGE_LOGGED");
                        dna.executeUpdate();

                        response.sendRedirect("trustScore.jsp");
                        return;
                    }
                }
            }
        } catch (Exception e) {
            msg = "Error: " + e.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Log Asset Usage | KN AIBTS</title>
    <meta charset="UTF-8">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;500;700&display=swap" rel="stylesheet">

    <style>
        body{
            margin:0;
            font-family:'Inter',sans-serif;
            background:radial-gradient(circle at top left,#111827,#050a10 80%);
            color:#f1f5f9;
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
            background:linear-gradient(90deg,#fff,#38bdf8);
            -webkit-background-clip:text;
            -webkit-text-fill-color:transparent;
        }
        .nav-item{
            display:block;
            padding:12px 16px;
            color:#94a3b8;
            text-decoration:none;
            border-radius:8px;
        }
        .nav-item:hover,.active{
            background:rgba(56,189,248,.1);
            color:#38bdf8;
        }
        .main{
            margin-left:260px;
            padding:40px;
            width:calc(100% - 260px);
        }
        .card{
            background:rgba(30,41,59,.4);
            border-radius:16px;
            padding:30px;
            max-width:520px;
        }
        label{
            font-size:13px;
            color:#94a3b8;
            margin-top:15px;
            display:block;
        }
        input,select{
            width:100%;
            padding:12px;
            margin-top:8px;
            background:rgba(255,255,255,.05);
            border:1px solid rgba(255,255,255,.08);
            border-radius:8px;
            color:white;
        }
        button{
            width:100%;
            padding:14px;
            margin-top:25px;
            background:#38bdf8;
            border:none;
            border-radius:10px;
            font-weight:600;
            cursor:pointer;
        }
        .msg{
            margin-top:20px;
            color:#ef4444;
        }
        .hint{
            font-size:12px;
            color:#94a3b8;
            margin-top:6px;
        }
    </style>
</head>

<body>

<div class="sidebar">
    <div class="brand">KN AIBTS</div>
    <a href="logUsage.jsp" class="nav-item active">📝 Log Usage</a>
    <a href="trustScore.jsp" class="nav-item">🛡 Trust Score</a>
    <a href="logout.jsp" class="nav-item">🚪 Logout</a>
</div>

<div class="main">
    <h1>Log Asset Usage</h1>
    <p>Idle hours are <b>automatically calculated</b>.</p>

    <div class="card">
        <form method="post">
            <label>Asset ID</label>
            <input type="number" name="asset_id" required>

            <label>Usage Hours (0–24)</label>
            <input type="number" name="usage_hours" required>
            <div class="hint">Idle hours = 24 − usage</div>

            <label>Misuse Detected?</label>
            <select name="misuse_flag">
                <option value="0">No</option>
                <option value="1">Yes</option>
            </select>

            <button type="submit">Submit Usage Log</button>
        </form>

        <% if (!msg.isEmpty()) { %>
            <div class="msg"><%= msg %></div>
        <% } %>
    </div>
</div>

</body>
</html>
