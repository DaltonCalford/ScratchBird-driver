/*
 * ScratchBird JDBC Driver
 */
package com.scratchbird.jdbc;

import java.sql.SQLException;
import java.util.List;

interface SBRowStream {
    Object[] nextRow() throws SQLException;
    List<SBColumnInfo> getColumns();
    long getUpdateCount();
    String getCommandTag();
    boolean isDone();
}
