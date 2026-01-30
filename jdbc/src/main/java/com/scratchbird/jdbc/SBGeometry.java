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

public class SBGeometry {
    private final byte[] wkb;
    private final Integer srid;
    private final String wkt;

    public SBGeometry(byte[] wkb) {
        this(wkb, null, null);
    }

    public SBGeometry(byte[] wkb, Integer srid, String wkt) {
        this.wkb = wkb != null ? wkb.clone() : null;
        this.srid = srid;
        this.wkt = wkt;
    }

    public byte[] getWkb() {
        return wkb != null ? wkb.clone() : null;
    }

    public Integer getSrid() {
        return srid;
    }

    public String getWkt() {
        return wkt;
    }
}
