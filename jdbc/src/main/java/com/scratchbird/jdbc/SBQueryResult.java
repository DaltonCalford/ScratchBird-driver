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

import java.util.*;

/**
 * Result from a query execution.
 */
public class SBQueryResult {
    private List<SBColumnInfo> columns;
    private List<Object[]> rows;
    private SBRowStream stream;
    private String commandTag;
    private long updateCount;

    public List<SBColumnInfo> getColumns() { return columns; }
    public void setColumns(List<SBColumnInfo> columns) { this.columns = columns; }

    public List<Object[]> getRows() { return rows; }
    public void setRows(List<Object[]> rows) { this.rows = rows; }

    public SBRowStream getStream() { return stream; }
    public void setStream(SBRowStream stream) { this.stream = stream; }

    public String getCommandTag() { return commandTag; }
    public void setCommandTag(String commandTag) { this.commandTag = commandTag; }

    public long getUpdateCount() { return updateCount; }
    public void setUpdateCount(long updateCount) { this.updateCount = updateCount; }
}
