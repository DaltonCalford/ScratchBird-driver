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
