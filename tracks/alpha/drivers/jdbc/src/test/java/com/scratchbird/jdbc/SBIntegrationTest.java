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
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.fail;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.SQLTimeoutException;
import java.sql.Statement;
import java.sql.Types;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import static org.junit.jupiter.api.Assertions.assertThrows;

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

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void metadataCatalogHasTablesAndColumns() throws Exception {
        try (Connection conn = openConnection()) {
            DatabaseMetaData metadata = conn.getMetaData();

            try (ResultSet tables = metadata.getTables(null, null, "%", new String[]{"TABLE"})) {
                assertTrue(tables.next());
                assertNotNull(tables.getString("TABLE_NAME"));
            }

            try (ResultSet columns = metadata.getColumns(null, null, "type_coverage", "%")) {
                assertTrue(columns.next());
            }

            try (ResultSet tables = metadata.getTables(null, null, "%", null)) {
                assertTrue(tables.next());
                assertMetadataColumns(tables, "TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "TABLE_TYPE", "REMARKS", "TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "SELF_REFERENCING_COL_NAME", "REF_GENERATION");
            }
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void preparedStatementReplayAfterSchemaRecreate() throws Exception {
        String table = "jdbc_stmt_replay_" + System.currentTimeMillis();

        try (Connection conn = openConnection();
             Statement setup = conn.createStatement()) {
            setup.execute("CREATE TABLE " + table + " (id INTEGER)");

            try (PreparedStatement stmt = conn.prepareStatement("SELECT COUNT(*) FROM " + table + " WHERE id = ?")) {
                stmt.setInt(1, 1);
                try (ResultSet rs = stmt.executeQuery()) {
                    assertTrue(rs.next());
                    assertEquals(0, rs.getInt(1));
                }

                setup.execute("DROP TABLE " + table);
                setup.execute("CREATE TABLE " + table + " (id INTEGER, note TEXT)");

                try (Statement insert = conn.createStatement()) {
                    insert.execute("INSERT INTO " + table + " (id, note) VALUES (1, 'x')");
                }

                stmt.setInt(1, 1);
                try (ResultSet rs = stmt.executeQuery()) {
                    assertTrue(rs.next());
                    assertEquals(1, rs.getInt(1));
                }
            }

            setup.execute("DROP TABLE IF EXISTS " + table);
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void metadataRoutinesAndFunctionsExposeExpectedColumns() throws Exception {
        try (Connection conn = openConnection()) {
            DatabaseMetaData metadata = conn.getMetaData();

            try (ResultSet procedures = metadata.getProcedures(null, null, "%")) {
                assertMetadataColumns(procedures, "PROCEDURE_CAT", "PROCEDURE_SCHEM", "PROCEDURE_NAME",
                    "RESERVED1", "RESERVED2", "RESERVED3", "REMARKS", "PROCEDURE_TYPE",
                    "SPECIFIC_NAME");
            }

            try (ResultSet procedureColumns = metadata.getProcedureColumns(null, null, "%", "%")) {
                assertMetadataColumns(procedureColumns,
                    "PROCEDURE_CAT", "PROCEDURE_SCHEM", "PROCEDURE_NAME", "COLUMN_NAME",
                    "COLUMN_TYPE", "DATA_TYPE", "TYPE_NAME", "PRECISION", "LENGTH", "SCALE",
                    "RADIX", "NULLABLE", "REMARKS", "COLUMN_DEF", "SQL_DATA_TYPE",
                    "SQL_DATETIME_SUB", "CHAR_OCTET_LENGTH", "ORDINAL_POSITION", "IS_NULLABLE",
                    "SPECIFIC_NAME");
            }

            try (ResultSet functions = metadata.getFunctions(null, null, "%")) {
                assertMetadataColumns(functions,
                    "FUNCTION_CAT", "FUNCTION_SCHEM", "FUNCTION_NAME", "REMARKS",
                    "FUNCTION_TYPE", "SPECIFIC_NAME");
            }

            try (ResultSet functionColumns = metadata.getFunctionColumns(null, null, "%", "%")) {
                assertMetadataColumns(functionColumns,
                    "FUNCTION_CAT", "FUNCTION_SCHEM", "FUNCTION_NAME", "COLUMN_NAME", "COLUMN_TYPE",
                    "DATA_TYPE", "TYPE_NAME", "PRECISION", "LENGTH", "SCALE", "RADIX",
                    "NULLABLE", "REMARKS", "CHAR_OCTET_LENGTH", "ORDINAL_POSITION",
                    "IS_NULLABLE", "SPECIFIC_NAME");
            }
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void largeBlobRoundTripViaPreparedStatement() throws Exception {
        final int payloadSize = 6 * 1024 * 1024;
        var expected = new byte[payloadSize];
        for (int i = 0; i < expected.length; i++)
        {
            expected[i] = (byte) ((i * 7 + 5) & 0xFF);
        }

        try (Connection conn = openConnection();
             PreparedStatement stmt = conn.prepareStatement("SELECT CAST(? AS BYTEA)")) {
            stmt.setBytes(1, expected);
            try (ResultSet rs = stmt.executeQuery()) {
                assertTrue(rs.next());
                byte[] actual = rs.getBytes(1);
                assertEquals(expected.length, actual.length);
                assertEquals(expected, actual);
                long available = rs.getBinaryStream(1).available();
                assertEquals(expected.length, actual.length);
                assertEquals((long) expected.length, available);
            }
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void largeCharacterLobRoundTripViaPreparedStatement() throws Exception {
        final int charCount = 3 * 1024 * 1024;
        var builder = new StringBuilder(charCount);
        for (int i = 0; i < charCount; i++)
        {
            builder.append((char) ('a' + (i % 26)));
        }

        try (Connection conn = openConnection();
             PreparedStatement stmt = conn.prepareStatement("SELECT CAST(? AS TEXT)")) {
            stmt.setObject(1, builder.toString(), Types.CLOB);
            try (ResultSet rs = stmt.executeQuery()) {
                assertTrue(rs.next());
                String actual = rs.getString(1);
                assertEquals(builder.length(), actual.length());
                assertEquals(builder.toString(), actual);
            }
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void metadataCatalogFilterReturnsNoRowsWhenCatalogMismatched() throws Exception {
        try (Connection conn = openConnection()) {
            String currentCatalog = conn.getCatalog();
            if (currentCatalog == null || currentCatalog.isBlank()) {
                return;
            }

            DatabaseMetaData metadata = conn.getMetaData();
            try (ResultSet procedures = metadata.getProcedures("__does_not_exist__", null, "%")) {
                assertFalse(procedures.next());
            }

            try (ResultSet functions = metadata.getFunctions("__does_not_exist__", null, "%")) {
                assertFalse(functions.next());
            }
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void queryTimeoutReleasesConnection() throws Exception {
        String cancelSql = System.getenv("SCRATCHBIRD_JDBC_CANCEL_SQL");
        if (cancelSql == null || cancelSql.isEmpty()) {
            return;
        }
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement()) {
            stmt.setQueryTimeout(1);
            assertThrows(SQLException.class, () -> stmt.execute(cancelSql));

            try (Statement verify = conn.createStatement();
                 ResultSet verifyRs = verify.executeQuery("SELECT 1")) {
                verifyRs.next();
                assertEquals(1, verifyRs.getInt(1));
            }
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void executeAsyncCancellationAndReuse() throws Exception {
        String cancelSql = System.getenv("SCRATCHBIRD_JDBC_CANCEL_SQL");
        if (cancelSql == null || cancelSql.isEmpty()) {
            return;
        }
        try (Connection conn = openConnection();
             Statement statement = conn.createStatement()) {
            SBStatement stmt = (SBStatement) statement;
            CompletableFuture<Boolean> future = stmt.executeAsync(cancelSql);
            assertFalse(future.isDone());

            Thread.sleep(200);
            if (!future.cancel(true)) {
                assertNotNull(future.get(5, TimeUnit.SECONDS));
                return;
            }
            assertThrows(java.util.concurrent.CancellationException.class, future::join);

            try (Statement verify = conn.createStatement();
                 ResultSet verifyRs = verify.executeQuery("SELECT 1")) {
                verifyRs.next();
                assertEquals(1, verifyRs.getInt(1));
            }
        }
    }

    @Test
    @EnabledIfEnvironmentVariable(named = "SCRATCHBIRD_JDBC_URL", matches = ".*")
    public void executeAsyncTimeoutAndContentionKeepsConnectionUsable() throws Exception {
        String cancelSql = System.getenv("SCRATCHBIRD_JDBC_CANCEL_SQL");
        if (cancelSql == null || cancelSql.isEmpty()) {
            return;
        }
        try (Connection conn = openConnection();
             Statement statement = conn.createStatement()) {
            SBStatement stmt = (SBStatement) statement;
            stmt.setQueryTimeout(1);

            CompletableFuture<Boolean> timedOut = stmt.executeAsync(cancelSql);
            CompletableFuture<Boolean> queued = stmt.executeAsync("SELECT 1");

            try {
                timedOut.get(5, TimeUnit.SECONDS);
                fail("expected timeout to abort long async query");
            } catch (ExecutionException ex) {
                Throwable cause = ex.getCause();
                assertTrue(cause instanceof SQLTimeoutException || cause instanceof SQLException);
            }

            assertTrue(queued.get(8, TimeUnit.SECONDS));
            try (Statement verify = conn.createStatement();
                 ResultSet verifyRs = verify.executeQuery("SELECT 1")) {
                verifyRs.next();
                assertEquals(1, verifyRs.getInt(1));
            }
        }
    }

    private void assertMetadataColumns(ResultSet rs, String... expectedColumns) throws SQLException {
        ResultSetMetaData metaData = rs.getMetaData();
        assertEquals(expectedColumns.length, metaData.getColumnCount());
        for (int i = 0; i < expectedColumns.length; i++) {
            assertEquals(expectedColumns[i], metaData.getColumnLabel(i + 1),
                "column index " + (i + 1));
        }
    }
}
