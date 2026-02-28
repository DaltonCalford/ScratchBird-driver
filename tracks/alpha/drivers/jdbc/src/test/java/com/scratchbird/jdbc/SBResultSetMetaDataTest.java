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

import java.math.BigDecimal;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

class SBResultSetMetaDataTest {

    @Test
    void reportsWritableAndQualifiedTableMetadataWhenProvided() throws Exception {
        SBColumnInfo amount = new SBColumnInfo();
        amount.setName("amount");
        amount.setTypeOid(790); // money
        amount.setTableOid(42);
        amount.setColumnNumber((short) 1);

        SBColumnInfo note = new SBColumnInfo();
        note.setName("note");
        note.setTypeOid(25); // text

        List<SBColumnInfo> columns = new ArrayList<>();
        columns.add(amount);
        columns.add(note);

        SBResultSetMetaData meta = new SBResultSetMetaData(
            columns,
            true,
            Set.of(1),
            "public",
            "orders",
            "main");

        assertEquals(2, meta.getColumnCount());
        assertEquals("public", meta.getSchemaName(1));
        assertEquals("orders", meta.getTableName(1));
        assertEquals("main", meta.getCatalogName(1));
        assertTrue(meta.isCurrency(1));
        assertEquals(Types.NUMERIC, meta.getColumnType(1));
        assertEquals(BigDecimal.class.getName(), meta.getColumnClassName(1));

        assertFalse(meta.isReadOnly(1));
        assertTrue(meta.isWritable(1));
        assertTrue(meta.isDefinitelyWritable(1));

        assertTrue(meta.isReadOnly(2));
        assertFalse(meta.isWritable(2));
        assertFalse(meta.isDefinitelyWritable(2));
    }

    @Test
    void reportsUuidClassForUuidOid() throws Exception {
        SBColumnInfo id = new SBColumnInfo();
        id.setName("id");
        id.setTypeOid(2950); // uuid

        SBResultSetMetaData meta = new SBResultSetMetaData(List.of(id));
        assertEquals(java.util.UUID.class.getName(), meta.getColumnClassName(1));
    }
}
