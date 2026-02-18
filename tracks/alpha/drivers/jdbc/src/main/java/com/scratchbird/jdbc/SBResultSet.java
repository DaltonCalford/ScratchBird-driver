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

import java.io.*;
import java.math.*;
import java.net.*;
import java.sql.*;
import java.util.*;
import java.time.*;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * JDBC ResultSet implementation for ScratchBird.
 */
public class SBResultSet implements ResultSet {

    // Parent statement
    private final SBStatement statement;

    // Column metadata
    private List<SBColumnInfo> columns;
    private final Map<String, Integer> columnNameIndex;

    // Row data
    private final SBRowStream stream;
    private final List<Object[]> rows;
    private Object[] currentRowData;
    private int rowsRead = 0;
    private final int maxRowsLimit;

    // Position (0-indexed internally, before-first is -1)
    private int currentRow = -1;

    // State
    private final AtomicBoolean closed = new AtomicBoolean(false);
    private boolean wasNull = false;

    // Warnings
    private SQLWarning warnings;

    // Fetch direction and size
    private int fetchDirection = ResultSet.FETCH_FORWARD;
    private int fetchSize = 0;

    /**
     * Creates a new result set from a buffered row list.
     */
    public SBResultSet(SBStatement statement, List<SBColumnInfo> columns, List<Object[]> rows) {
        this(statement, new ListRowStream(columns, rows), 0);
    }

    /**
     * Creates a new result set backed by a streaming cursor.
     */
    public SBResultSet(SBStatement statement, SBRowStream stream, int maxRowsLimit) {
        this.statement = statement;
        this.stream = stream;
        this.maxRowsLimit = maxRowsLimit;
        this.columns = stream != null && stream.getColumns() != null ? stream.getColumns() : Collections.emptyList();
        this.rows = stream instanceof ListRowStream ? ((ListRowStream) stream).getRows() : Collections.emptyList();

        this.columnNameIndex = new HashMap<>();
        rebuildColumnIndex();
    }

    // ==================== Navigation ====================

    @Override
    public boolean next() throws SQLException {
        checkClosed();
        if (maxRowsLimit > 0 && rowsRead >= maxRowsLimit) {
            currentRow = rowsRead;
            currentRowData = null;
            return false;
        }
        Object[] row = stream != null ? stream.nextRow() : null;
        if (row == null) {
            currentRow = rowsRead;
            currentRowData = null;
            return false;
        }
        currentRowData = row;
        rowsRead++;
        currentRow = rowsRead - 1;
        syncColumns();
        return true;
    }

    @Override
    public void close() throws SQLException {
        if (closed.compareAndSet(false, true)) {
            if (statement != null) {
                statement.checkCloseOnCompletion();
            }
        }
    }

    @Override
    public boolean wasNull() throws SQLException {
        checkClosed();
        return wasNull;
    }

    // ==================== Getters by Column Index ====================

    @Override
    public String getString(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return null;
        return value.toString();
    }

    @Override
    public boolean getBoolean(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return false;
        if (value instanceof Boolean) return (Boolean) value;
        if (value instanceof Number) return ((Number) value).intValue() != 0;
        String s = value.toString().toLowerCase();
        return "t".equals(s) || "true".equals(s) || "yes".equals(s) || "1".equals(s);
    }

    @Override
    public byte getByte(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return 0;
        if (value instanceof Number) return ((Number) value).byteValue();
        return Byte.parseByte(value.toString());
    }

    @Override
    public short getShort(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return 0;
        if (value instanceof Number) return ((Number) value).shortValue();
        return Short.parseShort(value.toString());
    }

    @Override
    public int getInt(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return 0;
        if (value instanceof Number) return ((Number) value).intValue();
        return Integer.parseInt(value.toString());
    }

    @Override
    public long getLong(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return 0;
        if (value instanceof Number) return ((Number) value).longValue();
        return Long.parseLong(value.toString());
    }

    @Override
    public float getFloat(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return 0;
        if (value instanceof Number) return ((Number) value).floatValue();
        return Float.parseFloat(value.toString());
    }

