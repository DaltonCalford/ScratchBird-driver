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
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Field;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import sun.misc.Unsafe;

import org.junit.jupiter.api.Test;

class SBCallableStatementEscapeSyntaxTest {

    @Test
    void procedureEscapeSyntaxRewritesToCall() throws Exception {
        CaptureProtocol protocol = new CaptureProtocol();
        SBConnection connection = newConnectionForTest(protocol);
        SBCallableStatement statement = new SBCallableStatement(connection,
            "{call demo_proc(?, ?)}",
            ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY,
            ResultSet.HOLD_CURSORS_OVER_COMMIT);

        statement.setInt(1, 11);
        statement.setString(2, "ok");

        boolean hasResultSet = statement.execute();

        assertFalse(hasResultSet);
        assertTrue(protocol.lastSql.startsWith("CALL demo_proc("));
        assertEquals(2, protocol.lastParams.size());
        assertEquals(11, protocol.lastParams.get(0));
        assertEquals("ok", protocol.lastParams.get(1));
    }

    @Test
    void functionEscapeSyntaxMapsReturnValueAndInputParameters() throws Exception {
        CaptureProtocol protocol = new CaptureProtocol();
        protocol.functionResult = 77;
        SBConnection connection = newConnectionForTest(protocol);
        SBCallableStatement statement = new SBCallableStatement(connection,
            "{? = call demo_fn(?)}",
            ResultSet.TYPE_FORWARD_ONLY,
            ResultSet.CONCUR_READ_ONLY,
            ResultSet.HOLD_CURSORS_OVER_COMMIT);

        statement.registerOutParameter(1, Types.INTEGER);
        assertThrows(SQLException.class, () -> statement.setInt(1, 99));
        statement.setInt(2, 41);

        boolean hasResultSet = statement.execute();

        assertTrue(hasResultSet);
        assertTrue(protocol.lastSql.startsWith("SELECT demo_fn("));
        assertEquals(1, protocol.lastParams.size());
        assertEquals(41, protocol.lastParams.get(0));
        assertEquals(77, statement.getInt(1));
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

    private static final class CaptureProtocol extends SBProtocolHandler {
        String lastSql;
        List<Object> lastParams = Collections.emptyList();
        int functionResult = 0;

        CaptureProtocol() {
            super(new SBConnectionProperties());
        }

        @Override
        public SBQueryResult execute(String sql, List<Object> params, List<Integer> paramTypes,
                                     int maxRows, int timeoutMs) {
            this.lastSql = sql;
            this.lastParams = new ArrayList<>(params);

            SBQueryResult result = new SBQueryResult();
            if (sql != null && sql.trim().toUpperCase().startsWith("SELECT")) {
                SBColumnInfo out = new SBColumnInfo();
                out.setName("return_value");
                result.setColumns(Collections.singletonList(out));
                result.setRows(Collections.singletonList(new Object[] {functionResult}));
                result.setUpdateCount(0);
            } else {
                result.setColumns(Collections.emptyList());
                result.setRows(Collections.emptyList());
                result.setUpdateCount(1);
            }
            return result;
        }
    }
}
