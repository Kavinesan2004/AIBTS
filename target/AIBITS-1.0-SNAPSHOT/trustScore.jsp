<%@ page import="java.sql.*" %>
<%@ page import="java.security.*" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    /* AUTH CHECK */
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    /* ================= TRUST SCORE AUTO ENGINE ================= */
    try {
        PreparedStatement ps = conn.prepareStatement(
            "SELECT asset_id, " +
            "SUM(usage_hours) u, " +
            "SUM(idle_hours) i, " +
            "SUM(CASE WHEN misuse_flag=1 THEN 1 ELSE 0 END) m " +
            "FROM asset_usage_log GROUP BY asset_id");

        ResultSet rs = ps.executeQuery();

        while (rs.next()) {

            int aid = rs.getInt("asset_id");
            int usage = rs.getInt("u");
            int idle  = rs.getInt("i");
            int misuse = rs.getInt("m");

            /* ===== FETCH CORE ===== */
            PreparedStatement core = conn.prepareStatement(
                "SELECT status, current_trust_score FROM asset_core WHERE asset_id=?");
            core.setInt(1, aid);
            ResultSet cr = core.executeQuery();
            if (!cr.next()) continue;

            String status = cr.getString("status");
            int oldScore = cr.getInt("current_trust_score");

            /* ===== LOST / RETIRED RULE ===== */
            if ("LOST".equals(status)) {
                PreparedStatement zero = conn.prepareStatement(
                    "UPDATE asset_core SET current_trust_score=0 WHERE asset_id=?");
                zero.setInt(1, aid);
                zero.executeUpdate();
                continue;
            }

            /* ===== FETCH LATEST DEPRECIATION ===== */
            PreparedStatement dps = conn.prepareStatement(
                "SELECT calculated_value FROM depreciation_engine " +
                "WHERE asset_id=? ORDER BY calculated_on DESC LIMIT 1");
            dps.setInt(1, aid);
            ResultSet dpr = dps.executeQuery();
            double dep = dpr.next() ? dpr.getDouble(1) : 0;

            /* ===== TRUST FORMULA (REAL WORLD) ===== */
            int score = 100;
            score -= misuse * 15;
            score -= (usage / 50) * 2;
            score -= (idle / 100) * 1;
            score -= (int)(dep / 10);

            if (score < 0) score = 0;
            if (score > 100) score = 100;

            if ("LOCKED".equals(status) && score > 30) score = 30;

            /* ===== UPDATE CORE ===== */
            PreparedStatement up = conn.prepareStatement(
                "UPDATE asset_core SET current_trust_score=? WHERE asset_id=?");
            up.setInt(1, score);
            up.setInt(2, aid);
            up.executeUpdate();

            /* ===== TRUST HISTORY ===== */
            PreparedStatement log = conn.prepareStatement(
                "INSERT INTO trust_score_log(asset_id,old_score,new_score,reason) " +
                "VALUES (?,?,?,?)");
            log.setInt(1, aid);
            log.setInt(2, oldScore);
            log.setInt(3, score);
            log.setString(4, "Auto recalculated from usage, idle, misuse & depreciation");
            log.executeUpdate();

            /* ===== AUTO LOCK ===== */
            if (score < 20 && "ACTIVE".equals(status)) {
                PreparedStatement lock = conn.prepareStatement(
                    "UPDATE asset_core SET status='LOCKED' WHERE asset_id=?");
                lock.setInt(1, aid);
                lock.executeUpdate();
            }

            /* ===== DNA TIMELINE ===== */
            String dnaRaw = aid + "|" + score + "|" + System.currentTimeMillis();
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(dnaRaw.getBytes("UTF-8"));
            String dna = "";
            for (byte b : hash) dna += String.format("%02x", b);

            PreparedStatement dnaPS = conn.prepareStatement(
                "INSERT INTO asset_dna_timeline(asset_id,dna_hash,trigger_event) VALUES(?,?,?)");
            dnaPS.setInt(1, aid);
            dnaPS.setString(2, dna);
            dnaPS.setString(3, "TRUST_RECALCULATION");
            dnaPS.executeUpdate();
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Trust Score | KN AIBTS</title>
    <meta charset="UTF-8">

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Outfit:wght@300;500;700&display=swap" rel="stylesheet">

    <style>
        :root{
            --card:rgba(30,41,59,.4);
            --border:rgba(255,255,255,.08);
            --primary:#38bdf8;
            --good:#10b981;
            --warn:#f59e0b;
            --bad:#ef4444;
            --text:#f1f5f9;
            --muted:#94a3b8;
        }

        body{
            font-family:'Inter',sans-serif;
            background:radial-gradient(circle at top left,#111827,#050a10 80%);
            color:var(--text);
            display:flex;
            min-height:100vh;
            margin:0;
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

        .nav a{
            display:block;
            padding:12px 16px;
            margin-bottom:8px;
            color:var(--muted);
            text-decoration:none;
            border-radius:8px;
        }

        .nav a.active,.nav a:hover{
            background:rgba(56,189,248,.1);
            color:var(--primary);
        }

        .main{
            margin-left:260px;
            padding:40px;
            width:calc(100% - 260px);
        }

        .card{
            background:var(--card);
            border:1px solid var(--border);
            border-radius:16px;
            padding:25px;
        }

        table{width:100%;border-collapse:collapse}

        th,td{
            padding:14px;
            border-bottom:1px solid rgba(255,255,255,.05);
        }

        th{
            font-size:12px;
            color:var(--muted);
            text-transform:uppercase;
            text-align:left;
        }

        .high{color:var(--good);font-weight:700}
        .mid{color:var(--warn);font-weight:700}
        .low{color:var(--bad);font-weight:800}

        .badge{
            padding:4px 10px;
            border-radius:20px;
            font-size:11px;
            background:rgba(255,255,255,.08);
        }
    </style>
</head>

<body>

<div class="sidebar">
    <div class="brand">KN AIBTS</div>
    <div class="nav">
        <a href="assetDashboard.jsp">📊 Dashboard</a>
        <a href="trustScore.jsp" class="active">🛡 Trust Score</a>
        <a href="depreciation.jsp">📉 Depreciation</a>
        <a href="ghostAssests.jsp">👻 Ghost Assets</a>
        <a href="logout.jsp">🚪 Logout</a>
    </div>
</div>

<div class="main">
    <h1>Asset Trust Scores</h1>
    <p class="subtitle">Real-time reliability index based on behavior & health</p>

    <div class="card">
        <table>
            <thead>
                <tr>
                    <th>Asset</th>
                    <th>Category</th>
                    <th>Status</th>
                    <th>Trust</th>
                    <th>Health</th>
                </tr>
            </thead>
            <tbody>
            <%
                Statement st = conn.createStatement();
                ResultSet vr = st.executeQuery(
                    "SELECT asset_id, category, status, current_trust_score FROM asset_core ORDER BY current_trust_score DESC");

                while (vr.next()) {
                    int score = vr.getInt("current_trust_score");
                    String cls = score >= 80 ? "high" : score >= 50 ? "mid" : "low";
                    String label = score >= 80 ? "HEALTHY" : score >= 50 ? "WARNING" : "CRITICAL";
            %>
                <tr>
                    <td style="font-family:monospace;color:var(--primary)">#<%=vr.getInt("asset_id")%></td>
                    <td><%=vr.getString("category")%></td>
                    <td><%=vr.getString("status")%></td>
                    <td class="<%=cls%>"><%=score%></td>
                    <td><span class="badge <%=cls%>"><%=label%></span></td>
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