    @Override
    public double getDouble(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return 0;
        if (value instanceof Number) return ((Number) value).doubleValue();
        return Double.parseDouble(value.toString());
    }

    @Override
    @Deprecated
    public BigDecimal getBigDecimal(int columnIndex, int scale) throws SQLException {
        BigDecimal bd = getBigDecimal(columnIndex);
        if (bd == null) return null;
        return bd.setScale(scale, RoundingMode.HALF_UP);
    }

    @Override
    public BigDecimal getBigDecimal(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return null;
        if (value instanceof BigDecimal) return (BigDecimal) value;
        if (value instanceof Number) return BigDecimal.valueOf(((Number) value).doubleValue());
        return new BigDecimal(value.toString());
    }

    @Override
    public byte[] getBytes(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return null;
        if (value instanceof byte[]) return (byte[]) value;
        // Try to decode hex string
        String s = value.toString();
        if (s.startsWith("\\x")) {
            s = s.substring(2);
            byte[] bytes = new byte[s.length() / 2];
            for (int i = 0; i < bytes.length; i++) {
                bytes[i] = (byte) Integer.parseInt(s.substring(i * 2, i * 2 + 2), 16);
            }
            return bytes;
        }
        return s.getBytes();
    }

    @Override
    public java.sql.Date getDate(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return null;
        if (value instanceof java.sql.Date) return (java.sql.Date) value;
        if (value instanceof java.util.Date) return new java.sql.Date(((java.util.Date) value).getTime());
        return java.sql.Date.valueOf(value.toString());
    }

    @Override
    public java.sql.Date getDate(int columnIndex, Calendar cal) throws SQLException {
        return adjustDate(getDate(columnIndex), cal);
    }

    @Override
    public Time getTime(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return null;
        if (value instanceof Time) return (Time) value;
        if (value instanceof java.util.Date) return new Time(((java.util.Date) value).getTime());
        return Time.valueOf(value.toString());
    }

    @Override
    public Time getTime(int columnIndex, Calendar cal) throws SQLException {
        return adjustTime(getTime(columnIndex), cal);
    }

    @Override
    public Timestamp getTimestamp(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return null;
        if (value instanceof Timestamp) return (Timestamp) value;
        if (value instanceof java.util.Date) return new Timestamp(((java.util.Date) value).getTime());
        return Timestamp.valueOf(value.toString());
    }

    @Override
    public Timestamp getTimestamp(int columnIndex, Calendar cal) throws SQLException {
        return adjustTimestamp(getTimestamp(columnIndex), cal);
    }

    private static java.sql.Date adjustDate(java.sql.Date value, Calendar cal) {
        if (value == null || cal == null) {
            return value;
        }
        Instant instant = Instant.ofEpochMilli(value.getTime());
        LocalDate localDate = instant.atZone(cal.getTimeZone().toZoneId()).toLocalDate();
        return java.sql.Date.valueOf(localDate);
    }

    private static java.sql.Time adjustTime(java.sql.Time value, Calendar cal) {
        if (value == null || cal == null) {
            return value;
        }
        Instant instant = Instant.ofEpochMilli(value.getTime());
        LocalTime localTime = instant.atZone(cal.getTimeZone().toZoneId()).toLocalTime();
        return java.sql.Time.valueOf(localTime);
    }

    private static java.sql.Timestamp adjustTimestamp(java.sql.Timestamp value, Calendar cal) {
        if (value == null || cal == null) {
            return value;
        }
        Instant instant = value.toInstant();
        LocalDateTime localDateTime = instant.atZone(cal.getTimeZone().toZoneId()).toLocalDateTime();
        java.sql.Timestamp adjusted = java.sql.Timestamp.valueOf(localDateTime);
        adjusted.setNanos(value.getNanos());
        return adjusted;
    }

    @Override
    public InputStream getAsciiStream(int columnIndex) throws SQLException {
        String s = getString(columnIndex);
        if (s == null) return null;
        try {
            return new ByteArrayInputStream(s.getBytes("US-ASCII"));
        } catch (UnsupportedEncodingException e) {
            throw new SQLException("ASCII encoding not supported", "HY000", e);
        }
    }

