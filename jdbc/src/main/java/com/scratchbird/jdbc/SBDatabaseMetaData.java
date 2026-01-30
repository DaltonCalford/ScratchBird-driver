/*
 * ScratchBird JDBC Driver
 * Copyright (c) 2025 ScratchBird Project
 */
package com.scratchbird.jdbc;

import java.sql.*;
import java.util.*;
import java.util.regex.Pattern;

/**
 * JDBC DatabaseMetaData implementation for ScratchBird.
 */
public class SBDatabaseMetaData implements DatabaseMetaData {

    private final SBConnection connection;

    public SBDatabaseMetaData(SBConnection connection) {
        this.connection = connection;
    }

    @Override
    public boolean allProceduresAreCallable() throws SQLException {
        return true;
    }

    @Override
    public boolean allTablesAreSelectable() throws SQLException {
        return true;
    }

    @Override
    public String getURL() throws SQLException {
        SBConnectionProperties props = connection.getConnectionProperties();
        return "jdbc:scratchbird://" + props.getHost() + ":" + props.getPort() + "/" + props.getDatabase();
    }

    @Override
    public String getUserName() throws SQLException {
        return connection.getConnectionProperties().getUser();
    }

    @Override
    public boolean isReadOnly() throws SQLException {
        return connection.isReadOnly();
    }

    @Override
    public boolean nullsAreSortedHigh() throws SQLException {
        return true;  // ScratchBird sorts nulls high
    }

    @Override
    public boolean nullsAreSortedLow() throws SQLException {
        return false;
    }

    @Override
    public boolean nullsAreSortedAtStart() throws SQLException {
        return false;
    }

    @Override
    public boolean nullsAreSortedAtEnd() throws SQLException {
        return false;
    }

    @Override
    public String getDatabaseProductName() throws SQLException {
        return "ScratchBird";
    }

    @Override
    public String getDatabaseProductVersion() throws SQLException {
        return "1.0.0";
    }

    @Override
    public String getDriverName() throws SQLException {
        return SBDriver.DRIVER_NAME;
    }

    @Override
    public String getDriverVersion() throws SQLException {
        return SBDriver.VERSION;
    }

    @Override
    public int getDriverMajorVersion() {
        return SBDriver.MAJOR_VERSION;
    }

    @Override
    public int getDriverMinorVersion() {
        return SBDriver.MINOR_VERSION;
    }

    @Override
    public boolean usesLocalFiles() throws SQLException {
        return false;
    }

    @Override
    public boolean usesLocalFilePerTable() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsMixedCaseIdentifiers() throws SQLException {
        return false;
    }

    @Override
    public boolean storesUpperCaseIdentifiers() throws SQLException {
        return false;
    }

    @Override
    public boolean storesLowerCaseIdentifiers() throws SQLException {
        return true;
    }

    @Override
    public boolean storesMixedCaseIdentifiers() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsMixedCaseQuotedIdentifiers() throws SQLException {
        return true;
    }

    @Override
    public boolean storesUpperCaseQuotedIdentifiers() throws SQLException {
        return false;
    }

    @Override
    public boolean storesLowerCaseQuotedIdentifiers() throws SQLException {
        return false;
    }

    @Override
    public boolean storesMixedCaseQuotedIdentifiers() throws SQLException {
        return true;
    }

    @Override
    public String getIdentifierQuoteString() throws SQLException {
        return "\"";
    }

    @Override
    public String getSQLKeywords() throws SQLException {
        return "ABORT,ANALYSE,ANALYZE,ARRAY,BIGINT,BINARY,BIT,BOOLEAN,BOTH,CASE," +
               "CAST,CHAR,CHARACTER,CLUSTER,COALESCE,COLLATION,CONSTRAINT,COPY,CROSS," +
               "CURRENT,DATABASE,DEFAULT,DEFERRABLE,DESC,DISTINCT,DO,ELSE,END,EXCEPT," +
               "EXISTS,EXPLAIN,EXTEND,EXTRACT,FALSE,FETCH,FLOAT,FOR,FOREIGN,FROM,FULL," +
               "FUNCTION,GRANT,GROUP,HAVING,ILIKE,IN,INDEX,INITIALLY,INNER,INOUT,INTERSECT," +
               "INTO,IS,ISNULL,JOIN,LEADING,LEFT,LIKE,LIMIT,LISTEN,LOAD,LOCAL,LOCK,MOVE," +
               "NATURAL,NCHAR,NEW,NOT,NOTNULL,NULL,NULLIF,NUMERIC,OFF,OFFSET,OLD,ON,ONLY," +
               "OR,ORDER,OUTER,OVERLAPS,OVERLAY,PARTIAL,POSITION,PRECISION,PRIMARY,PRIVILEGES," +
               "PROCEDURE,PUBLIC,REFERENCES,REINDEX,RESET,RESTRICT,RETURNING,REVOKE,RIGHT," +
               "ROLLBACK,ROW,SAVEPOINT,SCHEMA,SELECT,SESSION,SETOF,SIMILAR,SOME,SUBSTRING," +
               "TABLE,THEN,TO,TRAILING,TRANSACTION,TREAT,TRIGGER,TRIM,TRUE,TRUNCATE,UNION," +
               "UNIQUE,UNKNOWN,UPDATE,USER,USING,VALUES,VARCHAR,VARYING,VERBOSE,VIEW,WHEN," +
               "WHERE,WITH";
    }

    @Override
    public String getNumericFunctions() throws SQLException {
        return "ABS,ACOS,ASIN,ATAN,ATAN2,CEILING,COS,COT,DEGREES,EXP,FLOOR,LOG,LOG10," +
               "MOD,PI,POWER,RADIANS,RAND,ROUND,SIGN,SIN,SQRT,TAN,TRUNCATE";
    }

    @Override
    public String getStringFunctions() throws SQLException {
        return "ASCII,CHAR,CONCAT,INSERT,LCASE,LEFT,LENGTH,LOCATE,LTRIM,REPEAT,REPLACE," +
               "RIGHT,RTRIM,SPACE,SUBSTRING,UCASE";
    }

    @Override
    public String getSystemFunctions() throws SQLException {
        return "DATABASE,IFNULL,USER";
    }

    @Override
    public String getTimeDateFunctions() throws SQLException {
        return "CURDATE,CURTIME,DAYNAME,DAYOFMONTH,DAYOFWEEK,DAYOFYEAR,HOUR,MINUTE," +
               "MONTH,MONTHNAME,NOW,QUARTER,SECOND,TIMESTAMPADD,TIMESTAMPDIFF,WEEK,YEAR";
    }

    @Override
    public String getSearchStringEscape() throws SQLException {
        return "\\";
    }

    @Override
    public String getExtraNameCharacters() throws SQLException {
        return "";
    }

    @Override
    public boolean supportsAlterTableWithAddColumn() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsAlterTableWithDropColumn() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsColumnAliasing() throws SQLException {
        return true;
    }

    @Override
    public boolean nullPlusNonNullIsNull() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsConvert() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsConvert(int fromType, int toType) throws SQLException {
        return false;
    }

    @Override
    public boolean supportsTableCorrelationNames() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsDifferentTableCorrelationNames() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsExpressionsInOrderBy() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsOrderByUnrelated() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsGroupBy() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsGroupByUnrelated() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsGroupByBeyondSelect() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsLikeEscapeClause() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsMultipleResultSets() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsMultipleTransactions() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsNonNullableColumns() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsMinimumSQLGrammar() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsCoreSQLGrammar() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsExtendedSQLGrammar() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsANSI92EntryLevelSQL() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsANSI92IntermediateSQL() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsANSI92FullSQL() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsIntegrityEnhancementFacility() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsOuterJoins() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsFullOuterJoins() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsLimitedOuterJoins() throws SQLException {
        return true;
    }

