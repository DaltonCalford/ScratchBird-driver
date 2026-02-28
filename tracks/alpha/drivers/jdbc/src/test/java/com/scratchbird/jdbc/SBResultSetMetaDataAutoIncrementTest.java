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

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Field;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;
import sun.misc.Unsafe;

class SBResultSetMetaDataAutoIncrementTest {

    @Test
    void detectsAutoIncrementColumnsFromCatalogMetadata() throws Exception {
        AutoIncrementCatalogProtocol protocol = new AutoIncrementCatalogProtocol();
        SBConnection connection = newConnectionForTest(protocol);
        SBStatement statement = new SBStatement(connection, ResultSet.TYPE_SCROLL_INSENSITIVE,
            ResultSet.CONCUR_READ_ONLY, ResultSet.CLOSE_CURSORS_AT_COMMIT);
        statement.lastExecutedSql = "SELECT id, payload FROM public.demo";

        SBColumnInfo id = new SBColumnInfo();
        id.setName("id");
        id.setTableOid(878787);
        id.setColumnNumber((short) 1);

        SBColumnInfo payload = new SBColumnInfo();
        payload.setName("payload");
        payload.setTableOid(878787);
        payload.setColumnNumber((short) 2);

        SBResultSet rs = new SBResultSet(
            statement,
            Arrays.asList(id, payload),
            new ArrayList<>(Collections.singletonList(new Object[] {1, "alpha"}))
        );

        ResultSetMetaData meta = rs.getMetaData();
        assertTrue(meta.isAutoIncrement(1));
        assertFalse(meta.isAutoIncrement(2));
    }

    private static SBConnection newConnectionForTest(SBProtocolHandler protocol) throws Exception {
        SBConnection connection = (SBConnection) getUnsafe().allocateInstance(SBConnection.class);
        setField(connection, "protocol", protocol);
        SBConnectionProperties properties = new SBConnectionProperties();
        properties.setDatabase("main");
        setField(connection, "properties", properties);
        setField(connection, "closed", new java.util.concurrent.atomic.AtomicBoolean(false));
        setField(connection, "circuitBreaker", new CircuitBreaker());
        setField(connection, "telemetry", new TelemetryCollector());
        setField(connection, "readOnly", false);
        setField(connection, "autoCommit", true);
        setField(connection, "schema", "public");
        setField(connection, "catalog", "main");
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

    private static final class AutoIncrementCatalogProtocol extends SBProtocolHandler {
        AutoIncrementCatalogProtocol() {
            super(new SBConnectionProperties());
        }

        @Override
        public SBQueryResult execute(String sql, int maxRows, int timeoutMs) {
            SBQueryResult result = new SBQueryResult();
            if (sql.contains("FROM pg_catalog.pg_class c")) {
                result.setColumns(Arrays.asList(new SBColumnInfo(), new SBColumnInfo()));
                result.setRows(Collections.singletonList(new Object[] {"public", "demo"}));
                return result;
            }
            if (sql.contains("FROM pg_catalog.pg_attribute a")
                && sql.contains("pg_get_expr(ad.adbin")) {
                result.setColumns(Arrays.asList(new SBColumnInfo(), new SBColumnInfo()));
                int attnum = extractNumericSuffix(sql, "AND a.attnum = ");
                if (attnum == 1) {
                    result.setRows(Collections.singletonList(new Object[] {"d", "nextval('demo_id_seq')"}));
                } else {
                    result.setRows(Collections.singletonList(new Object[] {"", null}));
                }
                return result;
            }
            if (sql.contains("FROM pg_catalog.pg_attribute a")) {
                result.setColumns(Arrays.asList(new SBColumnInfo(), new SBColumnInfo()));
                result.setRows(List.of(
                    new Object[] {1, "id"},
                    new Object[] {2, "payload"}
                ));
                return result;
            }
            result.setColumns(Collections.emptyList());
            result.setRows(Collections.emptyList());
            return result;
        }

        private static int extractNumericSuffix(String sql, String marker) {
            int markerIndex = sql.indexOf(marker);
            if (markerIndex < 0) {
                return -1;
            }
            int start = markerIndex + marker.length();
            int end = start;
            while (end < sql.length() && Character.isDigit(sql.charAt(end))) {
                end++;
            }
            if (end <= start) {
                return -1;
            }
            try {
                return Integer.parseInt(sql.substring(start, end));
            } catch (NumberFormatException ex) {
                return -1;
            }
        }
    }
}