    @Override
    @Deprecated
    public InputStream getUnicodeStream(int columnIndex) throws SQLException {
        String s = getString(columnIndex);
        if (s == null) return null;
        try {
            return new ByteArrayInputStream(s.getBytes("UTF-8"));
        } catch (UnsupportedEncodingException e) {
            throw new SQLException("UTF-8 encoding not supported", "HY000", e);
        }
    }

    @Override
    public InputStream getBinaryStream(int columnIndex) throws SQLException {
        byte[] bytes = getBytes(columnIndex);
        if (bytes == null) return null;
        return new ByteArrayInputStream(bytes);
    }

    @Override
    public Reader getCharacterStream(int columnIndex) throws SQLException {
        String s = getString(columnIndex);
        if (s == null) return null;
        return new StringReader(s);
    }

    // ==================== Getters by Column Label ====================

    @Override
    public String getString(String columnLabel) throws SQLException {
        return getString(findColumn(columnLabel));
    }

    @Override
    public boolean getBoolean(String columnLabel) throws SQLException {
        return getBoolean(findColumn(columnLabel));
    }

    @Override
    public byte getByte(String columnLabel) throws SQLException {
        return getByte(findColumn(columnLabel));
    }

    @Override
    public short getShort(String columnLabel) throws SQLException {
        return getShort(findColumn(columnLabel));
    }

    @Override
    public int getInt(String columnLabel) throws SQLException {
        return getInt(findColumn(columnLabel));
    }

    @Override
    public long getLong(String columnLabel) throws SQLException {
        return getLong(findColumn(columnLabel));
    }

    @Override
    public float getFloat(String columnLabel) throws SQLException {
        return getFloat(findColumn(columnLabel));
    }

    @Override
    public double getDouble(String columnLabel) throws SQLException {
        return getDouble(findColumn(columnLabel));
    }

    @Override
    @Deprecated
    public BigDecimal getBigDecimal(String columnLabel, int scale) throws SQLException {
        return getBigDecimal(findColumn(columnLabel), scale);
    }

    @Override
    public BigDecimal getBigDecimal(String columnLabel) throws SQLException {
        return getBigDecimal(findColumn(columnLabel));
    }

    @Override
    public byte[] getBytes(String columnLabel) throws SQLException {
        return getBytes(findColumn(columnLabel));
    }

    @Override
    public java.sql.Date getDate(String columnLabel) throws SQLException {
        return getDate(findColumn(columnLabel));
    }

    @Override
    public java.sql.Date getDate(String columnLabel, Calendar cal) throws SQLException {
        return getDate(findColumn(columnLabel), cal);
    }

    @Override
    public Time getTime(String columnLabel) throws SQLException {
        return getTime(findColumn(columnLabel));
    }

    @Override
    public Time getTime(String columnLabel, Calendar cal) throws SQLException {
        return getTime(findColumn(columnLabel), cal);
    }

    @Override
    public Timestamp getTimestamp(String columnLabel) throws SQLException {
        return getTimestamp(findColumn(columnLabel));
    }

    @Override
    public Timestamp getTimestamp(String columnLabel, Calendar cal) throws SQLException {
        return getTimestamp(findColumn(columnLabel), cal);
    }

    @Override
    public InputStream getAsciiStream(String columnLabel) throws SQLException {
        return getAsciiStream(findColumn(columnLabel));
    }

    @Override
    @Deprecated
    public InputStream getUnicodeStream(String columnLabel) throws SQLException {
        return getUnicodeStream(findColumn(columnLabel));
    }

    @Override
    public InputStream getBinaryStream(String columnLabel) throws SQLException {
        return getBinaryStream(findColumn(columnLabel));
    }

    @Override
    public Reader getCharacterStream(String columnLabel) throws SQLException {
        return getCharacterStream(findColumn(columnLabel));
    }

    // ==================== Object Getters ====================

