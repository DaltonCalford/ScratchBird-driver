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

import java.sql.Ref;
import java.sql.SQLException;
import java.util.Map;

/**
 * Minimal JDBC Ref implementation used by the ScratchBird driver.
 */
public final class SBRef implements Ref {
    private final String baseTypeName;
    private Object value;

    public SBRef(String baseTypeName, Object value) {
        this.baseTypeName = baseTypeName == null ? "ref" : baseTypeName;
        this.value = value;
    }

    public static SBRef fromObject(Object value) throws SQLException {
        if (value == null) {
            return null;
        }
        if (value instanceof Ref) {
            Ref ref = (Ref) value;
            return new SBRef(ref.getBaseTypeName(), ref.getObject());
        }
        return new SBRef("ref", value);
    }

    @Override
    public String getBaseTypeName() throws SQLException {
        return baseTypeName;
    }

    @Override
    public Object getObject(Map<String, Class<?>> map) throws SQLException {
        return value;
    }

    @Override
    public Object getObject() throws SQLException {
        return value;
    }

    @Override
    public void setObject(Object value) throws SQLException {
        this.value = value;
    }
}