    @Override
    public String getSchemaTerm() throws SQLException {
        return "schema";
    }

    @Override
    public String getProcedureTerm() throws SQLException {
        return "function";
    }

    @Override
    public String getCatalogTerm() throws SQLException {
        return "database";
    }

    @Override
    public boolean isCatalogAtStart() throws SQLException {
        return true;
    }

    @Override
    public String getCatalogSeparator() throws SQLException {
        return ".";
    }

    @Override
    public boolean supportsSchemasInDataManipulation() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsSchemasInProcedureCalls() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsSchemasInTableDefinitions() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsSchemasInIndexDefinitions() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsSchemasInPrivilegeDefinitions() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsCatalogsInDataManipulation() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsCatalogsInProcedureCalls() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsCatalogsInTableDefinitions() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsCatalogsInIndexDefinitions() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsCatalogsInPrivilegeDefinitions() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsPositionedDelete() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsPositionedUpdate() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsSelectForUpdate() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsStoredProcedures() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsSubqueriesInComparisons() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsSubqueriesInExists() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsSubqueriesInIns() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsSubqueriesInQuantifieds() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsCorrelatedSubqueries() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsUnion() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsUnionAll() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsOpenCursorsAcrossCommit() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsOpenCursorsAcrossRollback() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsOpenStatementsAcrossCommit() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsOpenStatementsAcrossRollback() throws SQLException {
        return true;
    }

    @Override
    public int getMaxBinaryLiteralLength() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxCharLiteralLength() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxColumnNameLength() throws SQLException {
        return 63;
    }

    @Override
    public int getMaxColumnsInGroupBy() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxColumnsInIndex() throws SQLException {
        return 32;
    }

    @Override
    public int getMaxColumnsInOrderBy() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxColumnsInSelect() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxColumnsInTable() throws SQLException {
        return 1600;
    }

    @Override
    public int getMaxConnections() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxCursorNameLength() throws SQLException {
        return 63;
    }

    @Override
    public int getMaxIndexLength() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxSchemaNameLength() throws SQLException {
        return 63;
    }

    @Override
    public int getMaxProcedureNameLength() throws SQLException {
        return 63;
    }

    @Override
    public int getMaxCatalogNameLength() throws SQLException {
        return 63;
    }

    @Override
    public int getMaxRowSize() throws SQLException {
        return 1073741823;  // 1GB - 1
    }

    @Override
    public boolean doesMaxRowSizeIncludeBlobs() throws SQLException {
        return false;
    }

    @Override
    public int getMaxStatementLength() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxStatements() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxTableNameLength() throws SQLException {
        return 63;
    }

    @Override
    public int getMaxTablesInSelect() throws SQLException {
        return 0;  // No limit
    }

    @Override
    public int getMaxUserNameLength() throws SQLException {
        return 63;
    }

    @Override
    public int getDefaultTransactionIsolation() throws SQLException {
        return Connection.TRANSACTION_READ_COMMITTED;
    }

    @Override
    public boolean supportsTransactions() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsTransactionIsolationLevel(int level) throws SQLException {
        return level == Connection.TRANSACTION_READ_UNCOMMITTED ||
               level == Connection.TRANSACTION_READ_COMMITTED ||
               level == Connection.TRANSACTION_REPEATABLE_READ ||
               level == Connection.TRANSACTION_SERIALIZABLE ||
               level == SBConnection.TRANSACTION_SNAPSHOT;
    }

    @Override
    public boolean supportsDataDefinitionAndDataManipulationTransactions() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsDataManipulationTransactionsOnly() throws SQLException {
        return false;
    }

    @Override
    public boolean dataDefinitionCausesTransactionCommit() throws SQLException {
        return false;
    }

    @Override
    public boolean dataDefinitionIgnoredInTransactions() throws SQLException {
        return false;
    }

