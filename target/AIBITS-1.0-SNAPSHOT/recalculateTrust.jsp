<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page contentType="text/html" pageEncoding="UTF-8"%>
<%@ include file="db.jsp" %>

<%
    /* ===============================
       TRUST RECALCULATION SERVICE
       =============================== */

    String aidParam = request.getParameter("asset_id");
    if (aidParam == null) return;

    int assetId = Integer.parseInt(aidParam);

    try {

        /* ===============================
           1️⃣ AGGREGATE USAGE
           =============================== */
        PreparedStatement agg = conn.prepareStatement(
            "SELECT " +
            "SUM(usage_hours) AS u, " +
            "SUM(CASE WHEN misuse_flag=1 THEN 1 ELSE 0 END) AS m " +
            "FROM asset_usage_log WHERE asset_id=?");
        agg.setInt(1, assetId);
        ResultSet ar = agg.executeQuery();

        int usage = 0;
        int misuse = 0;
        if (ar.next()) {
            usage = ar.getInt("u");
            misuse = ar.getInt("m");
        }

        /* ===============================
           2️⃣ BASE TRUST CALC
           =============================== */
        int score = 100;
        score -= misuse * 15;
        score -= (usage / 50) * 2;

        /* ===============================
           3️⃣ DEPRECIATION
           =============================== */
        PreparedStatement depPS = conn.prepareStatement(
            "SELECT calculated_value FROM depreciation_engine " +
            "WHERE asset_id=? ORDER BY calculated_on DESC LIMIT 1");
        depPS.setInt(1, assetId);
        ResultSet depRS = depPS.executeQuery();

        double dep = depRS.next() ? depRS.getDouble(1) : 0;
        score -= (int)(dep / 10);

        if (score < 0) score = 0;

        /* ===============================
           4️⃣ PREVIOUS TRUST
           =============================== */
        PreparedStatement prev = conn.prepareStatement(
            "SELECT current_trust_score FROM asset_core WHERE asset_id=?");
        prev.setInt(1, assetId);
        ResultSet pr = prev.executeQuery();

        int oldScore = pr.next() ? pr.getInt(1) : 100;

        /* ===============================
           5️⃣ UPDATE CORE
           =============================== */
        PreparedStatement up = conn.prepareStatement(
            "UPDATE asset_core SET current_trust_score=? WHERE asset_id=?");
        up.setInt(1, score);
        up.setInt(2, assetId);
        up.executeUpdate();

        /* ===============================
           6️⃣ TRUST HISTORY
           =============================== */
        PreparedStatement tlog = conn.prepareStatement(
            "INSERT INTO trust_score_log(asset_id,old_score,new_score,reason) " +
            "VALUES(?,?,?,?)");
        tlog.setInt(1, assetId);
        tlog.setInt(2, oldScore);
        tlog.setInt(3, score);
        tlog.setString(4, "Usage + misuse + depreciation recalculation");
        tlog.executeUpdate();

        /* ===============================
           7️⃣ AUTO LOCK ASSET
           =============================== */
        if (score < 20) {
            PreparedStatement lock = conn.prepareStatement(
                "UPDATE asset_core SET status='LOCKED' WHERE asset_id=?");
            lock.setInt(1, assetId);
            lock.executeUpdate();

            PreparedStatement audit = conn.prepareStatement(
                "INSERT INTO decision_audit_log(asset_id,action_type,reason,performed_by) " +
                "VALUES(?,?,?,0)");
            audit.setInt(1, assetId);
            audit.setString(2, "ASSET_LOCKED");
            audit.setString(3, "Trust score below safety threshold");
            audit.executeUpdate();
        }

        /* ===============================
           8️⃣ ASSET DNA EVOLUTION
           =============================== */
        String dnaRaw = assetId + "|" + score + "|" + System.currentTimeMillis();
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest(dnaRaw.getBytes("UTF-8"));

        StringBuilder dna = new StringBuilder();
        for (byte b : hash) {
            dna.append(String.format("%02x", b));
        }

        PreparedStatement dnaPS = conn.prepareStatement(
            "INSERT INTO asset_dna_timeline(asset_id,dna_hash,trigger_event) " +
            "VALUES(?,?,?)");
        dnaPS.setInt(1, assetId);
        dnaPS.setString(2, dna.toString());
        dnaPS.setString(3, "TRUST_RECALCULATION");
        dnaPS.executeUpdate();

    } catch (Exception e) {
        e.printStackTrace();
    }
%>
