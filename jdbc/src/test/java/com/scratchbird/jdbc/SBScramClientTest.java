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
 * ScratchBird JDBC Driver tests
 */
package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

public class SBScramClientTest {

    @Test
    public void scramHandshakeProducesExpectedFormat() {
        SBScramClient scram = new SBScramClient("user", "rOprNGfwEbeRWgbNEkqO");
        String clientFirst = scram.getClientFirstMessage();
        assertEquals("n,,n=user,r=rOprNGfwEbeRWgbNEkqO", clientFirst);

        String serverFirst =
            "r=rOprNGfwEbeRWgbNEkqO+3rfcNHYJY1ZVvWVs7j," +
            "s=W22ZaJ0SNY7soEsUEjb6gQ==,i=4096";

        String clientFinal = scram.handleServerFirst(serverFirst, "pencil");
        assertTrue(clientFinal.startsWith("c=biws,r=rOprNGfwEbeRWgbNEkqO+3rfcNHYJY1ZVvWVs7j,"));

        String serverFinal = "v=" + scram.getServerSignatureBase64();
        scram.verifyServerFinal(serverFinal);
    }
}
