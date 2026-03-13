/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */
package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import org.junit.jupiter.api.Test;

class SBNativeSQLParityTest {

    private SBIntegrationRuntime.RuntimeConfig runtime() {
        return SBIntegrationRuntime.requireRuntime();
    }

    private Connection openConnection() throws Exception {
        String base = runtime().baseUrl();
        String dsn = base.contains("?") ? base + "&pooling=false" : base + "?pooling=false";
        return runtime().openConnection(dsn);
    }

    @Test
    void nativeSqlFunctionEscapeMatchesCanonicalExecution() throws Exception {
        try (Connection conn = openConnection()) {
            String converted = conn.nativeSQL("SELECT {fn UCASE('abc')}");
            assertEquals("SELECT UPPER('abc')", converted);

            Object viaNative = querySingleValue(conn, converted);
            Object viaCanonical = querySingleValue(conn, "SELECT UPPER('abc')");
            assertEquals(viaCanonical, viaNative);
        }
    }

    @Test
    void nativeSqlDateLiteralMatchesCanonicalExecution() throws Exception {
        try (Connection conn = openConnection()) {
            String converted = conn.nativeSQL("SELECT {d '2026-03-03'}");
            assertEquals("SELECT DATE '2026-03-03'", converted);

            Object viaNative = querySingleValue(conn, converted);
            Object viaCanonical = querySingleValue(conn, "SELECT DATE '2026-03-03'");
            assertEquals(viaCanonical, viaNative);
        }
    }

    private static Object querySingleValue(Connection conn, String sql) throws Exception {
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            assertTrue(rs.next(), "expected one row for SQL: " + sql);
            return rs.getObject(1);
        }
    }
}
