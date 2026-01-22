/*
 * ScratchBird JDBC Driver integration tests
 */
package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

public class SBIntegrationTest {

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void connectsAndRunsQuery() throws Exception {
        String url = System.getenv("SCRATCHBIRD_JDBC_URL");
        String user = System.getenv("SCRATCHBIRD_JDBC_USER");
        String password = System.getenv("SCRATCHBIRD_JDBC_PASSWORD");

        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT 1")) {
            rs.next();
            assertEquals(1, rs.getInt(1));
        }
    }
}
