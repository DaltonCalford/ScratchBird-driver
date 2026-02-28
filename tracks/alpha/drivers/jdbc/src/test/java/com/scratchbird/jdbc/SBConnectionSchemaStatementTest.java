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

class SBConnectionSchemaStatementTest {

    @Test
    void buildsSchemaStatementForRecursiveSchemaPath() {
        assertEquals("SET SCHEMA \"public\".\"examples\"",
            SBConnection.buildSchemaStatement("public.examples"));
    }

    @Test
    void buildsSearchPathStatementForMultipleRecursiveSchemas() {
        assertEquals("SET SEARCH_PATH TO \"public\".\"examples\", \"compat\".\"mysql\"",
            SBConnection.buildSchemaStatement("public.examples, compat.mysql"));
    }

    @Test
    void preservesQuotedSchemaSegments() {
        assertEquals("SET SCHEMA \"Public\".\"Examples\"",
            SBConnection.buildSchemaStatement("\"Public\".\"Examples\""));
    }
}
