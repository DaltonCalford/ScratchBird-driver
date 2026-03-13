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

import java.nio.charset.StandardCharsets;
import java.sql.RowId;
import java.util.Arrays;

/**
 * Minimal JDBC RowId wrapper used by the ScratchBird driver.
 */
public final class SBRowId implements RowId {
    private final byte[] bytes;

    public SBRowId(byte[] bytes) {
        this.bytes = bytes == null ? new byte[0] : bytes.clone();
    }

    public static SBRowId fromObject(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof RowId) {
            return new SBRowId(((RowId) value).getBytes());
        }
        if (value instanceof byte[]) {
            return new SBRowId((byte[]) value);
        }
        return new SBRowId(value.toString().getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public byte[] getBytes() {
        return bytes.clone();
    }

    @Override
    public String toString() {
        return new String(bytes, StandardCharsets.UTF_8);
    }

    @Override
    public int hashCode() {
        return Arrays.hashCode(bytes);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof RowId)) return false;
        return Arrays.equals(bytes, ((RowId) obj).getBytes());
    }
}
