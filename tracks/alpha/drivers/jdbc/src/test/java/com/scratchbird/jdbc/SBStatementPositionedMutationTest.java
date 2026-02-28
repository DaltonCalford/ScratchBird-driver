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
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Field;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.Test;
import sun.misc.Unsafe;

class SBStatementPositionedMutationTest {

    @Test
    void rewritesPositionedUpdateUsingNamedCursor() throws Exception {
        CaptureProtocol protocol = new CaptureProtocol();
        SBConnection connection = newConnectionForTest(protocol);
        SBResultSet cursor = createNamedCursor(connection, "SELECT id, note FROM demo", "c_demo",
            new Object[] {1, "old"});

        SBStatement statement = new SBStatement(connection, ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY, ResultSet.CLOSE_CURSORS_AT_COMMIT);
        long count = statement.executeLargeUpdate("UPDATE demo SET note = 'new' WHERE CURRENT OF c_demo");

        assertEquals(1L, count);
        assertEquals(1, protocol.executedSql.size());
        String rewritten = protocol.executedSql.get(0);
        assertTrue(rewritten.startsWith("UPDATE demo SET note = 'new' WHERE"));
        assertTrue(rewritten.contains("\"id\" = 1"));
        assertTrue(rewritten.contains("\"note\" = 'old'"));

        cursor.close();
    }

    @Test
    void rewritesPositionedDeleteUsingNamedCursor() throws Exception {
        CaptureProtocol protocol = new CaptureProtocol();
        SBConnection connection = newConnectionForTest(protocol);
        SBResultSet cursor = createNamedCursor(connection, "SELECT id, note FROM demo", "c_delete",
            new Object[] {2, "remove"});

        SBStatement statement = new SBStatement(connection, ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY, ResultSet.CLOSE_CURSORS_AT_COMMIT);
        int count = statement.executeUpdate("DELETE FROM demo WHERE CURRENT OF c_delete");

        assertEquals(1, count);
        assertEquals(1, protocol.executedSql.size());
        String rewritten = protocol.executedSql.get(0);
        assertTrue(rewritten.startsWith("DELETE FROM demo WHERE"));
        assertTrue(rewritten.contains("\"id\" = 2"));
        assertTrue(rewritten.contains("\"note\" = 'remove'"));

        cursor.close();
    }

    @Test
    void positionedMutationFailsWhenCursorMissing() throws Exception {
        CaptureProtocol protocol = new CaptureProtocol();
        SBConnection connection = newConnectionForTest(protocol);
        SBStatement statement = new SBStatement(connection, ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY, ResultSet.CLOSE_CURSORS_AT_COMMIT);

        SQLException ex = assertThrows(SQLException.class,
            () -> statement.executeUpdate("DELETE FROM demo WHERE CURRENT OF missing_cursor"));
        assertEquals("34000", ex.getSQLState());
    }

    @Test
    void positionedMutationFailsWhenTargetTableDiffers() throws Exception {
        CaptureProtocol protocol = new CaptureProtocol();
        SBConnection connection = newConnectionForTest(protocol);
        SBResultSet cursor = createNamedCursor(connection, "SELECT id, note FROM demo", "c_demo",
            new Object[] {1, "old"});
        SBStatement statement = new SBStatement(connection, ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY, ResultSet.CLOSE_CURSORS_AT_COMMIT);

        SQLException ex = assertThrows(SQLException.class,
            () -> statement.executeUpdate("UPDATE other_table SET note = 'x' WHERE CURRENT OF c_demo"));
        assertEquals("34000", ex.getSQLState());
        cursor.close();
    }

    private static SBResultSet createNamedCursor(SBConnection connection, String sql,
                                                 String cursorName, Object[] row) throws Exception {
        SBStatement cursorStatement = new SBStatement(connection, ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.CONCUR_UPDATABLE, ResultSet.CLOSE_CURSORS_AT_COMMIT);
        cursorStatement.lastExecutedSql = sql;
        cursorStatement.setCursorName(cursorName);

        List<SBColumnInfo> columns = new ArrayList<>();
        SBColumnInfo id = new SBColumnInfo();
        id.setName("id");
        columns.add(id);
        SBColumnInfo note = new SBColumnInfo();
        note.setName("note");
        columns.add(note);

        SBResultSet resultSet = new SBResultSet(cursorStatement, columns,
            new ArrayList<>(Collections.singletonList(row.clone())));
        assertTrue(resultSet.next());
        connection.registerNamedCursor(cursorName, resultSet);
        return resultSet;
    }

    private static SBConnection newConnectionForTest(SBProtocolHandler protocol) throws Exception {
        SBConnection connection = (SBConnection) getUnsafe().allocateInstance(SBConnection.class);
        setField(connection, "protocol", protocol);
        setField(connection, "properties", new SBConnectionProperties());
        setField(connection, "closed", new AtomicBoolean(false));
        setField(connection, "circuitBreaker", new CircuitBreaker());
        setField(connection, "telemetry", new TelemetryCollector());
        setField(connection, "namedCursors", new HashMap<String, SBResultSet>());
        setField(connection, "readOnly", false);
        setField(connection, "autoCommit", true);
        setField(connection, "schema", "public");
        return connection;
    }

    private static Unsafe getUnsafe() throws Exception {
        Field field = Unsafe.class.getDeclaredField("theUnsafe");
        field.setAccessible(true);
        return (Unsafe) field.get(null);
    }

    private static void setField(Object object, String fieldName, Object value) throws Exception {
        Field field = SBConnection.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(object, value);
    }

    private static final class CaptureProtocol extends SBProtocolHandler {
        private final List<String> executedSql = new ArrayList<>();

        CaptureProtocol() {
            super(new SBConnectionProperties());
        }

        @Override
        public synchronized SBQueryResult execute(String sql) throws SQLException {
            return execute(sql, 0, 0);
        }

        @Override
        public synchronized SBQueryResult execute(String sql, int maxRows, int timeoutMs) throws SQLException {
            executedSql.add(sql);
            SBQueryResult result = new SBQueryResult();
            result.setUpdateCount(1);
            return result;
        }
    }
}