    @Override
    public ResultSet getProcedures(String catalog, String schemaPattern, String procedureNamePattern)
            throws SQLException {
        // Return empty result set for now
        return createEmptyResultSet(
            new String[]{"PROCEDURE_CAT", "PROCEDURE_SCHEM", "PROCEDURE_NAME", "reserved1",
                         "reserved2", "reserved3", "REMARKS", "PROCEDURE_TYPE", "SPECIFIC_NAME"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR,
                      Types.VARCHAR, Types.VARCHAR, Types.SMALLINT, Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getProcedureColumns(String catalog, String schemaPattern,
            String procedureNamePattern, String columnNamePattern) throws SQLException {
        // Return empty result set for now
        return createEmptyResultSet(
            new String[]{"PROCEDURE_CAT", "PROCEDURE_SCHEM", "PROCEDURE_NAME", "COLUMN_NAME",
                         "COLUMN_TYPE", "DATA_TYPE", "TYPE_NAME", "PRECISION", "LENGTH", "SCALE",
                         "RADIX", "NULLABLE", "REMARKS", "COLUMN_DEF", "SQL_DATA_TYPE",
                         "SQL_DATETIME_SUB", "CHAR_OCTET_LENGTH", "ORDINAL_POSITION", "IS_NULLABLE",
                         "SPECIFIC_NAME"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.SMALLINT,
                      Types.INTEGER, Types.VARCHAR, Types.INTEGER, Types.INTEGER, Types.SMALLINT,
                      Types.SMALLINT, Types.SMALLINT, Types.VARCHAR, Types.VARCHAR, Types.INTEGER,
                      Types.INTEGER, Types.INTEGER, Types.INTEGER, Types.VARCHAR, Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getTables(String catalog, String schemaPattern, String tableNamePattern, String[] types)
            throws SQLException {
        String currentCatalog = connection.getConnectionProperties().getDatabase();
        if (catalog != null && currentCatalog != null && !catalog.equalsIgnoreCase(currentCatalog)) {
            return createEmptyResultSet(
                new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "TABLE_TYPE", "REMARKS",
                             "TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "SELF_REFERENCING_COL_NAME",
                             "REF_GENERATION"},
                new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR,
                          Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR}
            );
        }

        Set<String> typeFilter = normalizeTypes(types);
        List<Object[]> rows = new ArrayList<>();

        for (Object[] row : queryRows(
            "SELECT t.table_name, t.table_type, s.schema_name " +
            "FROM sys.tables t " +
            "JOIN sys.schemas s ON s.schema_id = t.schema_id " +
            "WHERE t.is_valid = 1 AND s.is_valid = 1"
        )) {
            String tableName = toStringValue(row, 0);
            String schemaName = toStringValue(row, 2);
            if (!matchesPattern(schemaName, schemaPattern) || !matchesPattern(tableName, tableNamePattern)) {
                continue;
            }
            String tableType = mapTableType(row[1], schemaName, false);
            if (!matchesTypeFilter(tableType, typeFilter)) {
                continue;
            }
            rows.add(new Object[]{
                currentCatalog,
                schemaName,
                tableName,
                tableType,
                null,
                null,
                null,
                null,
                null,
                null
            });
        }

        for (Object[] row : queryRows(
            "SELECT v.view_name, v.is_materialized, s.schema_name " +
            "FROM sys.views v " +
            "JOIN sys.schemas s ON s.schema_id = v.schema_id " +
            "WHERE v.is_valid = 1 AND s.is_valid = 1"
        )) {
            String viewName = toStringValue(row, 0);
            String schemaName = toStringValue(row, 2);
            if (!matchesPattern(schemaName, schemaPattern) || !matchesPattern(viewName, tableNamePattern)) {
                continue;
            }
            String tableType = mapTableType(row[1], schemaName, true);
            if (!matchesTypeFilter(tableType, typeFilter)) {
                continue;
            }
            rows.add(new Object[]{
                currentCatalog,
                schemaName,
                viewName,
                tableType,
                null,
                null,
                null,
                null,
                null,
                null
            });
        }

        if (matchesTypeFilter("SYSTEM VIEW", typeFilter)) {
            Set<String> existing = new HashSet<>();
            for (Object[] row : rows) {
                if (row[2] != null && row[1] != null) {
                    existing.add(row[1].toString().toLowerCase() + "." + row[2].toString().toLowerCase());
                }
            }
            for (String name : monitoringViews()) {
                if (!matchesPattern("sys", schemaPattern) || !matchesPattern(name, tableNamePattern)) {
                    continue;
                }
                String key = "sys." + name.toLowerCase();
                if (existing.contains(key)) {
                    continue;
                }
                rows.add(new Object[]{
                    currentCatalog,
                    "sys",
                    name,
                    "SYSTEM VIEW",
                    null,
                    null,
                    null,
                    null,
                    null,
                    null
                });
            }
        }

        List<SBColumnInfo> cols = new ArrayList<>();
        cols.add(column("TABLE_CAT", 25));
        cols.add(column("TABLE_SCHEM", 25));
        cols.add(column("TABLE_NAME", 25));
        cols.add(column("TABLE_TYPE", 25));
        cols.add(column("REMARKS", 25));
        cols.add(column("TYPE_CAT", 25));
        cols.add(column("TYPE_SCHEM", 25));
        cols.add(column("TYPE_NAME", 25));
        cols.add(column("SELF_REFERENCING_COL_NAME", 25));
        cols.add(column("REF_GENERATION", 25));
        return new SBResultSet(null, cols, rows);
    }

    @Override
    public ResultSet getSchemas() throws SQLException {
        return getSchemas(null, null);
    }

    @Override
    public ResultSet getSchemas(String catalog, String schemaPattern) throws SQLException {
        String currentCatalog = connection.getConnectionProperties().getDatabase();
        if (catalog != null && currentCatalog != null && !catalog.equalsIgnoreCase(currentCatalog)) {
            return createEmptyResultSet(
                new String[]{"TABLE_SCHEM", "TABLE_CATALOG"},
                new int[]{Types.VARCHAR, Types.VARCHAR}
            );
        }
        List<Object[]> rows = new ArrayList<>();
        for (Object[] row : queryRows("SELECT schema_name FROM sys.schemas WHERE is_valid = 1")) {
            String schemaName = toStringValue(row, 0);
            if (!matchesPattern(schemaName, schemaPattern)) {
                continue;
            }
            rows.add(new Object[]{schemaName, currentCatalog});
        }
        List<SBColumnInfo> cols = new ArrayList<>();
        cols.add(column("TABLE_SCHEM", 25));
        cols.add(column("TABLE_CATALOG", 25));
        return new SBResultSet(null, cols, rows);
    }

    @Override
    public ResultSet getCatalogs() throws SQLException {
        List<Object[]> rows = new ArrayList<>();
        String currentCatalog = connection.getConnectionProperties().getDatabase();
        if (currentCatalog != null && !currentCatalog.isEmpty()) {
            rows.add(new Object[]{currentCatalog});
        }
        List<SBColumnInfo> cols = new ArrayList<>();
        cols.add(column("TABLE_CAT", 25));
        return new SBResultSet(null, cols, rows);
    }

    @Override
    public ResultSet getTableTypes() throws SQLException {
        List<SBColumnInfo> cols = new ArrayList<>();
        SBColumnInfo col = new SBColumnInfo();
        col.setName("TABLE_TYPE");
        col.setTypeOid(25);  // text
        cols.add(col);

        List<Object[]> rows = new ArrayList<>();
        rows.add(new Object[]{"TABLE"});
        rows.add(new Object[]{"VIEW"});
        rows.add(new Object[]{"SYSTEM TABLE"});
        rows.add(new Object[]{"SYSTEM VIEW"});
        rows.add(new Object[]{"FOREIGN TABLE"});
        rows.add(new Object[]{"MATERIALIZED VIEW"});

        return new SBResultSet(null, cols, rows);
    }

    @Override
    public ResultSet getColumns(String catalog, String schemaPattern, String tableNamePattern,
            String columnNamePattern) throws SQLException {
        String currentCatalog = connection.getConnectionProperties().getDatabase();
        if (catalog != null && currentCatalog != null && !catalog.equalsIgnoreCase(currentCatalog)) {
            return createEmptyResultSet(
                new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "COLUMN_NAME", "DATA_TYPE",
                             "TYPE_NAME", "COLUMN_SIZE", "BUFFER_LENGTH", "DECIMAL_DIGITS",
                             "NUM_PREC_RADIX", "NULLABLE", "REMARKS", "COLUMN_DEF", "SQL_DATA_TYPE",
                             "SQL_DATETIME_SUB", "CHAR_OCTET_LENGTH", "ORDINAL_POSITION", "IS_NULLABLE",
                             "SCOPE_CATALOG", "SCOPE_SCHEMA", "SCOPE_TABLE", "SOURCE_DATA_TYPE",
                             "IS_AUTOINCREMENT", "IS_GENERATEDCOLUMN"},
                new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.INTEGER,
                          Types.VARCHAR, Types.INTEGER, Types.INTEGER, Types.INTEGER, Types.INTEGER,
                          Types.INTEGER, Types.VARCHAR, Types.VARCHAR, Types.INTEGER, Types.INTEGER,
                          Types.INTEGER, Types.INTEGER, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR,
                          Types.VARCHAR, Types.SMALLINT, Types.VARCHAR, Types.VARCHAR}
            );
        }

        List<Object[]> rows = new ArrayList<>();
        for (Object[] row : queryRows(
            "SELECT c.column_name, c.data_type_id, c.ordinal_position, c.is_nullable, c.default_value, " +
            "t.table_name, s.schema_name " +
            "FROM sys.columns c " +
            "JOIN sys.tables t ON t.table_id = c.table_id " +
            "JOIN sys.schemas s ON s.schema_id = t.schema_id " +
            "WHERE c.is_valid = 1 AND t.is_valid = 1 AND s.is_valid = 1"
        )) {
            String columnName = toStringValue(row, 0);
            String tableName = toStringValue(row, 5);
            String schemaName = toStringValue(row, 6);
            if (!matchesPattern(schemaName, schemaPattern) ||
                !matchesPattern(tableName, tableNamePattern) ||
                !matchesPattern(columnName, columnNamePattern)) {
                continue;
            }

            Object typeValue = row[1];
            Integer oid = parseOid(typeValue);
            String typeName = oid != null ? typeNameFromOid(oid) : toStringValue(typeValue);
            int jdbcType = oid != null ? jdbcTypeFromOid(oid) : jdbcTypeFromTypeName(typeName);

            int ordinal = toIntValue(row[2], 0);
            boolean nullable = toBooleanValue(row[3]);
            String nullableText = nullable ? "YES" : "NO";
            int nullableFlag = nullable ? DatabaseMetaData.columnNullable : DatabaseMetaData.columnNoNulls;
            String defaultValue = toStringValue(row, 4);

            rows.add(new Object[]{
                currentCatalog,
                schemaName,
                tableName,
                columnName,
                jdbcType,
                typeName,
                0,
                0,
                0,
                10,
                nullableFlag,
                null,
                defaultValue,
                null,
                null,
                0,
                ordinal,
                nullableText,
                null,
                null,
                null,
                null,
                "NO",
                "NO"
            });
        }

        List<SBColumnInfo> cols = new ArrayList<>();
        cols.add(column("TABLE_CAT", 25));
        cols.add(column("TABLE_SCHEM", 25));
        cols.add(column("TABLE_NAME", 25));
        cols.add(column("COLUMN_NAME", 25));
        cols.add(column("DATA_TYPE", 23));
        cols.add(column("TYPE_NAME", 25));
        cols.add(column("COLUMN_SIZE", 23));
        cols.add(column("BUFFER_LENGTH", 23));
        cols.add(column("DECIMAL_DIGITS", 23));
        cols.add(column("NUM_PREC_RADIX", 23));
        cols.add(column("NULLABLE", 23));
        cols.add(column("REMARKS", 25));
        cols.add(column("COLUMN_DEF", 25));
        cols.add(column("SQL_DATA_TYPE", 23));
        cols.add(column("SQL_DATETIME_SUB", 23));
        cols.add(column("CHAR_OCTET_LENGTH", 23));
        cols.add(column("ORDINAL_POSITION", 23));
        cols.add(column("IS_NULLABLE", 25));
        cols.add(column("SCOPE_CATALOG", 25));
        cols.add(column("SCOPE_SCHEMA", 25));
        cols.add(column("SCOPE_TABLE", 25));
        cols.add(column("SOURCE_DATA_TYPE", 21));
        cols.add(column("IS_AUTOINCREMENT", 25));
        cols.add(column("IS_GENERATEDCOLUMN", 25));
        return new SBResultSet(null, cols, rows);
    }

    @Override
    public ResultSet getColumnPrivileges(String catalog, String schema, String table,
            String columnNamePattern) throws SQLException {
        return createEmptyResultSet(
            new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "COLUMN_NAME", "GRANTOR",
                         "GRANTEE", "PRIVILEGE", "IS_GRANTABLE"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR,
                      Types.VARCHAR, Types.VARCHAR, Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getTablePrivileges(String catalog, String schemaPattern, String tableNamePattern)
            throws SQLException {
        return createEmptyResultSet(
            new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "GRANTOR", "GRANTEE",
                         "PRIVILEGE", "IS_GRANTABLE"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR,
                      Types.VARCHAR, Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getBestRowIdentifier(String catalog, String schema, String table,
            int scope, boolean nullable) throws SQLException {
        return createEmptyResultSet(
            new String[]{"SCOPE", "COLUMN_NAME", "DATA_TYPE", "TYPE_NAME", "COLUMN_SIZE",
                         "BUFFER_LENGTH", "DECIMAL_DIGITS", "PSEUDO_COLUMN"},
            new int[]{Types.SMALLINT, Types.VARCHAR, Types.INTEGER, Types.VARCHAR, Types.INTEGER,
                      Types.INTEGER, Types.SMALLINT, Types.SMALLINT}
        );
    }

    @Override
    public ResultSet getVersionColumns(String catalog, String schema, String table) throws SQLException {
        return createEmptyResultSet(
            new String[]{"SCOPE", "COLUMN_NAME", "DATA_TYPE", "TYPE_NAME", "COLUMN_SIZE",
                         "BUFFER_LENGTH", "DECIMAL_DIGITS", "PSEUDO_COLUMN"},
            new int[]{Types.SMALLINT, Types.VARCHAR, Types.INTEGER, Types.VARCHAR, Types.INTEGER,
                      Types.INTEGER, Types.SMALLINT, Types.SMALLINT}
        );
    }

    @Override
    public ResultSet getPrimaryKeys(String catalog, String schema, String table) throws SQLException {
        String currentCatalog = connection.getConnectionProperties().getDatabase();
        List<Object[]> source;
        try {
            source = queryRows(
                "SELECT tc.table_schema, tc.table_name, kcu.column_name, kcu.ordinal_position, tc.constraint_name " +
                    "FROM information_schema.table_constraints tc " +
                    "JOIN information_schema.key_column_usage kcu " +
                    "  ON tc.constraint_name = kcu.constraint_name " +
                    " AND tc.table_schema = kcu.table_schema " +
                    " AND tc.table_name = kcu.table_name " +
                    "WHERE tc.constraint_type = 'PRIMARY KEY'"
            );
        } catch (SQLException e) {
            source = Collections.emptyList();
        }

        List<Object[]> rows = new ArrayList<>();
        for (Object[] row : source) {
            String schemaName = toStringValue(row, 0);
            String tableName = toStringValue(row, 1);
            if (!matchesPattern(schemaName, schema) || !matchesPattern(tableName, table)) {
                continue;
            }
            String columnName = toStringValue(row, 2);
            short keySeq = toShortValue(row, 3);
            String pkName = toStringValue(row, 4);
            rows.add(new Object[]{currentCatalog, schemaName, tableName, columnName, keySeq, pkName});
        }

        List<SBColumnInfo> cols = new ArrayList<>();
        cols.add(column("TABLE_CAT", 25));
        cols.add(column("TABLE_SCHEM", 25));
        cols.add(column("TABLE_NAME", 25));
        cols.add(column("COLUMN_NAME", 25));
        cols.add(column("KEY_SEQ", 21));
        cols.add(column("PK_NAME", 25));
        return new SBResultSet(null, cols, rows);
    }

    @Override
    public ResultSet getImportedKeys(String catalog, String schema, String table) throws SQLException {
        String currentCatalog = connection.getConnectionProperties().getDatabase();
        List<Object[]> source;
        try {
            source = queryRows(
                "SELECT tc.table_schema AS fk_schema, tc.table_name AS fk_table, " +
                    "kcu.column_name AS fk_column, ccu.table_schema AS pk_schema, " +
                    "ccu.table_name AS pk_table, ccu.column_name AS pk_column, " +
                    "kcu.ordinal_position AS key_seq, rc.update_rule, rc.delete_rule, " +
                    "tc.constraint_name AS fk_name, rc.unique_constraint_name AS pk_name, " +
                    "rc.deferrable AS deferrable " +
                    "FROM information_schema.table_constraints tc " +
                    "JOIN information_schema.key_column_usage kcu " +
                    "  ON tc.constraint_name = kcu.constraint_name " +
                    " AND tc.table_schema = kcu.table_schema " +
                    " AND tc.table_name = kcu.table_name " +
                    "JOIN information_schema.constraint_column_usage ccu " +
                    "  ON ccu.constraint_name = tc.constraint_name " +
                    " AND ccu.constraint_schema = tc.table_schema " +
                    "LEFT JOIN information_schema.referential_constraints rc " +
                    "  ON rc.constraint_name = tc.constraint_name " +
                    " AND rc.constraint_schema = tc.table_schema " +
                    "WHERE tc.constraint_type = 'FOREIGN KEY'"
            );
        } catch (SQLException e) {
            source = Collections.emptyList();
        }

        List<Object[]> rows = new ArrayList<>();
        for (Object[] row : source) {
            String fkSchema = toStringValue(row, 0);
            String fkTable = toStringValue(row, 1);
            if (!matchesPattern(fkSchema, schema) || !matchesPattern(fkTable, table)) {
                continue;
            }
            String fkColumn = toStringValue(row, 2);
            String pkSchema = toStringValue(row, 3);
            String pkTable = toStringValue(row, 4);
            String pkColumn = toStringValue(row, 5);
            short keySeq = toShortValue(row, 6);
            short updateRule = mapRule(toStringValue(row, 7));
            short deleteRule = mapRule(toStringValue(row, 8));
            String fkName = toStringValue(row, 9);
            String pkName = toStringValue(row, 10);
            short deferrability = mapDeferrable(toStringValue(row, 11));

            rows.add(new Object[]{
                currentCatalog, pkSchema, pkTable, pkColumn,
                currentCatalog, fkSchema, fkTable, fkColumn,
                keySeq, updateRule, deleteRule, fkName, pkName, deferrability
            });
        }

        List<SBColumnInfo> cols = new ArrayList<>();
        cols.add(column("PKTABLE_CAT", 25));
        cols.add(column("PKTABLE_SCHEM", 25));
        cols.add(column("PKTABLE_NAME", 25));
        cols.add(column("PKCOLUMN_NAME", 25));
        cols.add(column("FKTABLE_CAT", 25));
        cols.add(column("FKTABLE_SCHEM", 25));
        cols.add(column("FKTABLE_NAME", 25));
        cols.add(column("FKCOLUMN_NAME", 25));
        cols.add(column("KEY_SEQ", 21));
        cols.add(column("UPDATE_RULE", 21));
        cols.add(column("DELETE_RULE", 21));
        cols.add(column("FK_NAME", 25));
        cols.add(column("PK_NAME", 25));
        cols.add(column("DEFERRABILITY", 21));
        return new SBResultSet(null, cols, rows);
    }

    @Override
    public ResultSet getExportedKeys(String catalog, String schema, String table) throws SQLException {
        return getImportedKeys(catalog, schema, table);
    }

    @Override
    public ResultSet getCrossReference(String parentCatalog, String parentSchema, String parentTable,
            String foreignCatalog, String foreignSchema, String foreignTable) throws SQLException {
        return getImportedKeys(foreignCatalog, foreignSchema, foreignTable);
    }

    @Override
    public ResultSet getTypeInfo() throws SQLException {
        List<Object[]> rows = new ArrayList<>();
        rows.add(typeInfoRow("BOOLEAN", Types.BOOLEAN, 1, null));
        rows.add(typeInfoRow("SMALLINT", Types.SMALLINT, 5, null));
        rows.add(typeInfoRow("INTEGER", Types.INTEGER, 10, null));
        rows.add(typeInfoRow("BIGINT", Types.BIGINT, 19, null));
        rows.add(typeInfoRow("REAL", Types.REAL, 24, null));
        rows.add(typeInfoRow("DOUBLE", Types.DOUBLE, 53, null));
        rows.add(typeInfoRow("NUMERIC", Types.NUMERIC, 38, "precision,scale"));
        rows.add(typeInfoRow("DECIMAL", Types.DECIMAL, 38, "precision,scale"));
        rows.add(typeInfoRow("CHAR", Types.CHAR, 255, "length"));
        rows.add(typeInfoRow("VARCHAR", Types.VARCHAR, 65535, "length"));
        rows.add(typeInfoRow("TEXT", Types.LONGVARCHAR, 2147483647, null));
        rows.add(typeInfoRow("BYTEA", Types.BINARY, 2147483647, null));
        rows.add(typeInfoRow("DATE", Types.DATE, 10, null));
        rows.add(typeInfoRow("TIME", Types.TIME, 15, null));
        rows.add(typeInfoRow("TIMESTAMP", Types.TIMESTAMP, 29, null));
        rows.add(typeInfoRow("TIMESTAMPTZ", Types.TIMESTAMP_WITH_TIMEZONE, 35, null));
        rows.add(typeInfoRow("UUID", Types.OTHER, 16, null));
        rows.add(typeInfoRow("JSON", Types.OTHER, 2147483647, null));
        rows.add(typeInfoRow("JSONB", Types.OTHER, 2147483647, null));

        List<SBColumnInfo> cols = new ArrayList<>();
        cols.add(column("TYPE_NAME", 25));
        cols.add(column("DATA_TYPE", 23));
        cols.add(column("PRECISION", 23));
        cols.add(column("LITERAL_PREFIX", 25));
        cols.add(column("LITERAL_SUFFIX", 25));
        cols.add(column("CREATE_PARAMS", 25));
        cols.add(column("NULLABLE", 21));
        cols.add(column("CASE_SENSITIVE", 16));
        cols.add(column("SEARCHABLE", 21));
        cols.add(column("UNSIGNED_ATTRIBUTE", 16));
        cols.add(column("FIXED_PREC_SCALE", 16));
        cols.add(column("AUTO_INCREMENT", 16));
        cols.add(column("LOCAL_TYPE_NAME", 25));
        cols.add(column("MINIMUM_SCALE", 21));
        cols.add(column("MAXIMUM_SCALE", 21));
        cols.add(column("SQL_DATA_TYPE", 23));
        cols.add(column("SQL_DATETIME_SUB", 23));
        cols.add(column("NUM_PREC_RADIX", 23));
        return new SBResultSet(null, cols, rows);
    }

    @Override
    public ResultSet getIndexInfo(String catalog, String schema, String table, boolean unique,
            boolean approximate) throws SQLException {
        String currentCatalog = connection.getConnectionProperties().getDatabase();
        if (catalog != null && currentCatalog != null && !catalog.equalsIgnoreCase(currentCatalog)) {
            return createEmptyResultSet(
                new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "NON_UNIQUE", "INDEX_QUALIFIER",
                             "INDEX_NAME", "TYPE", "ORDINAL_POSITION", "COLUMN_NAME", "ASC_OR_DESC",
                             "CARDINALITY", "PAGES", "FILTER_CONDITION"},
                new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.BOOLEAN, Types.VARCHAR,
                          Types.VARCHAR, Types.SMALLINT, Types.SMALLINT, Types.VARCHAR, Types.VARCHAR,
                          Types.BIGINT, Types.BIGINT, Types.VARCHAR}
            );
        }

        List<Object[]> rows = new ArrayList<>();
        boolean hasColumnInfo = true;
        Iterable<Object[]> resultRows;
        try {
            resultRows = queryRows(
                "SELECT i.index_name, i.index_type, i.is_unique, " +
                "t.table_name, s.schema_name, ic.ordinal_position, c.column_name " +
                "FROM sys.indexes i " +
                "JOIN sys.tables t ON t.table_id = i.table_id " +
                "JOIN sys.schemas s ON s.schema_id = t.schema_id " +
                "LEFT JOIN sys.index_columns ic ON ic.index_id = i.index_id " +
                "LEFT JOIN sys.columns c ON c.column_id = ic.column_id " +
                "WHERE i.is_valid = 1 AND t.is_valid = 1 AND s.is_valid = 1 " +
                "ORDER BY i.index_name, ic.ordinal_position"
            );
        } catch (SQLException ex) {
            hasColumnInfo = false;
            resultRows = queryRows(
                "SELECT i.index_name, i.index_type, i.is_unique, " +
                "t.table_name, s.schema_name " +
                "FROM sys.indexes i " +
                "JOIN sys.tables t ON t.table_id = i.table_id " +
                "JOIN sys.schemas s ON s.schema_id = t.schema_id " +
                "WHERE i.is_valid = 1 AND t.is_valid = 1 AND s.is_valid = 1"
            );
        }

        for (Object[] row : resultRows) {
            String indexName = toStringValue(row, 0);
            String tableName = toStringValue(row, 3);
            String schemaName = toStringValue(row, 4);
            if (!matchesPattern(schemaName, schema) || !matchesPattern(tableName, table)) {
                continue;
            }
            boolean isUnique = toBooleanValue(row[2]);
            if (unique && !isUnique) {
                continue;
            }

            Short ordinal = 0;
            String columnName = null;
            if (hasColumnInfo && row.length > 6) {
                ordinal = toShortValue(row, 5);
                columnName = toStringValue(row, 6);
            }

            rows.add(new Object[]{
                currentCatalog,
                schemaName,
                tableName,
                !isUnique,
                null,
                indexName,
                DatabaseMetaData.tableIndexOther,
                ordinal,
                columnName,
                null,
                0,
                0,
                null
            });
        }

        List<SBColumnInfo> cols = new ArrayList<>();
        cols.add(column("TABLE_CAT", 25));
        cols.add(column("TABLE_SCHEM", 25));
        cols.add(column("TABLE_NAME", 25));
        cols.add(column("NON_UNIQUE", 16));
        cols.add(column("INDEX_QUALIFIER", 25));
        cols.add(column("INDEX_NAME", 25));
        cols.add(column("TYPE", 21));
        cols.add(column("ORDINAL_POSITION", 21));
        cols.add(column("COLUMN_NAME", 25));
        cols.add(column("ASC_OR_DESC", 25));
        cols.add(column("CARDINALITY", 20));
        cols.add(column("PAGES", 20));
        cols.add(column("FILTER_CONDITION", 25));
        return new SBResultSet(null, cols, rows);
    }

    private List<Object[]> queryRows(String sql) throws SQLException {
        SBQueryResult result = connection.getProtocol().execute(sql);
        if (result == null || result.getRows() == null) {
            return Collections.emptyList();
        }
        return result.getRows();
    }

    private boolean matchesPattern(String value, String pattern) {
        if (pattern == null || pattern.isEmpty()) {
            return true;
        }
        if (value == null) {
            return false;
        }
        return Pattern.compile(patternToRegex(pattern), Pattern.CASE_INSENSITIVE).matcher(value).matches();
    }

    private String patternToRegex(String pattern) {
        StringBuilder out = new StringBuilder("^");
        boolean escaped = false;
        for (int i = 0; i < pattern.length(); i++) {
            char ch = pattern.charAt(i);
            if (escaped) {
                out.append(Pattern.quote(String.valueOf(ch)));
                escaped = false;
                continue;
            }
            if (ch == '\\') {
                escaped = true;
                continue;
            }
            if (ch == '%') {
                out.append(".*");
            } else if (ch == '_') {
                out.append('.');
            } else {
                out.append(Pattern.quote(String.valueOf(ch)));
            }
        }
        out.append('$');
        return out.toString();
    }

    private SBColumnInfo column(String name, int typeOid) {
        SBColumnInfo col = new SBColumnInfo();
        col.setName(name);
        col.setTypeOid(typeOid);
        return col;
    }

    private String toStringValue(Object[] row, int index) {
        if (row == null || index < 0 || index >= row.length) {
            return null;
        }
        return toStringValue(row[index]);
    }

    private String toStringValue(Object value) {
        if (value == null) {
            return null;
        }
        return value.toString();
    }

    private int toIntValue(Object value, int fallback) {
        if (value == null) {
            return fallback;
        }
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        try {
            return Integer.parseInt(value.toString());
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private short toShortValue(Object[] row, int index) {
        if (row == null || index < 0 || index >= row.length) {
            return 0;
        }
        return toShortValue(row[index]);
    }

    private short toShortValue(Object value) {
        if (value == null) {
            return 0;
        }
        if (value instanceof Number) {
            return ((Number) value).shortValue();
        }
        try {
            return Short.parseShort(value.toString());
        } catch (NumberFormatException ex) {
            return 0;
        }
    }

    private boolean toBooleanValue(Object value) {
        if (value == null) {
            return false;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        if (value instanceof Number) {
            return ((Number) value).intValue() != 0;
        }
        String text = value.toString().trim();
        if ("1".equals(text)) {
            return true;
        }
        if ("0".equals(text)) {
            return false;
        }
        return Boolean.parseBoolean(text);
    }

    private short mapRule(String rule) {
        if (rule == null) {
            return DatabaseMetaData.importedKeyNoAction;
        }
        String normalized = rule.trim().toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case "CASCADE" -> DatabaseMetaData.importedKeyCascade;
            case "SET NULL" -> DatabaseMetaData.importedKeySetNull;
            case "SET DEFAULT" -> DatabaseMetaData.importedKeySetDefault;
            case "RESTRICT" -> DatabaseMetaData.importedKeyRestrict;
            case "NO ACTION" -> DatabaseMetaData.importedKeyNoAction;
            default -> DatabaseMetaData.importedKeyNoAction;
        };
    }

    private short mapDeferrable(String deferrable) {
        if (deferrable == null) {
            return DatabaseMetaData.importedKeyNotDeferrable;
        }
        String normalized = deferrable.trim().toUpperCase(Locale.ROOT);
        if (normalized.contains("DEFERRED")) {
            return DatabaseMetaData.importedKeyInitiallyDeferred;
        }
        if (normalized.contains("NOT")) {
            return DatabaseMetaData.importedKeyNotDeferrable;
        }
        return DatabaseMetaData.importedKeyInitiallyImmediate;
    }

    private Object[] typeInfoRow(String typeName, int dataType, int precision, String createParams) {
        String literalPrefix = null;
        String literalSuffix = null;
        boolean caseSensitive = false;
        if (dataType == Types.CHAR || dataType == Types.VARCHAR || dataType == Types.LONGVARCHAR) {
            literalPrefix = "'";
            literalSuffix = "'";
            caseSensitive = true;
        }
        short searchable = DatabaseMetaData.typeSearchable;
        boolean unsigned = false;
        boolean fixedScale = false;
        boolean autoIncrement = false;
        String localTypeName = typeName;
        Short minScale = null;
        Short maxScale = null;
        if (dataType == Types.NUMERIC || dataType == Types.DECIMAL) {
            minScale = 0;
            maxScale = 38;
        }
        Integer numPrecRadix = 10;
        return new Object[]{
            typeName,
            dataType,
            precision,
            literalPrefix,
            literalSuffix,
            createParams,
            DatabaseMetaData.typeNullable,
            caseSensitive,
            searchable,
            unsigned,
            fixedScale,
            autoIncrement,
            localTypeName,
            minScale,
            maxScale,
            null,
            null,
            numPrecRadix
        };
    }

    private Integer parseOid(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        try {
            String text = value.toString();
            if (text.matches("^[0-9]+$")) {
                return Integer.parseInt(text);
            }
        } catch (NumberFormatException ex) {
            return null;
        }
        return null;
    }

    private String typeNameFromOid(int oid) {
        switch (oid) {
            case SBTypeCodec.OID_BOOL:
                return "boolean";
            case SBTypeCodec.OID_CHAR:
                return "char";
            case SBTypeCodec.OID_INT2:
                return "int2";
            case SBTypeCodec.OID_INT4:
                return "int4";
            case SBTypeCodec.OID_INT8:
                return "int8";
            case SBTypeCodec.OID_FLOAT4:
                return "float4";
            case SBTypeCodec.OID_FLOAT8:
                return "float8";
            case SBTypeCodec.OID_NUMERIC:
                return "numeric";
            case SBTypeCodec.OID_MONEY:
                return "money";
            case SBTypeCodec.OID_TEXT:
                return "text";
            case SBTypeCodec.OID_VARCHAR:
                return "varchar";
            case SBTypeCodec.OID_BPCHAR:
                return "char";
            case SBTypeCodec.OID_DATE:
                return "date";
            case SBTypeCodec.OID_TIME:
                return "time";
            case SBTypeCodec.OID_TIMESTAMP:
                return "timestamp";
            case SBTypeCodec.OID_TIMESTAMPTZ:
                return "timestamptz";
            case SBTypeCodec.OID_INTERVAL:
                return "interval";
            case SBTypeCodec.OID_UUID:
                return "uuid";
            case SBTypeCodec.OID_JSON:
                return "json";
            case SBTypeCodec.OID_JSONB:
                return "jsonb";
            case SBTypeCodec.OID_XML:
                return "xml";
            case SBTypeCodec.OID_BYTEA:
                return "bytea";
            case SBTypeCodec.OID_INET:
                return "inet";
            case SBTypeCodec.OID_CIDR:
                return "cidr";
            case SBTypeCodec.OID_MACADDR:
                return "macaddr";
            case SBTypeCodec.OID_MACADDR8:
                return "macaddr8";
            case SBTypeCodec.OID_RECORD:
                return "record";
            default:
                return "unknown";
        }
    }

    private int jdbcTypeFromOid(int oid) {
        switch (oid) {
            case SBTypeCodec.OID_BOOL:
                return Types.BOOLEAN;
            case SBTypeCodec.OID_CHAR:
                return Types.CHAR;
            case SBTypeCodec.OID_INT2:
                return Types.SMALLINT;
            case SBTypeCodec.OID_INT4:
                return Types.INTEGER;
            case SBTypeCodec.OID_INT8:
                return Types.BIGINT;
            case SBTypeCodec.OID_FLOAT4:
                return Types.REAL;
            case SBTypeCodec.OID_FLOAT8:
                return Types.DOUBLE;
            case SBTypeCodec.OID_NUMERIC:
            case SBTypeCodec.OID_MONEY:
                return Types.NUMERIC;
            case SBTypeCodec.OID_TEXT:
            case SBTypeCodec.OID_VARCHAR:
                return Types.VARCHAR;
            case SBTypeCodec.OID_BPCHAR:
                return Types.CHAR;
            case SBTypeCodec.OID_BYTEA:
                return Types.BINARY;
            case SBTypeCodec.OID_DATE:
                return Types.DATE;
            case SBTypeCodec.OID_TIME:
                return Types.TIME;
            case SBTypeCodec.OID_TIMESTAMP:
            case SBTypeCodec.OID_TIMESTAMPTZ:
                return Types.TIMESTAMP;
            case SBTypeCodec.OID_UUID:
            case SBTypeCodec.OID_JSON:
            case SBTypeCodec.OID_JSONB:
            case SBTypeCodec.OID_XML:
            case SBTypeCodec.OID_INET:
            case SBTypeCodec.OID_CIDR:
            case SBTypeCodec.OID_MACADDR:
            case SBTypeCodec.OID_MACADDR8:
            case SBTypeCodec.OID_RECORD:
                return Types.OTHER;
            default:
                return Types.OTHER;
        }
    }

    private int jdbcTypeFromTypeName(String typeName) {
        if (typeName == null) {
            return Types.OTHER;
        }
        String normalized = typeName.toLowerCase(Locale.ROOT);
        if (normalized.contains("int2") || normalized.contains("smallint")) {
            return Types.SMALLINT;
        }
        if (normalized.contains("int4") || normalized.equals("int") || normalized.contains("integer")) {
            return Types.INTEGER;
        }
        if (normalized.contains("int8") || normalized.contains("bigint")) {
            return Types.BIGINT;
        }
        if (normalized.contains("float4") || normalized.contains("real")) {
            return Types.REAL;
        }
        if (normalized.contains("float8") || normalized.contains("double")) {
            return Types.DOUBLE;
        }
        if (normalized.contains("numeric") || normalized.contains("decimal") || normalized.contains("money")) {
            return Types.NUMERIC;
        }
        if (normalized.contains("char") && !normalized.contains("varchar")) {
            return Types.CHAR;
        }
        if (normalized.contains("varchar") || normalized.contains("text")) {
            return Types.VARCHAR;
        }
        if (normalized.contains("date")) {
            return Types.DATE;
        }
        if (normalized.contains("time")) {
            return Types.TIME;
        }
        if (normalized.contains("timestamp")) {
            return Types.TIMESTAMP;
        }
        if (normalized.contains("bytea") || normalized.contains("blob")) {
            return Types.BINARY;
        }
        return Types.OTHER;
    }

    private String mapTableType(Object rawType, String schemaName, boolean fromView) {
        String schema = schemaName != null ? schemaName.toLowerCase(Locale.ROOT) : "";
        String type;
        if (fromView) {
            boolean materialized = toBooleanValue(rawType);
            type = materialized ? "MATERIALIZED VIEW" : "VIEW";
        } else if (rawType instanceof Number) {
            int code = ((Number) rawType).intValue();
            switch (code) {
                case 1:
                    type = "TABLE";
                    break;
                case 2:
                    type = "TEMPORARY TABLE";
                    break;
                case 3:
                    type = "FOREIGN TABLE";
                    break;
                case 4:
                    type = "MATERIALIZED VIEW";
                    break;
                case 5:
                    type = "SYSTEM TABLE";
                    break;
                case 0:
                default:
                    type = "TABLE";
                    break;
            }
        } else {
            type = rawType != null ? rawType.toString().toUpperCase(Locale.ROOT) : "TABLE";
        }

        if ("sys".equals(schema)) {
            if ("VIEW".equals(type) || "MATERIALIZED VIEW".equals(type)) {
                return "SYSTEM VIEW";
            }
            if ("TABLE".equals(type)) {
                return "SYSTEM TABLE";
            }
        }
        return type;
    }

    private Set<String> normalizeTypes(String[] types) {
        if (types == null || types.length == 0) {
            return Collections.emptySet();
        }
        Set<String> normalized = new HashSet<>();
        for (String type : types) {
            if (type != null) {
                normalized.add(type.toUpperCase(Locale.ROOT));
            }
        }
        return normalized;
    }

    private boolean matchesTypeFilter(String tableType, Set<String> filter) {
        if (filter == null || filter.isEmpty()) {
            return true;
        }
        if (tableType == null) {
            return false;
        }
        return filter.contains(tableType.toUpperCase(Locale.ROOT));
    }

    private List<String> monitoringViews() {
        return Arrays.asList(
            "sessions",
            "context_variables",
            "transactions",
            "locks",
            "statements",
            "io_stats",
            "performance",
            "jobs",
            "job_runs",
            "job_dependencies"
        );
    }

    @Override
    public boolean supportsResultSetType(int type) throws SQLException {
        return type == ResultSet.TYPE_FORWARD_ONLY ||
               type == ResultSet.TYPE_SCROLL_INSENSITIVE;
    }

    @Override
    public boolean supportsResultSetConcurrency(int type, int concurrency) throws SQLException {
        return concurrency == ResultSet.CONCUR_READ_ONLY;
    }

    @Override
    public boolean ownUpdatesAreVisible(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean ownDeletesAreVisible(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean ownInsertsAreVisible(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean othersUpdatesAreVisible(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean othersDeletesAreVisible(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean othersInsertsAreVisible(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean updatesAreDetected(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean deletesAreDetected(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean insertsAreDetected(int type) throws SQLException {
        return false;
    }

    @Override
    public boolean supportsBatchUpdates() throws SQLException {
        return true;
    }

    @Override
    public ResultSet getUDTs(String catalog, String schemaPattern, String typeNamePattern, int[] types)
            throws SQLException {
        return createEmptyResultSet(
            new String[]{"TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "CLASS_NAME", "DATA_TYPE",
                         "REMARKS", "BASE_TYPE"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.INTEGER,
                      Types.VARCHAR, Types.SMALLINT}
        );
    }

    @Override
    public Connection getConnection() throws SQLException {
        return connection;
    }

    @Override
    public boolean supportsSavepoints() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsNamedParameters() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsMultipleOpenResults() throws SQLException {
        return false;
    }

    @Override
    public boolean supportsGetGeneratedKeys() throws SQLException {
        return true;
    }

    @Override
    public ResultSet getSuperTypes(String catalog, String schemaPattern, String typeNamePattern)
            throws SQLException {
        return createEmptyResultSet(
            new String[]{"TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "SUPERTYPE_CAT", "SUPERTYPE_SCHEM",
                         "SUPERTYPE_NAME"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR,
                      Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getSuperTables(String catalog, String schemaPattern, String tableNamePattern)
            throws SQLException {
        return createEmptyResultSet(
            new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "SUPERTABLE_NAME"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getAttributes(String catalog, String schemaPattern, String typeNamePattern,
            String attributeNamePattern) throws SQLException {
        return createEmptyResultSet(
            new String[]{"TYPE_CAT", "TYPE_SCHEM", "TYPE_NAME", "ATTR_NAME", "DATA_TYPE",
                         "ATTR_TYPE_NAME", "ATTR_SIZE", "DECIMAL_DIGITS", "NUM_PREC_RADIX", "NULLABLE",
                         "REMARKS", "ATTR_DEF", "SQL_DATA_TYPE", "SQL_DATETIME_SUB", "CHAR_OCTET_LENGTH",
                         "ORDINAL_POSITION", "IS_NULLABLE", "SCOPE_CATALOG", "SCOPE_SCHEMA", "SCOPE_TABLE",
                         "SOURCE_DATA_TYPE"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.INTEGER,
                      Types.VARCHAR, Types.INTEGER, Types.INTEGER, Types.INTEGER, Types.INTEGER,
                      Types.VARCHAR, Types.VARCHAR, Types.INTEGER, Types.INTEGER, Types.INTEGER,
                      Types.INTEGER, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR,
                      Types.SMALLINT}
        );
    }

    @Override
    public boolean supportsResultSetHoldability(int holdability) throws SQLException {
        return holdability == ResultSet.HOLD_CURSORS_OVER_COMMIT;
    }

    @Override
    public int getResultSetHoldability() throws SQLException {
        return ResultSet.HOLD_CURSORS_OVER_COMMIT;
    }

    @Override
    public int getDatabaseMajorVersion() throws SQLException {
        return 1;
    }

    @Override
    public int getDatabaseMinorVersion() throws SQLException {
        return 0;
    }

    @Override
    public int getJDBCMajorVersion() throws SQLException {
        return 4;
    }

    @Override
    public int getJDBCMinorVersion() throws SQLException {
        return 3;
    }

    @Override
    public int getSQLStateType() throws SQLException {
        return sqlStateSQL;
    }

    @Override
    public boolean locatorsUpdateCopy() throws SQLException {
        return true;
    }

    @Override
    public boolean supportsStatementPooling() throws SQLException {
        return true;
    }

    @Override
    public RowIdLifetime getRowIdLifetime() throws SQLException {
        return RowIdLifetime.ROWID_UNSUPPORTED;
    }

    @Override
    public boolean supportsStoredFunctionsUsingCallSyntax() throws SQLException {
        return true;
    }

    @Override
    public boolean autoCommitFailureClosesAllResultSets() throws SQLException {
        return false;
    }

    @Override
    public ResultSet getClientInfoProperties() throws SQLException {
        return createEmptyResultSet(
            new String[]{"NAME", "MAX_LEN", "DEFAULT_VALUE", "DESCRIPTION"},
            new int[]{Types.VARCHAR, Types.INTEGER, Types.VARCHAR, Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getFunctions(String catalog, String schemaPattern, String functionNamePattern)
            throws SQLException {
        return createEmptyResultSet(
            new String[]{"FUNCTION_CAT", "FUNCTION_SCHEM", "FUNCTION_NAME", "REMARKS",
                         "FUNCTION_TYPE", "SPECIFIC_NAME"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR,
                      Types.SMALLINT, Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getFunctionColumns(String catalog, String schemaPattern, String functionNamePattern,
            String columnNamePattern) throws SQLException {
        return createEmptyResultSet(
            new String[]{"FUNCTION_CAT", "FUNCTION_SCHEM", "FUNCTION_NAME", "COLUMN_NAME",
                         "COLUMN_TYPE", "DATA_TYPE", "TYPE_NAME", "PRECISION", "LENGTH", "SCALE",
                         "RADIX", "NULLABLE", "REMARKS", "CHAR_OCTET_LENGTH", "ORDINAL_POSITION",
                         "IS_NULLABLE", "SPECIFIC_NAME"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.SMALLINT,
                      Types.INTEGER, Types.VARCHAR, Types.INTEGER, Types.INTEGER, Types.SMALLINT,
                      Types.SMALLINT, Types.SMALLINT, Types.VARCHAR, Types.INTEGER, Types.INTEGER,
                      Types.VARCHAR, Types.VARCHAR}
        );
    }

    @Override
    public ResultSet getPseudoColumns(String catalog, String schemaPattern, String tableNamePattern,
            String columnNamePattern) throws SQLException {
        return createEmptyResultSet(
            new String[]{"TABLE_CAT", "TABLE_SCHEM", "TABLE_NAME", "COLUMN_NAME", "DATA_TYPE",
                         "COLUMN_SIZE", "DECIMAL_DIGITS", "NUM_PREC_RADIX", "COLUMN_USAGE",
                         "REMARKS", "CHAR_OCTET_LENGTH", "IS_NULLABLE"},
            new int[]{Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.VARCHAR, Types.INTEGER,
                      Types.INTEGER, Types.INTEGER, Types.INTEGER, Types.VARCHAR, Types.VARCHAR,
                      Types.INTEGER, Types.VARCHAR}
        );
    }

    @Override
    public boolean generatedKeyAlwaysReturned() throws SQLException {
        return true;
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

    // Helper method to create empty result sets
    private ResultSet createEmptyResultSet(String[] columnNames, int[] columnTypes) {
        List<SBColumnInfo> cols = new ArrayList<>();
        for (int i = 0; i < columnNames.length; i++) {
            SBColumnInfo col = new SBColumnInfo();
            col.setName(columnNames[i]);
            // Map SQL type to OID
            col.setTypeOid(sqlTypeToOid(columnTypes[i]));
            cols.add(col);
        }
        return new SBResultSet(null, cols, Collections.emptyList());
    }

    private int sqlTypeToOid(int sqlType) {
        switch (sqlType) {
            case Types.VARCHAR: return 25;
            case Types.INTEGER: return 23;
            case Types.SMALLINT: return 21;
            case Types.BIGINT: return 20;
            case Types.BOOLEAN: return 16;
            default: return 25;  // Default to text
        }
    }
}
