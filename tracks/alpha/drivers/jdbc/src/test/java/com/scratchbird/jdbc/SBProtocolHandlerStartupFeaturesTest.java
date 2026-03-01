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
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

class SBProtocolHandlerStartupFeaturesTest {
    private static final long FEATURE_COMPRESSION = 1L << 0;
    private static final long FEATURE_STREAMING = 1L << 1;

    @Test
    void startupPayloadEncodesFeatureFlagsFromConnectionOptions() throws Exception {
        assertEquals(FEATURE_STREAMING, startupFeatureBits(true, "off"));
        assertEquals(0L, startupFeatureBits(false, "off"));
        assertEquals(FEATURE_COMPRESSION, startupFeatureBits(false, "zstd"));
        assertEquals(FEATURE_COMPRESSION | FEATURE_STREAMING, startupFeatureBits(true, "zstd"));
    }

    private static long startupFeatureBits(boolean binaryTransfer, String compression) throws Exception {
        SBConnectionProperties properties = new SBConnectionProperties();
        properties.setBinaryTransfer(binaryTransfer);
        properties.setCompression(compression);
        properties.setDatabase("main");
        properties.setUser("scratchbird");

        SBProtocolHandler protocol = new SBProtocolHandler(properties);
        ByteArrayOutputStream networkBuffer = new ByteArrayOutputStream();
        setField(protocol, "outputStream", networkBuffer);

        Method sendStartup = SBProtocolHandler.class.getDeclaredMethod("sendStartupMessage");
        sendStartup.setAccessible(true);
        sendStartup.invoke(protocol);

        byte[] message = networkBuffer.toByteArray();
        int marker = indexOf(message, "database".getBytes(StandardCharsets.UTF_8));
        assertTrue(marker >= 8, "startup frame did not include expected parameter block");
        int featureOffset = marker - 8;
        ByteBuffer payload = ByteBuffer.wrap(message).order(ByteOrder.LITTLE_ENDIAN);
        payload.position(featureOffset);
        return payload.getLong();
    }

    private static int indexOf(byte[] value, byte[] needle) {
        if (value == null || needle == null || needle.length == 0 || value.length < needle.length) {
            return -1;
        }
        for (int i = 0; i <= value.length - needle.length; i++) {
            boolean match = true;
            for (int j = 0; j < needle.length; j++) {
                if (value[i + j] != needle[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return i;
            }
        }
        return -1;
    }

    private static void setField(Object target, String fieldName, Object value) throws Exception {
        Field field = SBProtocolHandler.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(target, value);
    }
}
