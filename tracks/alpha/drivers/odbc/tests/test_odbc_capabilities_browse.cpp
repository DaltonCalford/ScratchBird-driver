#include <gtest/gtest.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <memory>
#include <string>
#include <vector>
#include <algorithm>
#include <unistd.h>

#define private public
#include "scratchbird/odbc/metadata_helpers.h"
#include "scratchbird/odbc/odbc_handles.h"
#include "scratchbird/odbc/odbc_client_bridge.h"
#include "scratchbird/odbc/odbc_driver.h"
#undef private

namespace {

class FakeBrowseClientBridge : public scratchbird::odbc::OdbcClientBridge {
public:
    SQLRETURN executeSQL(const std::string& sql,
                         std::vector<std::vector<std::string>>& results,
                         std::vector<scratchbird::odbc::ColumnMetadata>& columns,
                         SQLLEN& rows_affected) override {
        (void)columns;
        results.clear();
        rows_affected = 0;

        if (sql == "SHOW DATABASES") {
            results = {{"db_main"}, {"db_reporting"}};
            return SQL_SUCCESS;
        }
        if (sql == scratchbird::odbc::metadata::kSchemasQuery) {
            results = {{"public"}, {"analytics"}};
            return SQL_SUCCESS;
        }
        if (sql == scratchbird::odbc::metadata::kTablesQuery) {
            results = {
                {"users", "public", "TABLE"},
                {"orders", "public", "TABLE"},
                {"events", "analytics", "TABLE"}
            };
            return SQL_SUCCESS;
        }
        if (sql == scratchbird::odbc::metadata::kColumnsQuery) {
            results = {
                {"id", "users", "public", "INTEGER", "1", "NO", "PRI"},
                {"name", "users", "public", "VARCHAR", "2", "YES", ""},
                {"created_at", "users", "public", "TIMESTAMP", "3", "YES", ""},
                {"event_id", "events", "analytics", "INTEGER", "1", "NO", "PRI"},
                {"payload", "events", "analytics", "JSON", "2", "YES", ""}
            };
            return SQL_SUCCESS;
        }
        return SQL_ERROR;
    }
};

class ScopedOdbcIni {
public:
    explicit ScopedOdbcIni(const std::string& path) : path_(path) {
        const char* existing = std::getenv("ODBCINI");
        if (existing) {
            had_existing_ = true;
            old_value_ = existing;
        }
        setenv("ODBCINI", path_.c_str(), 1);
    }

    ~ScopedOdbcIni() {
        if (had_existing_) {
            setenv("ODBCINI", old_value_.c_str(), 1);
        } else {
            unsetenv("ODBCINI");
        }
    }

private:
    std::string path_;
    bool had_existing_{false};
    std::string old_value_;
};

class OdbcCapabilityBrowseTest : public ::testing::Test {
protected:
    scratchbird::odbc::OdbcEnvironment env_{};
    scratchbird::odbc::OdbcConnection conn_{&env_};

    void SetUp() override {
        conn_.connected_ = true;
        conn_.current_database_ = "db_main";
        conn_.current_schema_ = "public";
        conn_.params_.dsn = "MainDSN";
        conn_.client_bridge_ = std::make_unique<FakeBrowseClientBridge>();
    }

