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

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class SBSQLParserTest {

    @Test
    void convertsStoredProcedureEscapeToCall() {
        String sql = SBSQLParser.convertToNativeSQL("{call demo_proc(?, ?)}");
        assertEquals("CALL demo_proc(?, ?)", sql);
    }

    @Test
    void convertsStoredFunctionEscapeToSelect() {
        String sql = SBSQLParser.convertToNativeSQL("{? = call demo_fn(?)}");
        assertEquals("SELECT demo_fn(?)", sql);
    }
}