    @Override
    public Object getObject(int columnIndex) throws SQLException {
        checkClosed();
        checkRow();
        checkColumnIndex(columnIndex);

        Object value = currentRowData[columnIndex - 1];
        wasNull = (value == null);
        return value;
    }

    @Override
    public Object getObject(String columnLabel) throws SQLException {
        return getObject(findColumn(columnLabel));
    }

    @Override
    public Object getObject(int columnIndex, Map<String, Class<?>> map) throws SQLException {
        return getObject(columnIndex);
    }

    @Override
    public Object getObject(String columnLabel, Map<String, Class<?>> map) throws SQLException {
        return getObject(findColumn(columnLabel), map);
    }

    @Override
    public <T> T getObject(int columnIndex, Class<T> type) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return null;

        if (type.isInstance(value)) {
            return type.cast(value);
        }

        // Type conversions
        if (type == String.class) {
            return type.cast(value.toString());
        } else if (type == Integer.class || type == int.class) {
            return type.cast(getInt(columnIndex));
        } else if (type == Long.class || type == long.class) {
            return type.cast(getLong(columnIndex));
        } else if (type == Double.class || type == double.class) {
            return type.cast(getDouble(columnIndex));
        } else if (type == Float.class || type == float.class) {
            return type.cast(getFloat(columnIndex));
        } else if (type == Boolean.class || type == boolean.class) {
            return type.cast(getBoolean(columnIndex));
        } else if (type == BigDecimal.class) {
            return type.cast(getBigDecimal(columnIndex));
        } else if (type == java.sql.Date.class) {
            return type.cast(getDate(columnIndex));
        } else if (type == Time.class) {
            return type.cast(getTime(columnIndex));
        } else if (type == Timestamp.class) {
            return type.cast(getTimestamp(columnIndex));
        } else if (type == byte[].class) {
            return type.cast(getBytes(columnIndex));
        } else if (type == UUID.class) {
            String s = getString(columnIndex);
            return s == null ? null : type.cast(UUID.fromString(s));
        }

