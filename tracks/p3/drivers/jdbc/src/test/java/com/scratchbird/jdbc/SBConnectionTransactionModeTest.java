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
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Field;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.Test;
import sun.misc.Unsafe;

class SBConnectionTransactionModeTest {

    @Test
    void setAutoCommitTrueSkipsCommitWhenNoActiveTransaction() throws Exception {
        TrackingProtocol protocol = new TrackingProtocol();
        protocol.activeTransaction = false;
        SBConnection connection = newConnectionForTest(protocol, false);

        connection.setAutoCommit(true);

        assertEquals(0, protocol.commitCalls);
        assertTrue(protocol.executedSql.stream().anyMatch(sql -> sql.equalsIgnoreCase("SET AUTOCOMMIT ON")));
        assertTrue(connection.getAutoCommit());
    }

    @Test
    void setAutoCommitTrueCommitsWhenActiveTransactionExists() throws Exception {
        TrackingProtocol protocol = new TrackingProtocol();
        protocol.activeTransaction = true;
        SBConnection connection = newConnectionForTest(protocol, false);

        connection.setAutoCommit(true);

        assertEquals(1, protocol.commitCalls);
        assertTrue(connection.getAutoCommit());
        assertFalse(protocol.activeTransaction);
    }

    @Test
    void setAutoCommitFalseDoesNotBeginWhenServerAlreadyHasTransaction() throws Exception {
        TrackingProtocol protocol = new TrackingProtocol();
        protocol.activeTransaction = true;
        SBConnection connection = newConnectionForTest(protocol, true);

        connection.setAutoCommit(false);

        assertEquals(0, protocol.beginCalls);
        assertFalse(connection.getAutoCommit());
    }

    @Test
    void commitAndRollbackAreNoOpsWhenNoActiveTransaction() throws Exception {
        TrackingProtocol protocol = new TrackingProtocol();
        protocol.activeTransaction = false;
        SBConnection connection = newConnectionForTest(protocol, false);

        connection.commit();
        connection.rollback();

        assertEquals(0, protocol.commitCalls);
        assertEquals(0, protocol.rollbackCalls);
    }

    private static SBConnection newConnectionForTest(SBProtocolHandler protocol, boolean autoCommit) throws Exception {
        SBConnection connection = (SBConnection) getUnsafe().allocateInstance(SBConnection.class);
        setField(connection, "protocol", protocol);
        setField(connection, "properties", new SBConnectionProperties());
        setField(connection, "closed", new AtomicBoolean(false));
        setField(connection, "circuitBreaker", new CircuitBreaker());
        setField(connection, "telemetry", new TelemetryCollector());
        setField(connection, "readOnly", false);
        setField(connection, "autoCommit", autoCommit);
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

    private static final class TrackingProtocol extends SBProtocolHandler {
        private final List<String> executedSql = new ArrayList<>();
        private int beginCalls;
        private int commitCalls;
        private int rollbackCalls;
        private boolean activeTransaction;

        TrackingProtocol() {
            super(new SBConnectionProperties());
        }

        @Override
        public synchronized SBQueryResult execute(String sql) throws SQLException {
            return execute(sql, 0, 0);
        }

        @Override
        public synchronized SBQueryResult execute(String sql, int maxRows, int timeoutMs) throws SQLException {
            executedSql.add(sql);
            return new SBQueryResult();
        }

        @Override
        public synchronized boolean hasActiveTransaction() {
            return activeTransaction;
        }

        @Override
        public synchronized void beginTransaction() throws SQLException {
            beginCalls++;
            activeTransaction = true;
        }

        @Override
        public synchronized void commitTransaction(byte flags) throws SQLException {
            commitCalls++;
            activeTransaction = false;
        }

        @Override
        public synchronized void rollbackTransaction(byte flags) throws SQLException {
            rollbackCalls++;
            activeTransaction = false;
        }
    }
}
