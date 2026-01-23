/*
 * ScratchBird JDBC Driver integration tests
 */
package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

public class SBIntegrationTest {

    private Connection openConnection() throws Exception {
        String url = System.getenv("SCRATCHBIRD_JDBC_URL");
        if (url == null || url.isEmpty()) {
            return null;
        }
        String user = System.getenv("SCRATCHBIRD_JDBC_USER");
        String password = System.getenv("SCRATCHBIRD_JDBC_PASSWORD");
        return DriverManager.getConnection(url, user, password);
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void connectsAndRunsQuery() throws Exception {
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT 1")) {
            rs.next();
            assertEquals(1, rs.getInt(1));
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void prepareBindQuery() throws Exception {
        try (Connection conn = openConnection();
             PreparedStatement stmt = conn.prepareStatement("SELECT ?::INTEGER")) {
            stmt.setInt(1, 42);
            try (ResultSet rs = stmt.executeQuery()) {
                rs.next();
                assertEquals(42, rs.getInt(1));
            }
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void typesFixtureQuery() throws Exception {
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM sb_conformance.type_coverage")) {
            assertEquals(true, rs.next());
        }
    }
}
