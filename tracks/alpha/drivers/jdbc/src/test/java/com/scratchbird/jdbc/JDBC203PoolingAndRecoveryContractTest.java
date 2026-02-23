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
 * ScratchBird JDBC Driver
 */
package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

/**
 * Cross-runtime contract coverage for pooling and recovery behavior.
 */
public class JDBC203PoolingAndRecoveryContractTest {

    private static final int SCENARIO_C_WORKERS = 10;

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void scenarioA_borrowReuseAfterExplicitCancel() throws Exception {
        String dsn = pooledDsn("MaxPoolSize=4&MinPoolSize=0&ConnectionLifetime=30");
        String cancelSql = System.getenv("SCRATCHBIRD_JDBC_CANCEL_SQL");
        assumeTrue(cancelSql != null && !cancelSql.isBlank(), "SCRATCHBIRD_JDBC_CANCEL_SQL is not set");

        SBConnectionPool.PoolStats before = poolStats(dsn);
        assertNotNull(before);

        try (Connection conn = openConnection(dsn);
             Statement statement = conn.createStatement()) {
            ExecutorService executor = Executors.newSingleThreadExecutor();
            try {
                Future<Void> cancellation = executor.submit(() -> {
                    statement.execute(cancelSql);
                    return null;
                });
                Thread.sleep(150);
                statement.cancel();
                try {
                    cancellation.get(5, TimeUnit.SECONDS);
                    fail("Expected cancel/abort path to surface an error");
                } catch (ExecutionException ex) {
                    assertTrue(ex.getCause() instanceof SQLException);
                } catch (TimeoutException ex) {
                    fail("Cancellation scenario timed out waiting for cancellation completion", ex);
                }
            } finally {
                executor.shutdownNow();
            }
        }

        try (Connection verify = openConnection(dsn);
             Statement verifyStatement = verify.createStatement();
             ResultSet rs = verifyStatement.executeQuery("SELECT 1")) {
            assertTrue(rs.next());
            assertEquals(1, rs.getInt(1));
        }

        SBConnectionPool.PoolStats after = poolStats(dsn);
        assertNotNull(after);
        assertTrue(after.hits + after.misses >= before.hits + before.misses);
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void scenarioB_timeoutCancellationReuse() throws Exception {
        String dsn = pooledDsn("MaxPoolSize=4&MinPoolSize=0&ConnectionLifetime=30");
        String cancelSql = System.getenv("SCRATCHBIRD_JDBC_CANCEL_SQL");
        assumeTrue(cancelSql != null && !cancelSql.isBlank(), "SCRATCHBIRD_JDBC_CANCEL_SQL is not set");

        try (Connection conn = openConnection(dsn);
             Statement statement = conn.createStatement()) {
            statement.setQueryTimeout(1);
            assertThrows(SQLException.class, () -> statement.execute(cancelSql));
        }

        try (Connection verify = openConnection(dsn);
             Statement verifyStatement = verify.createStatement();
             ResultSet rs = verifyStatement.executeQuery("SELECT 1")) {
            assertTrue(rs.next());
            assertEquals(1, rs.getInt(1));
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void scenarioC_concurrentPoolStress_10Workers() throws Exception {
        String dsn = pooledDsn("MaxPoolSize=3&MinPoolSize=0&ConnectionLifetime=20");
        ExecutorService executor = Executors.newFixedThreadPool(SCENARIO_C_WORKERS);

        try {
            List<Future<Boolean>> tasks = new ArrayList<>();
            for (int i = 0; i < SCENARIO_C_WORKERS; i++) {
                tasks.add(executor.submit(() -> {
                    try (Connection conn = openConnection(dsn);
                         Statement statement = conn.createStatement()) {
                        try (ResultSet rs = statement.executeQuery("SELECT 1")) {
                            return rs.next() && rs.getInt(1) == 1;
                        }
                    }
                }));
            }

            for (Future<Boolean> task : tasks) {
                assertTrue(task.get(8, TimeUnit.SECONDS), "worker task did not return success");
            }
        } finally {
            executor.shutdownNow();
            assertTrue(executor.awaitTermination(5, TimeUnit.SECONDS));
        }

        SBConnectionPool.PoolStats stats = poolStats(dsn);
        assertNotNull(stats);
        assertTrue(stats.total <= 3);
        assertTrue(stats.hits + stats.misses >= SCENARIO_C_WORKERS);
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void scenarioD_reconnectRecoveryAfterFailure() throws Exception {
        String dsn = pooledDsn("MaxPoolSize=2&MinPoolSize=0&ConnectionLifetime=30");
        String cancelSql = System.getenv("SCRATCHBIRD_JDBC_CANCEL_SQL");
        assumeTrue(cancelSql != null && !cancelSql.isBlank(), "SCRATCHBIRD_JDBC_CANCEL_SQL is not set");

        for (int iteration = 0; iteration < 2; iteration++) {
            try (Connection conn = openConnection(dsn);
                 Statement statement = conn.createStatement()) {
                statement.setQueryTimeout(1);
                assertThrows(SQLException.class, () -> statement.execute(cancelSql));
            }
        }

        try (Connection verify = openConnection(dsn);
             Statement verifyStatement = verify.createStatement();
             ResultSet rs = verifyStatement.executeQuery("SELECT 1")) {
            assertTrue(rs.next());
            assertEquals(1, rs.getInt(1));
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void scenarioE_metadataAndLobReuseAfterRecovery() throws Exception {
        String dsn = pooledDsn("MaxPoolSize=4&MinPoolSize=0&ConnectionLifetime=30");
        String cancelSql = System.getenv("SCRATCHBIRD_JDBC_CANCEL_SQL");
        assumeTrue(cancelSql != null && !cancelSql.isBlank(), "SCRATCHBIRD_JDBC_CANCEL_SQL is not set");

        String table = "jdbc203_contract_" + UUID.randomUUID().toString().replace("-", "");
        String payloadText = "payload-" + System.currentTimeMillis();

        try (Connection conn = openConnection(dsn);
             Statement statement = conn.createStatement()) {
            statement.execute("CREATE TABLE " + table + " (id INTEGER, note TEXT)");
            try (PreparedStatement insert = conn.prepareStatement(
                "INSERT INTO " + table + " (id, note) VALUES (?, ?)")) {
                insert.setInt(1, 1);
                insert.setObject(2, payloadText, Types.CLOB);
                assertEquals(1, insert.executeUpdate());
            }
        }

        try (Connection verify = openConnection(dsn);
             Statement statement = verify.createStatement()) {
            statement.setQueryTimeout(1);
            assertThrows(SQLException.class, () -> statement.execute(cancelSql));

            DatabaseMetaData metadata = verify.getMetaData();
            try (ResultSet columns = metadata.getColumns(null, null, table, "%")) {
                assertTrue(columns.next());
                assertEquals("ID", columns.getString("COLUMN_NAME").toUpperCase());
            }

            try (PreparedStatement stmt = verify.prepareStatement("SELECT note FROM " + table + " WHERE id = ?")) {
                stmt.setInt(1, 1);
                try (ResultSet rs = stmt.executeQuery()) {
                    assertTrue(rs.next());
                    assertEquals(payloadText, rs.getString(1));
                }
            }
        }

        try (Connection cleanup = openConnection(dsn);
             Statement cleanupStatement = cleanup.createStatement()) {
            cleanupStatement.execute("DROP TABLE " + table);
        }
    }

    private static String pooledDsn(String extraQuery) throws Exception {
        String url = System.getenv("SCRATCHBIRD_JDBC_URL");
        assumeTrue(url != null && !url.isBlank(), "SCRATCHBIRD_JDBC_URL is not set");
        if (url.contains("?")) {
            return url + "&Pooling=true&" + extraQuery;
        }

        return url + "?Pooling=true&" + extraQuery;
    }

    private static Connection openConnection(String dsn) throws Exception {
        String user = System.getenv("SCRATCHBIRD_JDBC_USER");
        String password = System.getenv("SCRATCHBIRD_JDBC_PASSWORD");
        if (user != null && password != null) {
            return DriverManager.getConnection(dsn, user, password);
        }
        return DriverManager.getConnection(dsn);
    }

    private static SBConnectionProperties parseProperties(String dsn) throws Exception {
        Properties properties = new Properties();
        String user = System.getenv("SCRATCHBIRD_JDBC_USER");
        String password = System.getenv("SCRATCHBIRD_JDBC_PASSWORD");
        if (user != null) {
            properties.setProperty("user", user);
        }
        if (password != null) {
            properties.setProperty("password", password);
        }
        return SBDriver.parseURL(dsn, properties);
    }

    private static SBConnectionPool.PoolStats poolStats(String dsn) throws Exception {
        SBConnectionProperties properties = parseProperties(dsn);
        return SBDriver.getPoolStats(properties);
    }
}
