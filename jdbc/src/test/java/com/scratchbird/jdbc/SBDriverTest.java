/*
 * ScratchBird JDBC Driver tests
 */
package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

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
    }

    @Test
    public void parsesUrlWithParams() throws SQLException {
        Properties info = new Properties();
        info.setProperty("user", "alice");
        SBConnectionProperties props =
            SBDriver.parseURL("jdbc:scratchbird://db.example.com:3093/app?sslmode=require&connectTimeout=15",
                info);
        assertEquals("db.example.com", props.getHost());
        assertEquals(3093, props.getPort());
        assertEquals("app", props.getDatabase());
        assertEquals("alice", props.getUser());
        assertEquals("require", props.getSslMode());
        assertEquals("15", props.getProperty("connectTimeout"));
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
}
