/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */
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
