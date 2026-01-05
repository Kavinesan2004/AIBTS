<%@ page import="java.sql.*" %>
<%@ include file="db.jsp" %>
<%
    try {
        PreparedStatement ps = conn.prepareStatement(
            "SELECT asset_id, " +
            "SUM(usage_hours) u, " +
            "SUM(idle_hours) i, " +
            "SUM(CASE WHEN misuse_flag=1 THEN 1 ELSE 0 END) m " +
            "FROM asset_usage_log GROUP BY asset_id");

        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            int assetId = rs.getInt("asset_id");
            int usage = rs.getInt("u");
            int idle = rs.getInt("i");
            int misuse = rs.getInt("m");

            double usageW = usage * 0.6;
            double idleW = idle * 0.2;
            double misuseW = misuse * 15;
            double depreciation = usageW + idleW + misuseW;

            PreparedStatement ins = conn.prepareStatement(
                "INSERT INTO depreciation_engine " +
                "(asset_id, usage_weight, idle_weight, misuse_weight, calculated_value) " +
                "VALUES (?,?,?,?,?)");
            ins.setInt(1, assetId);
            ins.setDouble(2, usageW);
            ins.setDouble(3, idleW);
            ins.setDouble(4, misuseW);
            ins.setDouble(5, depreciation);
            ins.executeUpdate();

            PreparedStatement up = conn.prepareStatement(
                "UPDATE asset_core SET last_depreciation=? WHERE asset_id=?");
            up.setDouble(1, depreciation);
            up.setInt(2, assetId);
            up.executeUpdate();
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