    static std::string writeIniFile() {
        char path_template[] = "/tmp/sb_odbc_ini_XXXXXX";
        int fd = mkstemp(path_template);
        if (fd < 0) {
            return {};
        }
        std::ofstream out(path_template);
        out << "[odbc data sources]\n";
        out << "AlphaDSN=ScratchBird\n";
        out << "BetaDSN=ScratchBird\n";
        out << "\n[AlphaDSN]\nDriver=ScratchBird\n";
        out.close();
        ::close(fd);
        return path_template;
    }
};


static std::vector<SQLUSMALLINT> expectedSupportedFunctions() {
    return {
        SQL_API_SQLALLOCCONNECT,
        SQL_API_SQLALLOCENV,
        SQL_API_SQLALLOCSTMT,
        SQL_API_SQLALLOCHANDLE,
        SQL_API_SQLFREECONNECT,
        SQL_API_SQLFREEENV,
        SQL_API_SQLFREESTMT,
        SQL_API_SQLFREEHANDLE,
        SQL_API_SQLENDTRAN,
        SQL_API_SQLCONNECT,
        SQL_API_SQLDRIVERCONNECT,
        SQL_API_SQLBROWSECONNECT,
        SQL_API_SQLDISCONNECT,
        SQL_API_SQLSETCONNECTATTR,
        SQL_API_SQLGETCONNECTATTR,
        SQL_API_SQLSETENVATTR,
        SQL_API_SQLGETENVATTR,
        SQL_API_SQLSETSTMTATTR,
        SQL_API_SQLGETSTMTATTR,
        SQL_API_SQLPREPARE,
        SQL_API_SQLEXECUTE,
        SQL_API_SQLEXECDIRECT,
        SQL_API_SQLCANCEL,
        SQL_API_SQLCLOSECURSOR,
        SQL_API_SQLBULKOPERATIONS,
        SQL_API_SQLSETPOS,
        SQL_API_SQLFETCH,
        SQL_API_SQLFETCHSCROLL,
        SQL_API_SQLMORERESULTS,
        SQL_API_SQLBINDCOL,
        SQL_API_SQLBINDPARAM,
        SQL_API_SQLBINDPARAMETER,
        SQL_API_SQLNUMPARAMS,
        SQL_API_SQLDESCRIBEPARAM,
        SQL_API_SQLDESCRIBECOL,
        SQL_API_SQLNUMRESULTCOLS,
        SQL_API_SQLCOLATTRIBUTE,
        SQL_API_SQLSETDESCREC,
        SQL_API_SQLGETDESCREC,
        SQL_API_SQLSETDESCFIELD,
        SQL_API_SQLGETDESCFIELD,
        SQL_API_SQLCOPYDESC,
        SQL_API_SQLROWCOUNT,
        SQL_API_SQLGETDATA,
        SQL_API_SQLPARAMDATA,
        SQL_API_SQLPUTDATA,
        SQL_API_SQLGETDIAGFIELD,
        SQL_API_SQLGETDIAGREC,
        SQL_API_SQLERROR,
        SQL_API_SQLTABLES,
        SQL_API_SQLCOLUMNS,
        SQL_API_SQLPRIMARYKEYS,
        SQL_API_SQLFOREIGNKEYS,
        SQL_API_SQLSTATISTICS,
        SQL_API_SQLSPECIALCOLUMNS,
        SQL_API_SQLPROCEDURES,
        SQL_API_SQLPROCEDURECOLUMNS,
        SQL_API_SQLTABLEPRIVILEGES,
        SQL_API_SQLCOLUMNPRIVILEGES,
        SQL_API_SQLGETFUNCTIONS,
        SQL_API_SQLGETINFO,
        SQL_API_SQLGETTYPEINFO,
    };
}

static bool isFunctionAdvertised(const SQLUSMALLINT* function_map, SQLUSMALLINT function_id) {
    if (!function_map) {
        return false;
    }
    if (function_id >= SQL_API_ODBC3_ALL_FUNCTIONS_SIZE * 16) {
        return false;
    }
    std::size_t word = static_cast<std::size_t>(function_id >> 4);
    std::size_t bit = static_cast<std::size_t>(function_id & 0x0F);
    return ((function_map[word] >> bit) & 1u) != 0;
}

TEST_F(OdbcCapabilityBrowseTest, BrowseConnectListsAvailableDsnsWhenNotYetConnected) {
    auto ini_path = writeIniFile();
    ASSERT_FALSE(ini_path.empty());
    ScopedOdbcIni scoped(ini_path);

    SQLCHAR out_conn[256] = {};
    SQLSMALLINT out_len = 0;

    auto rc = conn_.browseConnect(nullptr, SQL_NTS, out_conn, sizeof(out_conn), &out_len);
    ASSERT_EQ(rc, SQL_SUCCESS);
    EXPECT_GT(out_len, 0);
    std::string out = reinterpret_cast<const char*>(out_conn);
    EXPECT_NE(out.find("DSN=AlphaDSN"), std::string::npos);
    EXPECT_NE(out.find("DSN=BetaDSN"), std::string::npos);
    EXPECT_TRUE(std::remove(ini_path.c_str()) == 0);
}

TEST_F(OdbcCapabilityBrowseTest, BrowseConnectTraversesCatalogSchemaTableColumns) {
    std::string input;
    SQLCHAR out_conn[256] = {};
    SQLSMALLINT out_len = 0;
    SQLRETURN rc;

    input = "DSN=MainDSN;CATALOG=db_main;";
    rc = conn_.browseConnect(reinterpret_cast<SQLCHAR*>(input.data()),
                             SQL_NTS, out_conn, sizeof(out_conn), &out_len);
    ASSERT_EQ(rc, SQL_NEED_DATA);
    std::string schema_level = reinterpret_cast<const char*>(out_conn);
    EXPECT_NE(schema_level.find("SCHEMA=public"), std::string::npos);
    EXPECT_NE(schema_level.find("SCHEMA=analytics"), std::string::npos);

    input = "DSN=MainDSN;CATALOG=db_main;SCHEMA=public;";
    std::fill(std::begin(out_conn), std::end(out_conn), 0);
    rc = conn_.browseConnect(reinterpret_cast<SQLCHAR*>(input.data()),
                             SQL_NTS, out_conn, sizeof(out_conn), &out_len);
    ASSERT_EQ(rc, SQL_NEED_DATA);
    std::string table_level = reinterpret_cast<const char*>(out_conn);
    EXPECT_NE(table_level.find("TABLE=users"), std::string::npos);
    EXPECT_NE(table_level.find("TABLE=orders"), std::string::npos);
    EXPECT_NE(table_level.find("TABLE=events"), std::string::npos);

    input = "DSN=MainDSN;CATALOG=db_main;SCHEMA=public;TABLE=users;";
    std::fill(std::begin(out_conn), std::end(out_conn), 0);
    rc = conn_.browseConnect(reinterpret_cast<SQLCHAR*>(input.data()),
                             SQL_NTS, out_conn, sizeof(out_conn), &out_len);
    ASSERT_EQ(rc, SQL_NEED_DATA);
    std::string column_level = reinterpret_cast<const char*>(out_conn);
    EXPECT_NE(column_level.find("COLUMN=id"), std::string::npos);
    EXPECT_NE(column_level.find("COLUMN=name"), std::string::npos);
    EXPECT_NE(column_level.find("COLUMN=created_at"), std::string::npos);
    EXPECT_EQ(column_level.find("COLUMN=payload"), std::string::npos);
}

TEST_F(OdbcCapabilityBrowseTest, GetInfoAndGetFunctionsReportNoFalsePositives) {
    char value[8] = {};
    SQLSMALLINT len = 0;
    EXPECT_EQ(conn_.getInfo(SQL_MULT_RESULT_SETS, value, sizeof(value), &len), SQL_SUCCESS);
    EXPECT_STREQ(value, "N");
    EXPECT_EQ(conn_.getInfo(SQL_MULTIPLE_ACTIVE_TXN, value, sizeof(value), &len), SQL_SUCCESS);
    EXPECT_STREQ(value, "N");

    SQLUSMALLINT function_map[SQL_API_ODBC3_ALL_FUNCTIONS_SIZE] = {};
    EXPECT_EQ(conn_.getFunctions(SQL_API_ODBC3_ALL_FUNCTIONS, function_map), SQL_SUCCESS);
    EXPECT_FALSE(isFunctionAdvertised(function_map, SQL_API_SQLGETCURSORNAME));
    EXPECT_FALSE(isFunctionAdvertised(function_map, SQL_API_SQLNATIVESQL));
    EXPECT_TRUE(isFunctionAdvertised(function_map, SQL_API_SQLPARAMDATA));
    EXPECT_TRUE(isFunctionAdvertised(function_map, SQL_API_SQLPUTDATA));
    EXPECT_FALSE(isFunctionAdvertised(function_map, SQL_API_SQLSETCURSORNAME));
    EXPECT_TRUE(isFunctionAdvertised(function_map, SQL_API_SQLCONNECT));
    EXPECT_TRUE(isFunctionAdvertised(function_map, SQL_API_SQLTABLES));

    SQLUSMALLINT unsupported = 0;
    EXPECT_EQ(conn_.getFunctions(SQL_API_SQLGETCURSORNAME, &unsupported), SQL_SUCCESS);
    EXPECT_EQ(unsupported, 0);
    EXPECT_EQ(conn_.getFunctions(SQL_API_SQLGETFUNCTIONS, &unsupported), SQL_SUCCESS);
    EXPECT_EQ(unsupported, 1);
}

TEST_F(OdbcCapabilityBrowseTest, GetFunctionsAdvertisesOnlyImplementedFunctions) {
    SQLUSMALLINT function_map[SQL_API_ODBC3_ALL_FUNCTIONS_SIZE] = {};
    ASSERT_EQ(conn_.getFunctions(SQL_API_ODBC3_ALL_FUNCTIONS, function_map), SQL_SUCCESS);

    auto expected = expectedSupportedFunctions();
    std::sort(expected.begin(), expected.end());

    for (auto func_id : expected) {
        EXPECT_TRUE(isFunctionAdvertised(function_map, func_id))
            << "Expected function is not advertised: " << func_id;
    }

    for (std::size_t word = 0; word < SQL_API_ODBC3_ALL_FUNCTIONS_SIZE; ++word) {
        SQLUSMALLINT bits = function_map[word];
        for (std::size_t bit = 0; bit < 16; ++bit) {
            if ((bits >> bit) & 1u) {
                SQLUSMALLINT func_id = static_cast<SQLUSMALLINT>((word << 4) + bit);
                EXPECT_TRUE(std::binary_search(expected.begin(), expected.end(), func_id))
                    << "Unexpected advertised function id: " << func_id;
            }
        }
    }

    const char* matrix_path = std::getenv("ODBC_008_CAPABILITY_MATRIX_PATH");
    if (matrix_path && std::strlen(matrix_path) > 0) {
        std::ofstream matrix_file(matrix_path);
        ASSERT_TRUE(matrix_file.good()) << "Failed to open capability matrix path: " << matrix_path;
        matrix_file << "function_id,advertised\n";
        const SQLUSMALLINT max_function_id =
            static_cast<SQLUSMALLINT>(SQL_API_ODBC3_ALL_FUNCTIONS_SIZE * 16);
        for (SQLUSMALLINT func_id = 0; func_id < max_function_id; ++func_id) {
            matrix_file << func_id << ',' << (isFunctionAdvertised(function_map, func_id) ? 1 : 0) << '\n';
        }
    }
}

TEST_F(OdbcCapabilityBrowseTest, GetFunctionsSupportsAllFunctionsBitmapAlias) {
    SQLUSMALLINT all_functions_map[SQL_API_ODBC3_ALL_FUNCTIONS_SIZE] = {};
    SQLUSMALLINT legacy_function_map[SQL_API_ODBC3_ALL_FUNCTIONS_SIZE] = {};
    ASSERT_EQ(conn_.getFunctions(0, all_functions_map), SQL_SUCCESS);
    ASSERT_EQ(conn_.getFunctions(SQL_API_ODBC3_ALL_FUNCTIONS, legacy_function_map), SQL_SUCCESS);
    EXPECT_TRUE(std::equal(std::begin(all_functions_map),
                           std::end(all_functions_map),
                           std::begin(legacy_function_map)));
}

TEST_F(OdbcCapabilityBrowseTest, BrowseConnectPathFallbackParsesHierarchicalPath) {
    SQLCHAR out_conn[256] = {};
    SQLSMALLINT out_len = 0;
    auto input = std::string("PATH=MainDSN/db_main/public/users;");
    auto rc = conn_.browseConnect(reinterpret_cast<SQLCHAR*>(input.data()),
                                 SQL_NTS, out_conn, sizeof(out_conn), &out_len);
    ASSERT_EQ(rc, SQL_NEED_DATA);
    std::string row_columns = reinterpret_cast<const char*>(out_conn);
    EXPECT_NE(row_columns.find("COLUMN=id"), std::string::npos);
    EXPECT_NE(row_columns.find("COLUMN=name"), std::string::npos);
    EXPECT_NE(row_columns.find("COLUMN=created_at"), std::string::npos);
}

TEST_F(OdbcCapabilityBrowseTest, BrowseConnectRawPathWithoutKeyFallsBackToPath) {
    SQLCHAR out_conn[256] = {};
    SQLSMALLINT out_len = 0;
    auto input = std::string("MainDSN/db_main/public/users;");
    auto rc = conn_.browseConnect(reinterpret_cast<SQLCHAR*>(input.data()),
                                 SQL_NTS, out_conn, sizeof(out_conn), &out_len);
    ASSERT_EQ(rc, SQL_NEED_DATA);
    std::string row_columns = reinterpret_cast<const char*>(out_conn);
    EXPECT_NE(row_columns.find("COLUMN=id"), std::string::npos);
    EXPECT_NE(row_columns.find("COLUMN=name"), std::string::npos);
    EXPECT_NE(row_columns.find("COLUMN=created_at"), std::string::npos);
}

TEST_F(OdbcCapabilityBrowseTest, NullEnvConnectionPoolingDefaultsPropagateToNewEnvironments) {
    SQLHENV env = SQL_NULL_HENV;
    constexpr SQLUINTEGER desired_pooling = SQL_CP_ONE_PER_DRIVER;
    SQLUINTEGER pooling = SQL_CP_OFF;
    SQLINTEGER len = 0;

    ASSERT_EQ(SQLSetEnvAttr(SQL_NULL_HENV, SQL_ATTR_CONNECTION_POOLING,
                           reinterpret_cast<SQLPOINTER>(desired_pooling), 0),
              SQL_SUCCESS);
    ASSERT_EQ(SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env), SQL_SUCCESS);
    ASSERT_NE(env, nullptr);
    EXPECT_EQ(SQLGetEnvAttr(env, SQL_ATTR_CONNECTION_POOLING, &pooling, sizeof(pooling), &len),
              SQL_SUCCESS);
    EXPECT_EQ(pooling, desired_pooling);
    EXPECT_EQ(len, sizeof(pooling));

    ASSERT_EQ(SQLFreeHandle(SQL_HANDLE_ENV, env), SQL_SUCCESS);

    // Restore default to avoid leaking state to other tests.
    ASSERT_EQ(SQLSetEnvAttr(SQL_NULL_HENV, SQL_ATTR_CONNECTION_POOLING,
                           reinterpret_cast<SQLPOINTER>(SQL_CP_OFF), 0),
              SQL_SUCCESS);
}

}  // namespace
