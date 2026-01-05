<%@ page import="java.sql.*" %>
<%@ page import="java.security.*" %>
<%@ include file="db.jsp" %>

<%
try{
    Statement st = conn.createStatement();
    ResultSet rs = st.executeQuery(
        "SELECT asset_id, category, status, current_trust_score " +
        "FROM asset_core");

    while(rs.next()){

        int assetId = rs.getInt("asset_id");
        int trust   = rs.getInt("current_trust_score");
        String stat = rs.getString("status");

        /* ================= LIVE BEHAVIOR ================= */
        PreparedStatement bh = conn.prepareStatement(
            "SELECT SUM(usage_hours) u, " +
            "SUM(CASE WHEN misuse_flag=1 THEN 1 ELSE 0 END) m " +
            "FROM asset_usage_log WHERE asset_id=?");
        bh.setInt(1, assetId);
        ResultSet br = bh.executeQuery();

        int usage = 0, misuse = 0;
        if(br.next()){
            usage = br.getInt("u");
            misuse = br.getInt("m");
        }

        /* ================= DEPRECIATION ================= */
        PreparedStatement dp = conn.prepareStatement(
            "SELECT calculated_value FROM depreciation_engine " +
            "WHERE asset_id=? ORDER BY calculated_on DESC LIMIT 1");
        dp.setInt(1, assetId);
        ResultSet dr = dp.executeQuery();
        double depreciation = dr.next() ? dr.getDouble(1) : 0;

        /* ================= BUILD EXPECTED DNA ================= */
        String dnaSource =
            assetId + "|" +
            usage + "|" +
            misuse + "|" +
            depreciation;

        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest(dnaSource.getBytes("UTF-8"));

        String expectedDNA = "";
        for(byte b : hash){
            expectedDNA += String.format("%02x", b);
        }

        /* ================= FETCH LAST STORED DNA ================= */
        PreparedStatement last = conn.prepareStatement(
            "SELECT dna_hash FROM asset_dna_history " +
            "WHERE asset_id=? ORDER BY created_on DESC LIMIT 1");
        last.setInt(1, assetId);
        ResultSet lr = last.executeQuery();

        String storedDNA = lr.next() ? lr.getString(1) : "";

        boolean tampered = !storedDNA.equals("") && !storedDNA.equals(expectedDNA);

        String cls = trust >= 80 ? "high" :
                     trust >= 50 ? "mid" : "low";
%>

<tr>
    <td style="font-family:monospace;color:var(--primary)">
        #<%=assetId%>
    </td>
    <td><%=rs.getString("category")%></td>
    <td><%=stat%></td>
    <td class="<%=cls%>"><%=trust%></td>
    <td>
        <%= tampered ? "? TAMPERED" : "? SAFE" %>
    </td>
</tr>

<%
        /* ================= AUTO ACTION ================= */
        if(tampered){

            PreparedStatement lock = conn.prepareStatement(
                "UPDATE asset_core SET status='LOCKED' WHERE asset_id=?");
            lock.setInt(1, assetId);
            lock.executeUpdate();

            PreparedStatement audit = conn.prepareStatement(
                "INSERT INTO decision_audit_log(asset_id,action_type,reason,performed_by) " +
                "VALUES(?,?,?,0)");
            audit.setInt(1, assetId);
            audit.setString(2, "DNA_TAMPERING_DETECTED");
            audit.setString(3, "DNA mismatch detected during trust evaluation");
            audit.executeUpdate();
        }
    }
}catch(Exception e){
%>
<tr>
    <td colspan="5" style="color:red">
        Error: <%= e.getMessage() %>
    </td>
</tr>
<%
}
%>
