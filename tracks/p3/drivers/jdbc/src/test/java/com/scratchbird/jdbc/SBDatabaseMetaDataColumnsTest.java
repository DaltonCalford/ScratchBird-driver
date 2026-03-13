package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Types;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

class SBDatabaseMetaDataColumnsTest {

    private static final class HarnessMetaData extends SBDatabaseMetaData {
        private final List<Object[]> columnRows;

        private HarnessMetaData(List<Object[]> columnRows) {
            super(null);
            this.columnRows = columnRows;
        }

        @Override
        protected String currentCatalogName() {
            return "demo";
        }

        @Override
        protected List<Object[]> queryRows(String sql) throws SQLException {
            if (sql != null && sql.contains("FROM sys.columns c")) {
                return columnRows;
            }
            return Collections.emptyList();
        }
    }

    @Test
    void getColumnsReportsUsefulTypeSizesAndScale() throws SQLException {
        SBDatabaseMetaData meta = new HarnessMetaData(Arrays.asList(
            new Object[]{"id", "int4", 1, 0, "nextval('orders_id_seq'::regclass)", "orders", "public"},
            new Object[]{"price", "numeric", 2, 1, "0", "orders", "public"},
            new Object[]{"name", "varchar", 3, 1, "GENERATED ALWAYS AS (upper(payload)) STORED", "orders", "public"},
            new Object[]{"created_at", "timestamp", 4, 1, null, "orders", "public"}
        ));

        ResultSet rs = meta.getColumns(null, "public", "orders", "%");
        int seen = 0;
        while (rs.next()) {
            seen++;
            String column = rs.getString("COLUMN_NAME");
            assertNotNull(column);
            if ("id".equals(column)) {
                assertEquals(Types.INTEGER, rs.getInt("DATA_TYPE"));
                assertEquals(10, rs.getInt("COLUMN_SIZE"));
                assertEquals(0, rs.getInt("DECIMAL_DIGITS"));
                assertEquals(10, rs.getInt("NUM_PREC_RADIX"));
                assertEquals("YES", rs.getString("IS_AUTOINCREMENT"));
            } else if ("price".equals(column)) {
                assertEquals(Types.NUMERIC, rs.getInt("DATA_TYPE"));
                assertEquals(38, rs.getInt("COLUMN_SIZE"));
                assertEquals(0, rs.getInt("DECIMAL_DIGITS"));
                assertEquals(10, rs.getInt("NUM_PREC_RADIX"));
                assertEquals("NO", rs.getString("IS_AUTOINCREMENT"));
            } else if ("name".equals(column)) {
                assertEquals(Types.VARCHAR, rs.getInt("DATA_TYPE"));
                assertEquals(65535, rs.getInt("COLUMN_SIZE"));
                assertEquals(65535, rs.getInt("CHAR_OCTET_LENGTH"));
                assertEquals("NO", rs.getString("IS_AUTOINCREMENT"));
                assertEquals("YES", rs.getString("IS_GENERATEDCOLUMN"));
            } else if ("created_at".equals(column)) {
                assertEquals(Types.TIMESTAMP, rs.getInt("DATA_TYPE"));
                assertEquals(29, rs.getInt("COLUMN_SIZE"));
                assertEquals("NO", rs.getString("IS_AUTOINCREMENT"));
                assertEquals("NO", rs.getString("IS_GENERATEDCOLUMN"));
            }
        }

        assertEquals(4, seen);
    }

    @Test
    void supportsResultSetConcurrencyRequiresSupportedType() throws SQLException {
        SBDatabaseMetaData meta = new HarnessMetaData(Collections.emptyList());
        assertTrue(meta.supportsResultSetConcurrency(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY));
        assertTrue(meta.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY));
        assertTrue(meta.supportsResultSetConcurrency(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE));
        assertTrue(meta.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE));
        assertTrue(meta.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY));
        assertTrue(meta.supportsResultSetConcurrency(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE));
    }

    @Test
    void catalogMismatchStillReturnsStandardColumnsShape() throws SQLException {
        SBDatabaseMetaData meta = new HarnessMetaData(Collections.emptyList());
        ResultSet rs = meta.getColumns("other", "public", "orders", "%");
        ResultSetMetaData md = rs.getMetaData();

        assertEquals(24, md.getColumnCount());
        assertEquals("TABLE_CAT", md.getColumnName(1));
        assertEquals("IS_GENERATEDCOLUMN", md.getColumnName(24));
        assertFalse(rs.next());
    }
}
