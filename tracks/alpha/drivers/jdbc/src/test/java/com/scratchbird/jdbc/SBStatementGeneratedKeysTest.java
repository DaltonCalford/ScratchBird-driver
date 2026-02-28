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
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Field;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.List;
import java.util.Queue;
import sun.misc.Unsafe;

import org.junit.jupiter.api.Test;

public class SBStatementGeneratedKeysTest {

    @Test
    public void executeUpdateReturnGeneratedKeysPopulatesGeneratedKeysResultSet() throws Exception {
        QueueProtocol protocol = new QueueProtocol();
        protocol.enqueue(resultWithColumns(1, List.of("id"), java.util.Collections.singletonList(new Object[] {42L})));
        SBConnection connection = newConnectionForTest(protocol);
        SBStatement statement = new SBStatement(connection, ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY, ResultSet.CLOSE_CURSORS_AT_COMMIT);

        int updated = statement.executeUpdate("INSERT INTO demo(v) VALUES (1)", Statement.RETURN_GENERATED_KEYS);

        assertEquals(1, updated);
        assertTrue(protocol.lastSql.toUpperCase().contains("RETURNING *"));
        assertNull(statement.getResultSet());
        try (ResultSet keys = statement.getGeneratedKeys()) {
            assertTrue(keys.next());
            assertEquals(42L, keys.getLong(1));
            assertFalse(keys.next());
        }
    }

    @Test
    public void executeWithNamedGeneratedColumnsRoutesReturningRowsToGeneratedKeys() throws Exception {
        QueueProtocol protocol = new QueueProtocol();
        protocol.enqueue(resultWithColumns(1, List.of("id"), java.util.Collections.singletonList(new Object[] {7})));
        SBConnection connection = newConnectionForTest(protocol);
        SBStatement statement = new SBStatement(connection, ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY, ResultSet.CLOSE_CURSORS_AT_COMMIT);

        boolean hasResultSet = statement.execute("INSERT INTO demo(v) VALUES (2)", new String[] {"id"});

        assertFalse(hasResultSet);
        assertTrue(protocol.lastSql.toUpperCase().contains("RETURNING ID"));
        assertNull(statement.getResultSet());
        try (ResultSet keys = statement.getGeneratedKeys()) {
            assertTrue(keys.next());
            assertEquals(7, keys.getInt(1));
            assertFalse(keys.next());
        }
    }

    @Test
    public void executeSelectWithGeneratedKeysHintStillReturnsResultSet() throws Exception {
        QueueProtocol protocol = new QueueProtocol();
        protocol.enqueue(resultWithColumns(-1, List.of("value"), java.util.Collections.singletonList(new Object[] {5})));
        SBConnection connection = newConnectionForTest(protocol);
        SBStatement statement = new SBStatement(connection, ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY, ResultSet.CLOSE_CURSORS_AT_COMMIT);

        boolean hasResultSet = statement.execute("SELECT 5", Statement.RETURN_GENERATED_KEYS);

        assertTrue(hasResultSet);
        assertNotNull(statement.getResultSet());
        try (ResultSet rs = statement.getResultSet()) {
            assertTrue(rs.next());
            assertEquals(5, rs.getInt(1));
            assertFalse(rs.next());
        }
        try (ResultSet keys = statement.getGeneratedKeys()) {
            assertFalse(keys.next());
        }
    }

    private static SBConnection newConnectionForTest(SBProtocolHandler protocol) throws Exception {
        SBConnection connection = (SBConnection) getUnsafe().allocateInstance(SBConnection.class);
        setField(connection, "protocol", protocol);
        setField(connection, "properties", new SBConnectionProperties());
        setField(connection, "closed", new java.util.concurrent.atomic.AtomicBoolean(false));
        setField(connection, "circuitBreaker", new CircuitBreaker());
        setField(connection, "telemetry", new TelemetryCollector());
        setField(connection, "readOnly", false);
        setField(connection, "autoCommit", true);
        setField(connection, "schema", "public");
        return connection;
    }

    private static void setField(Object object, String fieldName, Object value) throws Exception {
        Field field = SBConnection.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(object, value);
    }

    private static Unsafe getUnsafe() throws Exception {
        Field field = Unsafe.class.getDeclaredField("theUnsafe");
        field.setAccessible(true);
        return (Unsafe) field.get(null);
    }

    private static SBQueryResult resultWithColumns(long updateCount, List<String> columnNames,
            List<Object[]> rows) {
        SBQueryResult result = new SBQueryResult();
        List<SBColumnInfo> columns = new ArrayList<>();
        for (String name : columnNames) {
            SBColumnInfo column = new SBColumnInfo();
            column.setName(name);
            columns.add(column);
        }
        result.setColumns(columns);
        result.setRows(rows);
        result.setUpdateCount(updateCount);
        return result;
    }

    private static final class QueueProtocol extends SBProtocolHandler {
        final Queue<SBQueryResult> results = new ArrayDeque<>();
        String lastSql;

        QueueProtocol() {
            super(new SBConnectionProperties());
        }

        void enqueue(SBQueryResult result) {
            results.add(result);
        }

        @Override
        public SBQueryResult execute(String sql, int maxRows, int timeoutMs) {
            this.lastSql = sql;
            SBQueryResult result = results.poll();
            if (result == null) {
                return new SBQueryResult();
            }
            return result;
        }
    }
}
