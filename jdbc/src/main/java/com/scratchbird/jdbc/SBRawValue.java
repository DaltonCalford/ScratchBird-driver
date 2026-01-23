/*
 * ScratchBird JDBC Driver
 * Copyright (c) 2025 ScratchBird Project
 */
package com.scratchbird.jdbc;

public class SBRawValue {
    private final int oid;
    private final byte[] data;

    public SBRawValue(int oid, byte[] data) {
        this.oid = oid;
        this.data = data != null ? data.clone() : null;
    }

    public int getOid() {
        return oid;
    }

    public byte[] getData() {
        return data != null ? data.clone() : null;
    }
}
