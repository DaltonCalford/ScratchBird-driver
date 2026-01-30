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