        throw new SQLException("Cannot convert to " + type.getName(), "HY000");
    }

    @Override
    public <T> T getObject(String columnLabel, Class<T> type) throws SQLException {
        return getObject(findColumn(columnLabel), type);
    }

    // ==================== Positioning ====================

    @Override
    public SQLWarning getWarnings() throws SQLException {
        checkClosed();
        return warnings;
    }

    @Override
    public void clearWarnings() throws SQLException {
        checkClosed();
        warnings = null;
    }

    @Override
    public String getCursorName() throws SQLException {
        checkClosed();
        return null;  // Not supported
    }

    @Override
    public ResultSetMetaData getMetaData() throws SQLException {
        checkClosed();
        syncColumns();
        return new SBResultSetMetaData(columns);
    }

    @Override
    public int findColumn(String columnLabel) throws SQLException {
        checkClosed();
        syncColumns();
        Integer index = columnNameIndex.get(columnLabel.toLowerCase());
        if (index == null) {
            throw new SQLException("Column not found: " + columnLabel, "42703");
        }
        return index;
    }

    @Override
    public boolean isBeforeFirst() throws SQLException {
        checkClosed();
        if (!rows.isEmpty()) {
            return currentRow < 0;
        }
        return currentRow < 0 && currentRowData == null && rowsRead == 0;
    }

    @Override
    public boolean isAfterLast() throws SQLException {
        checkClosed();
        if (!rows.isEmpty()) {
            return currentRow >= rows.size();
        }
        return stream != null && stream.isDone() && currentRowData == null;
    }

    @Override
    public boolean isFirst() throws SQLException {
        checkClosed();
        if (!rows.isEmpty()) {
            return currentRow == 0;
        }
        return rowsRead == 1 && currentRowData != null;
    }

    @Override
    public boolean isLast() throws SQLException {
        checkClosed();
        if (!rows.isEmpty()) {
            return currentRow == rows.size() - 1;
        }
        return stream != null && stream.isDone() && currentRowData != null;
    }

    @Override
    public void beforeFirst() throws SQLException {
        checkClosed();
        if (rows.isEmpty()) {
            throw new SQLException("ResultSet is forward-only", "0A000");
        }
        currentRow = -1;
        currentRowData = null;
    }

    @Override
    public void afterLast() throws SQLException {
        checkClosed();
        if (rows.isEmpty()) {
            throw new SQLException("ResultSet is forward-only", "0A000");
        }
        currentRow = rows.size();
        currentRowData = null;
    }

    @Override
    public boolean first() throws SQLException {
        checkClosed();
        if (rows.isEmpty()) {
            throw new SQLException("ResultSet is forward-only", "0A000");
        }
        if (rows.isEmpty()) return false;
        currentRow = 0;
        currentRowData = rows.get(0);
        return true;
    }

    @Override
    public boolean last() throws SQLException {
        checkClosed();
        if (rows.isEmpty()) {
            throw new SQLException("ResultSet is forward-only", "0A000");
        }
        if (rows.isEmpty()) return false;
        currentRow = rows.size() - 1;
        currentRowData = rows.get(currentRow);
        return true;
    }

    @Override
    public int getRow() throws SQLException {
        checkClosed();
        if (currentRowData == null) return 0;
        return currentRow + 1;  // 1-indexed for JDBC
    }

    @Override
    public boolean absolute(int row) throws SQLException {
        checkClosed();
        if (rows.isEmpty()) {
            throw new SQLException("ResultSet is forward-only", "0A000");
        }
        if (rows.isEmpty()) return false;

        if (row > 0) {
            currentRow = Math.min(row - 1, rows.size());
        } else if (row < 0) {
            currentRow = Math.max(rows.size() + row, -1);
        } else {
            currentRow = -1;
        }
        if (currentRow >= 0 && currentRow < rows.size()) {
            currentRowData = rows.get(currentRow);
            return true;
        }
        currentRowData = null;
        return false;
    }

    @Override
    public boolean relative(int rows) throws SQLException {
        checkClosed();
        return absolute(currentRow + 1 + rows);
    }

    @Override
    public boolean previous() throws SQLException {
        checkClosed();
        if (rows.isEmpty()) {
            throw new SQLException("ResultSet is forward-only", "0A000");
        }
        if (currentRow > 0) {
            currentRow--;
            return true;
        }
        currentRow = -1;
        return false;
    }

    @Override
    public void setFetchDirection(int direction) throws SQLException {
        checkClosed();
        this.fetchDirection = direction;
    }

    @Override
    public int getFetchDirection() throws SQLException {
        checkClosed();
        return fetchDirection;
    }

    @Override
    public void setFetchSize(int rows) throws SQLException {
        checkClosed();
        this.fetchSize = rows;
    }

    @Override
    public int getFetchSize() throws SQLException {
        checkClosed();
        return fetchSize;
    }

    @Override
    public int getType() throws SQLException {
        checkClosed();
        return ResultSet.TYPE_SCROLL_INSENSITIVE;
    }

    @Override
    public int getConcurrency() throws SQLException {
        checkClosed();
        return ResultSet.CONCUR_READ_ONLY;
    }

    // ==================== Update Methods (Read-Only) ====================

    @Override
    public boolean rowUpdated() throws SQLException {
        checkClosed();
        return false;
    }

    @Override
    public boolean rowInserted() throws SQLException {
        checkClosed();
        return false;
    }

    @Override
    public boolean rowDeleted() throws SQLException {
        checkClosed();
        return false;
    }

    @Override
    public void updateNull(int columnIndex) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBoolean(int columnIndex, boolean x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateByte(int columnIndex, byte x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateShort(int columnIndex, short x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateInt(int columnIndex, int x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateLong(int columnIndex, long x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateFloat(int columnIndex, float x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateDouble(int columnIndex, double x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBigDecimal(int columnIndex, BigDecimal x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateString(int columnIndex, String x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBytes(int columnIndex, byte[] x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateDate(int columnIndex, java.sql.Date x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateTime(int columnIndex, Time x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateTimestamp(int columnIndex, Timestamp x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateAsciiStream(int columnIndex, InputStream x, int length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBinaryStream(int columnIndex, InputStream x, int length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateCharacterStream(int columnIndex, Reader x, int length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateObject(int columnIndex, Object x, int scaleOrLength) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateObject(int columnIndex, Object x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    // String column variants - delegate to index versions
    @Override
    public void updateNull(String columnLabel) throws SQLException {
        updateNull(findColumn(columnLabel));
    }

    @Override
    public void updateBoolean(String columnLabel, boolean x) throws SQLException {
        updateBoolean(findColumn(columnLabel), x);
    }

    @Override
    public void updateByte(String columnLabel, byte x) throws SQLException {
        updateByte(findColumn(columnLabel), x);
    }

    @Override
    public void updateShort(String columnLabel, short x) throws SQLException {
        updateShort(findColumn(columnLabel), x);
    }

    @Override
    public void updateInt(String columnLabel, int x) throws SQLException {
        updateInt(findColumn(columnLabel), x);
    }

    @Override
    public void updateLong(String columnLabel, long x) throws SQLException {
        updateLong(findColumn(columnLabel), x);
    }

    @Override
    public void updateFloat(String columnLabel, float x) throws SQLException {
        updateFloat(findColumn(columnLabel), x);
    }

    @Override
    public void updateDouble(String columnLabel, double x) throws SQLException {
        updateDouble(findColumn(columnLabel), x);
    }

    @Override
    public void updateBigDecimal(String columnLabel, BigDecimal x) throws SQLException {
        updateBigDecimal(findColumn(columnLabel), x);
    }

    @Override
    public void updateString(String columnLabel, String x) throws SQLException {
        updateString(findColumn(columnLabel), x);
    }

    @Override
    public void updateBytes(String columnLabel, byte[] x) throws SQLException {
        updateBytes(findColumn(columnLabel), x);
    }

    @Override
    public void updateDate(String columnLabel, java.sql.Date x) throws SQLException {
        updateDate(findColumn(columnLabel), x);
    }

    @Override
    public void updateTime(String columnLabel, Time x) throws SQLException {
        updateTime(findColumn(columnLabel), x);
    }

    @Override
    public void updateTimestamp(String columnLabel, Timestamp x) throws SQLException {
        updateTimestamp(findColumn(columnLabel), x);
    }

    @Override
    public void updateAsciiStream(String columnLabel, InputStream x, int length) throws SQLException {
        updateAsciiStream(findColumn(columnLabel), x, length);
    }

    @Override
    public void updateBinaryStream(String columnLabel, InputStream x, int length) throws SQLException {
        updateBinaryStream(findColumn(columnLabel), x, length);
    }

    @Override
    public void updateCharacterStream(String columnLabel, Reader reader, int length) throws SQLException {
        updateCharacterStream(findColumn(columnLabel), reader, length);
    }

    @Override
    public void updateObject(String columnLabel, Object x, int scaleOrLength) throws SQLException {
        updateObject(findColumn(columnLabel), x, scaleOrLength);
    }

    @Override
    public void updateObject(String columnLabel, Object x) throws SQLException {
        updateObject(findColumn(columnLabel), x);
    }

    @Override
    public void insertRow() throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateRow() throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void deleteRow() throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void refreshRow() throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void cancelRowUpdates() throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void moveToInsertRow() throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void moveToCurrentRow() throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public Statement getStatement() throws SQLException {
        checkClosed();
        return statement;
    }

    // ==================== Additional Methods ====================

    @Override
    public Ref getRef(int columnIndex) throws SQLException {
        throw new SQLFeatureNotSupportedException("Ref not supported");
    }

    @Override
    public Ref getRef(String columnLabel) throws SQLException {
        throw new SQLFeatureNotSupportedException("Ref not supported");
    }

    @Override
    public Blob getBlob(int columnIndex) throws SQLException {
        byte[] bytes = getBytes(columnIndex);
        if (bytes == null) return null;
        return new SBBlob(bytes);
    }

    @Override
    public Blob getBlob(String columnLabel) throws SQLException {
        return getBlob(findColumn(columnLabel));
    }

    @Override
    public Clob getClob(int columnIndex) throws SQLException {
        String s = getString(columnIndex);
        if (s == null) return null;
        return new SBClob(s);
    }

    @Override
    public Clob getClob(String columnLabel) throws SQLException {
        return getClob(findColumn(columnLabel));
    }

    @Override
    public Array getArray(int columnIndex) throws SQLException {
        Object value = getObject(columnIndex);
        if (value == null) return null;
        if (value instanceof Array) return (Array) value;
        // Parse array string if needed
        throw new SQLException("Not an array type", "HY000");
    }

    @Override
    public Array getArray(String columnLabel) throws SQLException {
        return getArray(findColumn(columnLabel));
    }

    @Override
    public URL getURL(int columnIndex) throws SQLException {
        String s = getString(columnIndex);
        if (s == null) return null;
        try {
            return new URL(s);
        } catch (MalformedURLException e) {
            throw new SQLException("Invalid URL: " + s, "HY000", e);
        }
    }

    @Override
    public URL getURL(String columnLabel) throws SQLException {
        return getURL(findColumn(columnLabel));
    }

    @Override
    public void updateRef(int columnIndex, Ref x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Ref not supported");
    }

    @Override
    public void updateRef(String columnLabel, Ref x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Ref not supported");
    }

    @Override
    public void updateBlob(int columnIndex, Blob x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBlob(String columnLabel, Blob x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateClob(int columnIndex, Clob x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateClob(String columnLabel, Clob x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateArray(int columnIndex, Array x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateArray(String columnLabel, Array x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public RowId getRowId(int columnIndex) throws SQLException {
        throw new SQLFeatureNotSupportedException("RowId not supported");
    }

    @Override
    public RowId getRowId(String columnLabel) throws SQLException {
        throw new SQLFeatureNotSupportedException("RowId not supported");
    }

    @Override
    public void updateRowId(int columnIndex, RowId x) throws SQLException {
        throw new SQLFeatureNotSupportedException("RowId not supported");
    }

    @Override
    public void updateRowId(String columnLabel, RowId x) throws SQLException {
        throw new SQLFeatureNotSupportedException("RowId not supported");
    }

    @Override
    public int getHoldability() throws SQLException {
        checkClosed();
        return ResultSet.HOLD_CURSORS_OVER_COMMIT;
    }

    @Override
    public boolean isClosed() throws SQLException {
        return closed.get();
    }

    @Override
    public void updateNString(int columnIndex, String nString) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNString(String columnLabel, String nString) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNClob(int columnIndex, NClob nClob) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNClob(String columnLabel, NClob nClob) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public NClob getNClob(int columnIndex) throws SQLException {
        String s = getString(columnIndex);
        if (s == null) return null;
        return new SBNClob(s);
    }

    @Override
    public NClob getNClob(String columnLabel) throws SQLException {
        return getNClob(findColumn(columnLabel));
    }

    @Override
    public SQLXML getSQLXML(int columnIndex) throws SQLException {
        String s = getString(columnIndex);
        if (s == null) return null;
        return new SBSQLXML(s);
    }

    @Override
    public SQLXML getSQLXML(String columnLabel) throws SQLException {
        return getSQLXML(findColumn(columnLabel));
    }

    @Override
    public void updateSQLXML(int columnIndex, SQLXML xmlObject) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateSQLXML(String columnLabel, SQLXML xmlObject) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public String getNString(int columnIndex) throws SQLException {
        return getString(columnIndex);
    }

    @Override
    public String getNString(String columnLabel) throws SQLException {
        return getString(columnLabel);
    }

    @Override
    public Reader getNCharacterStream(int columnIndex) throws SQLException {
        return getCharacterStream(columnIndex);
    }

    @Override
    public Reader getNCharacterStream(String columnLabel) throws SQLException {
        return getCharacterStream(columnLabel);
    }

    @Override
    public void updateNCharacterStream(int columnIndex, Reader x, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNCharacterStream(String columnLabel, Reader reader, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateAsciiStream(int columnIndex, InputStream x, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBinaryStream(int columnIndex, InputStream x, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateCharacterStream(int columnIndex, Reader x, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateAsciiStream(String columnLabel, InputStream x, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBinaryStream(String columnLabel, InputStream x, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateCharacterStream(String columnLabel, Reader reader, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBlob(int columnIndex, InputStream inputStream, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBlob(String columnLabel, InputStream inputStream, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateClob(int columnIndex, Reader reader, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateClob(String columnLabel, Reader reader, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNClob(int columnIndex, Reader reader, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNClob(String columnLabel, Reader reader, long length) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNCharacterStream(int columnIndex, Reader x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNCharacterStream(String columnLabel, Reader reader) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateAsciiStream(int columnIndex, InputStream x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBinaryStream(int columnIndex, InputStream x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateCharacterStream(int columnIndex, Reader x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateAsciiStream(String columnLabel, InputStream x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBinaryStream(String columnLabel, InputStream x) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateCharacterStream(String columnLabel, Reader reader) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBlob(int columnIndex, InputStream inputStream) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateBlob(String columnLabel, InputStream inputStream) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateClob(int columnIndex, Reader reader) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateClob(String columnLabel, Reader reader) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNClob(int columnIndex, Reader reader) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public void updateNClob(String columnLabel, Reader reader) throws SQLException {
        throw new SQLFeatureNotSupportedException("Result set is read-only");
    }

    @Override
    public <T> T unwrap(Class<T> iface) throws SQLException {
        if (iface.isAssignableFrom(getClass())) {
            return iface.cast(this);
        }
        throw new SQLException("Cannot unwrap to " + iface.getName(), "0A000");
    }

    @Override
    public boolean isWrapperFor(Class<?> iface) throws SQLException {
        return iface.isAssignableFrom(getClass());
    }

    // ==================== Helper Methods ====================

    private void checkClosed() throws SQLException {
        if (closed.get()) {
            throw new SQLException("ResultSet is closed", "HY010");
        }
    }

    private void checkRow() throws SQLException {
        if (currentRowData == null) {
            throw new SQLException("Cursor not on a valid row", "HY109");
        }
    }

    private void checkColumnIndex(int columnIndex) throws SQLException {
        if (columnIndex < 1 || columnIndex > columns.size()) {
            throw new SQLException("Column index out of range: " + columnIndex +
                " (expected 1-" + columns.size() + ")", "42703");
        }
    }

    private void syncColumns() {
        if (stream == null) {
            return;
        }
        List<SBColumnInfo> updated = stream.getColumns();
        if (updated == null) {
            return;
        }
        if (columns != updated) {
            columns = updated;
            rebuildColumnIndex();
        }
    }

    private void rebuildColumnIndex() {
        columnNameIndex.clear();
        for (int i = 0; i < columns.size(); i++) {
            columnNameIndex.put(columns.get(i).getName().toLowerCase(), i + 1);
        }
    }

    private static final class ListRowStream implements SBRowStream {
        private final List<SBColumnInfo> columns;
        private final List<Object[]> rows;
        private int index = 0;

        ListRowStream(List<SBColumnInfo> columns, List<Object[]> rows) {
            this.columns = columns == null ? Collections.emptyList() : columns;
            this.rows = rows == null ? Collections.emptyList() : rows;
        }

        @Override
        public Object[] nextRow() {
            if (index >= rows.size()) {
                return null;
            }
            return rows.get(index++);
        }

        @Override
        public List<SBColumnInfo> getColumns() {
            return columns;
        }

        @Override
        public long getUpdateCount() {
            return -1;
        }

        @Override
        public String getCommandTag() {
            return null;
        }

        @Override
        public boolean isDone() {
            return index >= rows.size();
        }

        List<Object[]> getRows() {
            return rows;
        }
    }
}
