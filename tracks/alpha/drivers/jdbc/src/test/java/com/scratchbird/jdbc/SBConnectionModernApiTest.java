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
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Field;
import java.sql.ShardingKey;
import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.Test;
import sun.misc.Unsafe;

class SBConnectionModernApiTest {

    @Test
    void supportsRequestScopeAndShardingKeySetters() throws Exception {
        SBConnection connection = newConnectionForTest();
        ShardingKey shard = new ShardingKey() {};
        ShardingKey superShard = new ShardingKey() {};

        connection.beginRequest();
        assertTrue((Boolean) getField(connection, "requestScopeActive"));
        connection.endRequest();
        assertFalse((Boolean) getField(connection, "requestScopeActive"));

        assertTrue(connection.setShardingKeyIfValid(shard, 1));
        assertEquals(shard, getField(connection, "shardingKey"));
        assertNull(getField(connection, "superShardingKey"));

        assertTrue(connection.setShardingKeyIfValid(shard, superShard, 0));
        assertEquals(shard, getField(connection, "shardingKey"));
        assertEquals(superShard, getField(connection, "superShardingKey"));

        assertFalse(connection.setShardingKeyIfValid(null, 2));
        assertFalse(connection.setShardingKeyIfValid(null, superShard, 2));

        connection.setShardingKey(shard);
        assertEquals(shard, getField(connection, "shardingKey"));
        assertNull(getField(connection, "superShardingKey"));

        connection.setShardingKey(shard, superShard);
        assertEquals(shard, getField(connection, "shardingKey"));
        assertEquals(superShard, getField(connection, "superShardingKey"));
    }

    @Test
    void rejectsInvalidShardingArguments() throws Exception {
        SBConnection connection = newConnectionForTest();
        ShardingKey shard = new ShardingKey() {};

        SQLException timeoutSingle = assertThrows(SQLException.class,
            () -> connection.setShardingKeyIfValid(shard, -1));
        assertEquals("HY024", timeoutSingle.getSQLState());

        SQLException timeoutComposite = assertThrows(SQLException.class,
            () -> connection.setShardingKeyIfValid(shard, new ShardingKey() {}, -1));
        assertEquals("HY024", timeoutComposite.getSQLState());

        SQLException nullSingle = assertThrows(SQLException.class,
            () -> connection.setShardingKey((ShardingKey) null));
        assertEquals("HY024", nullSingle.getSQLState());

        SQLException nullComposite = assertThrows(SQLException.class,
            () -> connection.setShardingKey((ShardingKey) null, new ShardingKey() {}));
        assertEquals("HY024", nullComposite.getSQLState());
    }

    private static SBConnection newConnectionForTest() throws Exception {
        SBConnection connection = (SBConnection) getUnsafe().allocateInstance(SBConnection.class);
        setField(connection, "properties", new SBConnectionProperties());
        setField(connection, "closed", new AtomicBoolean(false));
        setField(connection, "circuitBreaker", new CircuitBreaker());
        setField(connection, "telemetry", new TelemetryCollector());
        setField(connection, "requestScopeActive", false);
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

    private static Object getField(Object object, String fieldName) throws Exception {
        Field field = SBConnection.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        return field.get(object);
    }
}
