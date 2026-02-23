/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */
/*
 * ScratchBird JDBC Driver integration tests
 */
package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
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
             ResultSet rs = stmt.executeQuery("SELECT * FROM type_coverage")) {
            assertEquals(true, rs.next());
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void cancelQuery() throws Exception {
        String cancelSql = System.getenv("SCRATCHBIRD_JDBC_CANCEL_SQL");
        if (cancelSql == null || cancelSql.isEmpty()) {
            return;
        }
        ExecutorService executor = Executors.newSingleThreadExecutor();
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement()) {
            Future<Boolean> future = executor.submit(() -> stmt.execute(cancelSql));
            Thread.sleep(200);
            stmt.cancel();
            try {
                future.get();
                assertTrue(false, "expected cancel error");
            } catch (ExecutionException ex) {
                // expected cancel or execution error
            }
            try (Statement verify = conn.createStatement();
                 ResultSet verifyRs = verify.executeQuery("SELECT 1")) {
                verifyRs.next();
                assertEquals(1, verifyRs.getInt(1));
            }
        } finally {
            executor.shutdownNow();
        }
    }
}
