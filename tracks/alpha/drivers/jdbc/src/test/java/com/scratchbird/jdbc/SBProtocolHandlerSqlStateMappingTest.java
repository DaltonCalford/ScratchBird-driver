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

import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertFalse;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.sql.SQLException;
import org.junit.jupiter.api.Test;

public class SBProtocolHandlerSqlStateMappingTest {

    @Test
    public void exactSqlStateMapsToSpecificType() throws Exception {
        var ex = createSQLExceptionFromState("42P01");
        assertInstanceOf(java.sql.SQLSyntaxErrorException.class, ex);
    }

    @Test
    public void classSqlStateMapsToCategory() throws Exception {
        var ex = createSQLExceptionFromState("22000");
        assertInstanceOf(java.sql.SQLDataException.class, ex);
    }

    @Test
    public void classSqlStateMapsConnectionCategory() throws Exception {
        var ex = createSQLExceptionFromState("08012");
        assertInstanceOf(java.sql.SQLTransientConnectionException.class, ex);
    }

    @Test
    public void unknownClassReturnsGenericSqlException() throws Exception {
        var ex = createSQLExceptionFromState("ZZ123");
        assertInstanceOf(java.sql.SQLException.class, ex);
        assertFalse(ex instanceof java.sql.SQLTransientException);
    }

    private static SQLException createSQLExceptionFromState(String state) throws Exception {
        var method = getCreateSQLExceptionMethod();
        var handler = new SBProtocolHandler(new SBConnectionProperties());
        try {
            var result = method.invoke(handler, "mapped", state);
            return (SQLException) result;
        } catch (InvocationTargetException ex) {
            var cause = ex.getTargetException();
            if (cause instanceof Exception exception) {
                throw exception;
            }
            throw ex;
        }
    }

    private static Method getCreateSQLExceptionMethod() throws NoSuchMethodException {
        var method = SBProtocolHandler.class.getDeclaredMethod("createSQLException", String.class, String.class);
        method.setAccessible(true);
        return method;
    }
}
