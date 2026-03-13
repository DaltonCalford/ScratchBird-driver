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

import java.sql.*;
import java.util.*;

/**
 * JDBC Struct implementation for ScratchBird.
 */
public class SBStruct implements Struct {
    private final String typeName;
    private final Object[] attributes;

    public SBStruct(String typeName, Object[] attributes) {
        this.typeName = typeName;
        this.attributes = attributes != null ? attributes.clone() : new Object[0];
    }

    @Override
    public String getSQLTypeName() throws SQLException {
        return typeName;
    }

    @Override
    public Object[] getAttributes() throws SQLException {
        return attributes.clone();
    }

    @Override
    public Object[] getAttributes(Map<String, Class<?>> map) throws SQLException {
        return getAttributes();
    }
}
