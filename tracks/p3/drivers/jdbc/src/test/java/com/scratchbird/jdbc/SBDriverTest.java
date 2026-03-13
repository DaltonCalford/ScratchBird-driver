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
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.sql.SQLException;
import java.util.Properties;
import org.junit.jupiter.api.Test;

public class SBDriverTest {

    @Test
    public void parsesBasicUrl() throws SQLException {
        SBConnectionProperties props =
            SBDriver.parseURL("jdbc:scratchbird://localhost:3092/demo", null);
        assertEquals("localhost", props.getHost());
        assertEquals(3092, props.getPort());
        assertEquals("demo", props.getDatabase());
        assertNull(props.getCurrentSchema());
        assertNull(props.toProperties().getProperty("currentSchema"));
    }

    @Test
    public void parsesUrlWithParams() throws SQLException {
        Properties info = new Properties();
        info.setProperty("user", "alice");
        SBConnectionProperties props =
            SBDriver.parseURL("jdbc:scratchbird://db.example.com:3093/app?sslmode=require&connectTimeout=15&metadataExpandSchemaParents=true",
                info);
        assertEquals("db.example.com", props.getHost());
        assertEquals(3093, props.getPort());
        assertEquals("app", props.getDatabase());
        assertEquals("alice", props.getUser());
        assertEquals("require", props.getSslMode());
        assertEquals("15", props.getProperty("connectTimeout"));
        assertEquals("true", props.getProperty("metadataExpandSchemaParents"));
    }

    @Test
    public void parsesIpv6Url() throws SQLException {
        SBConnectionProperties props =
            SBDriver.parseURL("jdbc:scratchbird://[::1]:3092/testdb", null);
        assertEquals("::1", props.getHost());
        assertEquals(3092, props.getPort());
        assertEquals("testdb", props.getDatabase());
        assertNotNull(props);
    }

    @Test
    public void parsesCompressionAndRejectsUnsupportedAlgorithms() throws SQLException {
        SBConnectionProperties zstd = SBDriver.parseURL(
            "jdbc:scratchbird://localhost:3092/demo?compression=zstd", null);
        assertEquals("zstd", zstd.getCompression());

        SBConnectionProperties off = SBDriver.parseURL(
            "jdbc:scratchbird://localhost:3092/demo?compression=none", null);
        assertEquals("off", off.getCompression());

        assertThrows(SQLException.class, () ->
            SBDriver.parseURL("jdbc:scratchbird://localhost:3092/demo?compression=gzip", null));
    }

    @Test
    public void parsesDbeaverSchemaExpansionAlias() throws SQLException {
        SBConnectionProperties props = SBDriver.parseURL(
            "jdbc:scratchbird://localhost:3092/demo?dbeaver_expand_schema_parents=true", null);
        assertEquals("true", props.getProperty("metadataExpandSchemaParents"));
    }

    @Test
    public void preservesExplicitCurrentSchemaOverride() throws SQLException {
        SBConnectionProperties props = SBDriver.parseURL(
            "jdbc:scratchbird://localhost:3092/demo?currentSchema=users.public", null);
        assertEquals("users.public", props.getCurrentSchema());
        assertEquals("users.public", props.toProperties().getProperty("currentSchema"));
    }

    @Test
    public void parsesAuthPluginAndPinningParams() throws SQLException {
        SBConnectionProperties props = SBDriver.parseURL(
            "jdbc:scratchbird://localhost:3092/demo" +
                "?connect_client_flags=257" +
                "&auth_method_id=scratchbird.auth.proxy_assertion" +
                "&auth_method_payload=opaque" +
                "&auth_payload_json=%7B%22subject%22%3A%22alice%22%7D" +
                "&auth_payload_b64=YWJj" +
                "&auth_provider_profile=corp_primary" +
                "&auth_required_methods=SCRAM_SHA_256%2CTOKEN" +
                "&auth_forbidden_methods=MD5" +
                "&auth_require_channel_binding=true" +
                "&workload_identity_token=jwt-token" +
                "&proxy_principal_assertion=signed-assertion",
            null);

        assertEquals("257", props.getProperty("connect_client_flags"));
        assertEquals("scratchbird.auth.proxy_assertion", props.getProperty("auth_method_id"));
        assertEquals("opaque", props.getProperty("auth_method_payload"));
        assertEquals("{\"subject\":\"alice\"}", props.getProperty("auth_payload_json"));
        assertEquals("YWJj", props.getProperty("auth_payload_b64"));
        assertEquals("corp_primary", props.getProperty("auth_provider_profile"));
        assertEquals("SCRAM_SHA_256,TOKEN", props.getProperty("auth_required_methods"));
        assertEquals("MD5", props.getProperty("auth_forbidden_methods"));
        assertEquals("true", props.getProperty("auth_require_channel_binding"));
        assertEquals("jwt-token", props.getProperty("workload_identity_token"));
        assertEquals("signed-assertion", props.getProperty("proxy_principal_assertion"));
    }

    @Test
    public void rejectsInvalidAuthMethodNamespace() {
        SQLException ex = assertThrows(SQLException.class, () ->
            SBDriver.parseURL(
                "jdbc:scratchbird://localhost:3092/demo?auth_method_id=invalid.namespace",
                null));
        assertEquals("0A000", ex.getSQLState());
    }
}
