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

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.nio.charset.StandardCharsets;
import java.sql.Types;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import org.junit.jupiter.api.Test;

class SBTypeCodecParameterCoverageTest {

    @Test
    void encodesExtendedJdbcParameterObjects() throws Exception {
        byte[] rowIdBytes = "rid-42".getBytes(StandardCharsets.UTF_8);
        SBTypeCodec.ParamEncoding rowId = SBTypeCodec.encodeParam(new SBRowId(rowIdBytes), Types.ROWID);
        assertEquals(SBTypeCodec.OID_BYTEA, rowId.getOid());
        assertArrayEquals(
            rowIdBytes,
            assertInstanceOf(byte[].class,
                SBTypeCodec.decodeValue(rowId.getOid(), rowId.getData(), rowId.getFormat())));

        SBTypeCodec.ParamEncoding ref = SBTypeCodec.encodeParam(new SBRef("demo_ref", "rid-100"), Types.REF);
        assertEquals(SBTypeCodec.OID_TEXT, ref.getOid());
        assertEquals("rid-100", SBTypeCodec.decodeValue(ref.getOid(), ref.getData(), ref.getFormat()));

        SBTypeCodec.ParamEncoding xml = SBTypeCodec.encodeParam(new SBSQLXML("<doc/>"), Types.SQLXML);
        assertEquals(SBTypeCodec.OID_XML, xml.getOid());
        assertEquals("<doc/>", SBTypeCodec.decodeValue(xml.getOid(), xml.getData(), xml.getFormat()));

        SBTypeCodec.ParamEncoding blob = SBTypeCodec.encodeParam(new SBBlob(new byte[]{1, 2, 3}), Types.BLOB);
        assertEquals(SBTypeCodec.OID_BYTEA, blob.getOid());
        assertArrayEquals(
            new byte[]{1, 2, 3},
            assertInstanceOf(byte[].class,
                SBTypeCodec.decodeValue(blob.getOid(), blob.getData(), blob.getFormat())));

        SBTypeCodec.ParamEncoding clob = SBTypeCodec.encodeParam(new SBClob("hello"), Types.CLOB);
        assertEquals(SBTypeCodec.OID_TEXT, clob.getOid());
        assertEquals("hello", SBTypeCodec.decodeValue(clob.getOid(), clob.getData(), clob.getFormat()));

        SBTypeCodec.ParamEncoding enumValue = SBTypeCodec.encodeParam(Thread.State.RUNNABLE, Types.VARCHAR);
        assertEquals(SBTypeCodec.OID_TEXT, enumValue.getOid());
        assertEquals("RUNNABLE", SBTypeCodec.decodeValue(
            enumValue.getOid(), enumValue.getData(), enumValue.getFormat()));
    }

    @Test
    void acceptsStringTemporalBoundsForRanges() throws Exception {
        SBRange<String> dateRange = new SBRange<>(
            "2026-01-10",
            "2026-02-11",
            true,
            false,
            false,
            false,
            false,
            SBTypeCodec.OID_DATERANGE);
        SBTypeCodec.ParamEncoding encodedDateRange = SBTypeCodec.encodeParam(dateRange, null);
        SBRange<?> decodedDateRange = assertInstanceOf(SBRange.class, SBTypeCodec.decodeValue(
            encodedDateRange.getOid(),
            encodedDateRange.getData(),
            encodedDateRange.getFormat()));
        assertEquals(LocalDate.parse("2026-01-10"), decodedDateRange.getLower());
        assertEquals(LocalDate.parse("2026-02-11"), decodedDateRange.getUpper());

        SBRange<String> tsTzRange = new SBRange<>(
            "2026-03-01T00:00:00Z",
            "2026-03-02T12:30:00Z",
            true,
            false,
            false,
            false,
            false,
            SBTypeCodec.OID_TSTZRANGE);
        SBTypeCodec.ParamEncoding encodedTsTzRange = SBTypeCodec.encodeParam(tsTzRange, null);
        SBRange<?> decodedTsTzRange = assertInstanceOf(SBRange.class, SBTypeCodec.decodeValue(
            encodedTsTzRange.getOid(),
            encodedTsTzRange.getData(),
            encodedTsTzRange.getFormat()));
        assertNotNull(decodedTsTzRange.getLower());
        assertNotNull(decodedTsTzRange.getUpper());
        assertInstanceOf(OffsetDateTime.class, decodedTsTzRange.getLower());
        assertInstanceOf(OffsetDateTime.class, decodedTsTzRange.getUpper());
    }
}
