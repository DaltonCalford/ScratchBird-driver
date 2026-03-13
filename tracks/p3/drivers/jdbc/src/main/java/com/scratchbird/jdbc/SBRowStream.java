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
