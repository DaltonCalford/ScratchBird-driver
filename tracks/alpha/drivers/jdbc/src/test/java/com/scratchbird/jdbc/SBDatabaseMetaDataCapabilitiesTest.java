package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.ResultSet;
import java.sql.RowIdLifetime;
import java.sql.SQLException;
import org.junit.jupiter.api.Test;

class SBDatabaseMetaDataCapabilitiesTest {

    @Test
    void reportsValidatedCapabilitySurfaceForGrammarAndMultiResultSupport() throws SQLException {
        SBDatabaseMetaData meta = new SBDatabaseMetaData(null);

        assertTrue(meta.allProceduresAreCallable());
        assertTrue(meta.allTablesAreSelectable());
        assertTrue(meta.supportsMultipleTransactions());
        assertTrue(meta.supportsMultipleResultSets());
        assertTrue(meta.supportsMultipleOpenResults());
        assertTrue(meta.supportsPositionedUpdate());
        assertTrue(meta.supportsPositionedDelete());
        assertTrue(meta.supportsSelectForUpdate());
        assertTrue(meta.supportsConvert());
        assertTrue(meta.supportsConvert(java.sql.Types.INTEGER, java.sql.Types.BIGINT));
        assertTrue(meta.supportsConvert(java.sql.Types.VARCHAR, java.sql.Types.INTEGER));
        assertTrue(meta.supportsConvert(java.sql.Types.TIMESTAMP, java.sql.Types.DATE));
        assertFalse(meta.supportsConvert(java.sql.Types.ARRAY, java.sql.Types.STRUCT));
        assertTrue(meta.supportsMinimumSQLGrammar());
        assertTrue(meta.supportsCoreSQLGrammar());
        assertTrue(meta.supportsExtendedSQLGrammar());
        assertTrue(meta.supportsANSI92EntryLevelSQL());
        assertTrue(meta.supportsANSI92IntermediateSQL());
        assertTrue(meta.supportsANSI92FullSQL());
        assertTrue(meta.supportsCatalogsInDataManipulation());
        assertTrue(meta.supportsCatalogsInProcedureCalls());
        assertTrue(meta.supportsCatalogsInTableDefinitions());
        assertTrue(meta.supportsCatalogsInIndexDefinitions());
        assertTrue(meta.supportsCatalogsInPrivilegeDefinitions());
        assertFalse(meta.locatorsUpdateCopy());
        assertTrue(meta.supportsStatementPooling());
        assertTrue(meta.supportsNamedParameters());
        assertTrue(meta.supportsStoredFunctionsUsingCallSyntax());
        assertTrue(meta.generatedKeyAlwaysReturned());
        assertTrue(meta.supportsResultSetType(ResultSet.TYPE_SCROLL_INSENSITIVE));
    }

    @Test
    void keepsKnownSupportedCapabilities() throws SQLException {
        SBDatabaseMetaData meta = new SBDatabaseMetaData(null);

        assertTrue(meta.supportsBatchUpdates());
        assertTrue(meta.supportsSavepoints());
        assertTrue(meta.supportsGetGeneratedKeys());
        assertTrue(meta.supportsOpenCursorsAcrossCommit());
        assertTrue(meta.supportsOpenCursorsAcrossRollback());
        assertTrue(meta.supportsOpenStatementsAcrossCommit());
        assertTrue(meta.supportsOpenStatementsAcrossRollback());
        assertTrue(meta.supportsResultSetType(ResultSet.TYPE_FORWARD_ONLY));
        assertTrue(meta.supportsResultSetConcurrency(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY));
        assertTrue(meta.supportsResultSetConcurrency(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_UPDATABLE));
        assertTrue(meta.getRowIdLifetime() == RowIdLifetime.ROWID_VALID_OTHER);
    }
}
