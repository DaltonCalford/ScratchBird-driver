/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */

#include <gtest/gtest.h>

#include <sql.h>
#include <sqlext.h>

#include <cstdlib>
#include <sstream>
#include <string>

namespace {

std::string diagMessage(SQLSMALLINT handle_type, SQLHANDLE handle) {
    std::ostringstream out;
    SQLSMALLINT record = 1;
    while (true) {
        SQLCHAR sqlstate[6] = {};
        SQLINTEGER native = 0;
        SQLCHAR message[512] = {};
        SQLSMALLINT message_len = 0;
        SQLRETURN rc = SQLGetDiagRec(handle_type,
                                     handle,
                                     record,
                                     sqlstate,
                                     &native,
                                     message,
                                     sizeof(message),
                                     &message_len);
        if (rc == SQL_NO_DATA) {
            break;
        }
        if (!SQL_SUCCEEDED(rc)) {
            break;
        }
        if (record > 1) {
            out << " | ";
        }
        out << "[" << reinterpret_cast<char*>(sqlstate) << "] "
            << reinterpret_cast<char*>(message)
            << " (native=" << native << ")";
        ++record;
    }
    return out.str();
}

}  // namespace

TEST(OdbcExternalRuntimeTest, ConnectsThroughListenerAndQueriesFixtureData) {
    const char* conn_env = std::getenv("SCRATCHBIRD_ODBC_TEST_CONNSTR");
    if (conn_env == nullptr || std::string(conn_env).empty()) {
        GTEST_SKIP() << "SCRATCHBIRD_ODBC_TEST_CONNSTR is not set";
    }

    std::string conn_str(conn_env);

    SQLHENV env = SQL_NULL_HENV;
    SQLHDBC dbc = SQL_NULL_HDBC;
    SQLHSTMT stmt = SQL_NULL_HSTMT;

    ASSERT_EQ(SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env), SQL_SUCCESS);
    ASSERT_EQ(SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION,
                            reinterpret_cast<SQLPOINTER>(SQL_OV_ODBC3), 0), SQL_SUCCESS);

    ASSERT_EQ(SQLAllocHandle(SQL_HANDLE_DBC, env, &dbc), SQL_SUCCESS);

    SQLCHAR out_conn[1024] = {};
    SQLSMALLINT out_len = 0;
    SQLRETURN conn_rc = SQLDriverConnect(dbc,
                                         nullptr,
                                         reinterpret_cast<SQLCHAR*>(&conn_str[0]),
                                         SQL_NTS,
                                         out_conn,
                                         sizeof(out_conn),
                                         &out_len,
                                         SQL_DRIVER_NOPROMPT);
    ASSERT_TRUE(SQL_SUCCEEDED(conn_rc)) << "SQLDriverConnect failed: " << diagMessage(SQL_HANDLE_DBC, dbc);

    ASSERT_EQ(SQLAllocHandle(SQL_HANDLE_STMT, dbc, &stmt), SQL_SUCCESS);

    SQLRETURN exec_rc = SQLExecDirect(stmt,
                                      reinterpret_cast<SQLCHAR*>(const_cast<char*>(
                                          "UPDATE basic_table SET name = name "
                                          "WHERE name = 'baseline'")),
                                      SQL_NTS);
    ASSERT_TRUE(SQL_SUCCEEDED(exec_rc)) << "SQLExecDirect failed: " << diagMessage(SQL_HANDLE_STMT, stmt);
    SQLLEN row_count = 0;
    ASSERT_EQ(SQLRowCount(stmt, &row_count), SQL_SUCCESS);
    EXPECT_GE(row_count, 0);

    SQLFreeHandle(SQL_HANDLE_STMT, stmt);
    SQLDisconnect(dbc);
    SQLFreeHandle(SQL_HANDLE_DBC, dbc);
    SQLFreeHandle(SQL_HANDLE_ENV, env);
}
