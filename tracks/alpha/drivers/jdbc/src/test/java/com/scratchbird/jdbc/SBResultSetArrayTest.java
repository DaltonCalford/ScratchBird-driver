package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.Array;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

class SBResultSetArrayTest {

    @Test
    void parsesBraceIntegerArrayLiterals() throws SQLException {
        SBResultSet rs = singleColumnResultSet("{1,2,3}");
        assertTrue(rs.next());

        Array array = rs.getArray(1);
        assertNotNull(array);
        assertEquals("integer", array.getBaseTypeName());
        assertArrayEquals(new Object[] {1, 2, 3}, (Object[]) array.getArray());
    }

    @Test
    void parsesArrayKeywordWithQuotedValues() throws SQLException {
        SBResultSet rs = singleColumnResultSet("ARRAY['alpha','be\\'ta',NULL,'3']");
        assertTrue(rs.next());

        Array array = rs.getArray(1);
        assertNotNull(array);
        assertEquals("text", array.getBaseTypeName());
        assertArrayEquals(new Object[] {"alpha", "be'ta", null, "3"}, (Object[]) array.getArray());
    }

    @Test
    void wrapsObjectArrayWithoutStringParsing() throws SQLException {
        SBResultSet rs = singleColumnResultSet(new Object[] {true, false, true});
        assertTrue(rs.next());

        Array array = rs.getArray(1);
        assertNotNull(array);
        assertEquals("boolean", array.getBaseTypeName());
        assertArrayEquals(new Object[] {true, false, true}, (Object[]) array.getArray());
    }

    @Test
    void parsesNestedArrayLiterals() throws SQLException {
        SBResultSet rs = singleColumnResultSet("{{1,2},{3,4}}");
        assertTrue(rs.next());

        Array array = rs.getArray(1);
        Object[] outer = (Object[]) array.getArray();
        assertEquals(2, outer.length);
        assertArrayEquals(new Object[] {1, 2}, (Object[]) outer[0]);
        assertArrayEquals(new Object[] {3, 4}, (Object[]) outer[1]);
    }

    private static SBResultSet singleColumnResultSet(Object value) {
        SBColumnInfo column = new SBColumnInfo();
        column.setName("arr");
        List<SBColumnInfo> columns = Collections.singletonList(column);
        List<Object[]> rows = Collections.singletonList(new Object[] {value});
        return new SBResultSet(null, columns, rows);
    }
}
