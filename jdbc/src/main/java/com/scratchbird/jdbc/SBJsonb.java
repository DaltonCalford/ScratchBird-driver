/*
 * ScratchBird JDBC Driver
 * Copyright (c) 2025 ScratchBird Project
 */
package com.scratchbird.jdbc;

import java.nio.charset.StandardCharsets;

public class SBJsonb {
    private final byte[] raw;
    private final String value;

    public SBJsonb(byte[] raw) {
        this(raw, null);
    }

    public SBJsonb(String value) {
        this(value != null ? value.getBytes(StandardCharsets.UTF_8) : null, value);
    }

    public SBJsonb(byte[] raw, String value) {
        this.raw = raw != null ? raw.clone() : null;
        this.value = value;
    }

    public byte[] getRaw() {
        return raw != null ? raw.clone() : null;
    }

    public String getValue() {
        return value;
    }
}
