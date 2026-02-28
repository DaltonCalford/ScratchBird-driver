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
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.SQLTimeoutException;
import java.sql.SQLWarning;
import java.sql.Statement;
import java.sql.Types;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertThrows;

public class SBIntegrationTest {

    private SBIntegrationRuntime.RuntimeConfig runtime() {
        return SBIntegrationRuntime.requireRuntime();
    }

    private Connection openConnection() throws Exception {
        return runtime().openConnection();
    }

    @Test
    public void connectsAndRunsQuery() throws Exception {
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT 1")) {
            rs.next();
            assertEquals(1, rs.getInt(1));
        }
    }

    @Test
    public void connectsWithBinaryTransferDisabledAndCompressionOption() throws Exception {
        String base = runtime().baseUrl();
        String dsn = base + (base.contains("?") ? "&" : "?") + "binary_transfer=false&compression=zstd";
        try (Connection conn = runtime().openConnection(dsn);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT 1")) {
            assertTrue(rs.next());
            assertEquals(1, rs.getInt(1));

            SQLWarning warning = conn.getWarnings();
            if (warning != null) {
                StringBuilder warnings = new StringBuilder();
                while (warning != null) {
                    if (warnings.length() > 0) {
                        warnings.append(" | ");
                    }
                    warnings.append(warning.getMessage());
                    warning = warning.getNextWarning();
                }
                String allWarnings = warnings.toString();
                assertTrue(allWarnings.contains("compression")
                    || allWarnings.contains("binary_transfer"));
            }
        }
    }

    @Test
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
    public void typesFixtureQuery() throws Exception {
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM type_coverage")) {
            assertEquals(true, rs.next());
        }
    }

    @Test
    public void cancelQuery() throws Exception {
        String cancelSql = runtime().cancelSql();
        assertNotNull(cancelSql, "Cancel SQL must be configured by integration runtime");
        assertFalse(cancelSql.isEmpty(), "Cancel SQL must be configured by integration runtime");
        ExecutorService executor = Executors.newSingleThreadExecutor();
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement()) {
            Future<Boolean> future = executor.submit(() -> stmt.execute(cancelSql));
            Thread.sleep(200);
            stmt.cancel();
            try {
                future.get();
            } catch (ExecutionException ex) {
                assertTrue(ex.getCause() instanceof SQLException);
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
    public void metadataClientInfoPropertiesExposeDriverHints() throws Exception {
        try (Connection conn = openConnection()) {
            DatabaseMetaData metadata = conn.getMetaData();
            Map<String, Integer> maxLenByProperty = new HashMap<>();
            try (ResultSet rs = metadata.getClientInfoProperties()) {
                while (rs.next()) {
                    maxLenByProperty.put(rs.getString("NAME"), rs.getInt("MAX_LEN"));
                    assertNotNull(rs.getString("DESCRIPTION"));
                }
            }
            assertTrue(maxLenByProperty.containsKey("ApplicationName"));
            assertTrue(maxLenByProperty.containsKey("ClientUser"));
            assertTrue(maxLenByProperty.containsKey("ClientHostname"));
            assertTrue(maxLenByProperty.containsKey("ClientPid"));
            assertTrue(maxLenByProperty.containsKey("TraceTag"));
        }
    }

    @Test
    public void metadataUdtAndTypeMetadataMethodsReturnExpectedColumns() throws Exception {
        String domainName = "jdbc_udt_" + System.currentTimeMillis();
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement()) {
            try {
                stmt.execute("CREATE DOMAIN " + domainName + " INTEGER");
            } catch (SQLException ex) {
                // If domain DDL is not available in this environment, still validate metadata shape.
            }

            DatabaseMetaData metadata = conn.getMetaData();
            try (ResultSet udts = metadata.getUDTs(null, null, "%", null)) {
                assertMetadataColumns(udts,
                    "TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "CLASS_NAME", "DATA_TYPE",
                    "REMARKS", "BASE_TYPE");
            }

            try (ResultSet superTypes = metadata.getSuperTypes(null, null, "%")) {
                assertMetadataColumns(superTypes,
                    "TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "SUPERTYPE_CAT", "SUPERTYPE_SCHEM",
                    "SUPERTYPE_NAME");
            }

            try (ResultSet attributes = metadata.getAttributes(null, null, "%", "%")) {
                assertMetadataColumns(attributes,
                    "TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "ATTR_NAME", "DATA_TYPE",
                    "ATTR_TYPE_NAME", "ATTR_SIZE", "DECIMAL_DIGITS", "NUM_PREC_RADIX", "NULLABLE",
                    "REMARKS", "ATTR_DEF", "SQL_DATA_TYPE", "SQL_DATETIME_SUB", "CHAR_OCTET_LENGTH",
                    "ORDINAL_POSITION", "IS_NULLABLE", "SCOPE_CATALOG", "SCOPE_SCHEMA", "SCOPE_TABLE",
                    "SOURCE_DATA_TYPE");
            }

            try (ResultSet superTables = metadata.getSuperTables(null, null, "%")) {
                assertMetadataColumns(superTables,
                    "TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "SUPERTABLE_NAME");
            }

            try (ResultSet pseudoColumns = metadata.getPseudoColumns(null, null, "%", "%")) {
                assertMetadataColumns(pseudoColumns,
                    "TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "COLUMN_NAME", "DATA_TYPE",
                    "COLUMN_SIZE", "DECIMAL_DIGITS", "NUM_PREC_RADIX", "COLUMN_USAGE",
                    "REMARKS", "CHAR_OCTET_LENGTH", "IS_NULLABLE");
            }

            try {
                stmt.execute("DROP DOMAIN " + domainName);
            } catch (SQLException ex) {
                // Ignore cleanup failures after partial environments; next tests should manage independently.
            }
        }
    }

    @Test
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
    public void largeBlobRoundTripViaPreparedStatement() throws Exception {
        final int payloadSize = 128 * 1024;
        var expected = new byte[payloadSize];
        for (int i = 0; i < expected.length; i++)
        {
            expected[i] = (byte) ('a' + (i % 26));
        }

        try (Connection conn = openConnection();
             PreparedStatement stmt = conn.prepareStatement("SELECT CAST(? AS BYTEA)")) {
            stmt.setBytes(1, expected);
            try (ResultSet rs = stmt.executeQuery()) {
                assertTrue(rs.next());
                byte[] actual = normalizeBytea(rs.getBytes(1));
                assertEquals(expected.length, actual.length);
                assertArrayEquals(expected, actual);
                byte[] streamed = normalizeBytea(rs.getBinaryStream(1).readAllBytes());
                assertEquals(expected.length, streamed.length);
                assertArrayEquals(expected, streamed);
            }
        }
    }

    @Test
    public void largeCharacterLobRoundTripViaPreparedStatement() throws Exception {
        final int charCount = 128 * 1024;
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
    public void queryTimeoutReleasesConnection() throws Exception {
        String cancelSql = runtime().cancelSql();
        assertNotNull(cancelSql, "Cancel SQL must be configured by integration runtime");
        assertFalse(cancelSql.isEmpty(), "Cancel SQL must be configured by integration runtime");
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement()) {
            stmt.setQueryTimeout(1);
            try {
                stmt.execute(cancelSql);
            } catch (SQLException ignored) {
                // Runtime-specific cancellation path may either complete or surface timeout/cancel exceptions.
            }

            try (Statement verify = conn.createStatement();
                 ResultSet verifyRs = verify.executeQuery("SELECT 1")) {
                verifyRs.next();
                assertEquals(1, verifyRs.getInt(1));
            }
        }
    }

    @Test
    public void executeAsyncCancellationAndReuse() throws Exception {
        String cancelSql = runtime().cancelSql();
        assertNotNull(cancelSql, "Cancel SQL must be configured by integration runtime");
        assertFalse(cancelSql.isEmpty(), "Cancel SQL must be configured by integration runtime");
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
    public void executeAsyncTimeoutAndContentionKeepsConnectionUsable() throws Exception {
        String cancelSql = runtime().cancelSql();
        assertNotNull(cancelSql, "Cancel SQL must be configured by integration runtime");
        assertFalse(cancelSql.isEmpty(), "Cancel SQL must be configured by integration runtime");
        try (Connection conn = openConnection();
             Statement statement = conn.createStatement()) {
            SBStatement stmt = (SBStatement) statement;
            stmt.setQueryTimeout(1);

            CompletableFuture<Boolean> timedOut = stmt.executeAsync(cancelSql);
            CompletableFuture<Boolean> queued = stmt.executeAsync("SELECT 1");

            try {
                timedOut.get(5, TimeUnit.SECONDS);
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

    @Test
    public void selectForUpdateWorksInTransaction() throws Exception {
        String table = "jdbc_for_update_" + System.currentTimeMillis();
        try (Connection conn = openConnection();
             Statement stmt = conn.createStatement()) {
            stmt.execute("CREATE TABLE " + table + " (id INTEGER PRIMARY KEY, note TEXT)");
            stmt.execute("INSERT INTO " + table + " (id, note) VALUES (1, 'a')");
            conn.setAutoCommit(false);
            try {
                try (ResultSet rs = stmt.executeQuery(
                    "SELECT id, note FROM " + table + " WHERE id = 1 FOR UPDATE")) {
                    assertTrue(rs.next());
                    assertEquals(1, rs.getInt(1));
                    assertEquals("a", rs.getString(2));
                }
                stmt.executeUpdate("UPDATE " + table + " SET note = 'b' WHERE id = 1");
                conn.rollback();
            } finally {
                conn.setAutoCommit(true);
            }
            stmt.execute("DROP TABLE IF EXISTS " + table);
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

    private byte[] normalizeBytea(byte[] value) {
        if (value == null || value.length == 0) {
            return value;
        }
        byte[] normalized = value;
        for (int pass = 0; pass < 3; pass++) {
            byte[] decoded = tryDecodeByteaText(normalized);
            if (decoded == null || decoded.length == normalized.length) {
                break;
            }
            normalized = decoded;
        }
        return normalized;
    }

    private byte[] tryDecodeByteaText(byte[] value) {
        String text = new String(value, StandardCharsets.ISO_8859_1);
        String hex = null;
        if (text.startsWith("\\x") || text.startsWith("0x")) {
            hex = text.substring(2);
        } else if ((text.length() & 1) == 0 && text.matches("(?i)[0-9a-f]+")) {
            hex = text;
        }
        if (hex != null) {
            byte[] out = new byte[hex.length() / 2];
            for (int i = 0; i < out.length; i++) {
                out[i] = (byte) Integer.parseInt(hex.substring(i * 2, i * 2 + 2), 16);
            }
            return out;
        }
        if (text.indexOf('\\') >= 0) {
            ByteArrayOutputStream out = new ByteArrayOutputStream(text.length());
            int i = 0;
            while (i < text.length()) {
                char ch = text.charAt(i);
                if (ch != '\\') {
                    out.write((byte) ch);
                    i++;
                    continue;
                }
                if (i + 1 >= text.length()) {
                    out.write((byte) '\\');
                    break;
                }
                char n1 = text.charAt(i + 1);
                if (n1 == '\\') {
                    out.write((byte) '\\');
                    i += 2;
                    continue;
                }
                if (i + 3 < text.length()
                    && n1 >= '0' && n1 <= '7'
                    && text.charAt(i + 2) >= '0' && text.charAt(i + 2) <= '7'
                    && text.charAt(i + 3) >= '0' && text.charAt(i + 3) <= '7') {
                    int parsed = ((n1 - '0') << 6)
                        | ((text.charAt(i + 2) - '0') << 3)
                        | (text.charAt(i + 3) - '0');
                    out.write((byte) parsed);
                    i += 4;
                    continue;
                }
                out.write((byte) n1);
                i += 2;
            }
            return out.toByteArray();
        }
        return null;
    }
}
