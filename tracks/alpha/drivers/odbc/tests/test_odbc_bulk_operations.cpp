#include <gtest/gtest.h>

#include <cstring>
#include <memory>
#include <string>
#include <vector>

#define private public
#include "scratchbird/odbc/odbc_handles.h"
#include "scratchbird/odbc/odbc_client_bridge.h"
#undef private

namespace {

class FakeBulkClientBridge : public scratchbird::odbc::OdbcClientBridge {
public:
    SQLRETURN executeSQL(const std::string& sql,
                         std::vector<std::vector<std::string>>& results,
                         std::vector<scratchbird::odbc::ColumnMetadata>& columns,
                         SQLLEN& rows_affected) override {
        (void)columns;
        (void)rows_affected;

        statements.push_back(sql);
        results.clear();
        rows_affected = 0;
        return SQL_SUCCESS;
    }

    std::vector<std::string> statements;
};

class OdbcBulkOperationsTest : public ::testing::Test {
protected:
    scratchbird::odbc::OdbcEnvironment env_{};
    scratchbird::odbc::OdbcConnection conn_{&env_};
    scratchbird::odbc::OdbcStatement stmt_{&conn_};
    FakeBulkClientBridge* bridge_{nullptr};

    void SetUp() override {
        conn_.connected_ = true;
        auto bridge = std::make_unique<FakeBulkClientBridge>();
        bridge_ = bridge.get();
        conn_.client_bridge_ = std::move(bridge);
    }
};

class OdbcFlakyBulkClientBridge : public scratchbird::odbc::OdbcClientBridge {
public:
    explicit OdbcFlakyBulkClientBridge(SQLULEN fail_row)
        : fail_row_(fail_row) {}

    SQLRETURN executeSQL(const std::string& sql,
                        std::vector<std::vector<std::string>>& results,
                        std::vector<scratchbird::odbc::ColumnMetadata>& columns,
                        SQLLEN& rows_affected) override {
        (void)columns;
        (void)rows_affected;

        statements.push_back(sql);
        results.clear();
        rows_affected = 0;
        ++executed_rows_;

        if (executed_rows_ == fail_row_) {
            return SQL_ERROR;
        }
        return SQL_SUCCESS;
    }

    SQLULEN fail_row_;
    SQLULEN executed_rows_{0};
    std::vector<std::string> statements;
};

TEST_F(OdbcBulkOperationsTest, BulkOperationsExecutesEachRowInOrder) {
    const char* sql = "INSERT INTO bulk_load (id, note, is_active) VALUES (?, ?, ?)";
    ASSERT_EQ(stmt_.prepare(reinterpret_cast<SQLCHAR*>(const_cast<char*>(sql)), SQL_NTS), SQL_SUCCESS);

    SQLINTEGER ids[] = {10, 20, 30};
    SQLLEN id_ind[] = {0, 0, 0};

    char notes[3][16] = {};
    std::strcpy(notes[0], "alpha");
    std::strcpy(notes[1], "skip");
    std::strcpy(notes[2], "gamma");
    SQLLEN note_ind[] = {SQL_NTS, SQL_NULL_DATA, SQL_NTS};

    SQLCHAR flags[] = {1, 0, 1};
    SQLLEN flag_ind[] = {0, 0, 0};

    ASSERT_EQ(stmt_.bindParameter(1, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER,
                                 0, 0, ids, 0, id_ind), SQL_SUCCESS);
    ASSERT_EQ(stmt_.bindParameter(2, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR,
                                 sizeof(notes[0]), 0, notes, sizeof(notes[0]), note_ind),
              SQL_SUCCESS);
    ASSERT_EQ(stmt_.bindParameter(3, SQL_PARAM_INPUT, SQL_C_BIT, SQL_BIT,
                                 0, 0, flags, 0, flag_ind), SQL_SUCCESS);

    SQLULEN paramset_size = 3;
    SQLUSMALLINT param_status[3] = {0};
    SQLULEN processed = 0;
    SQLULEN fetched = 0;

    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMSET_SIZE, reinterpret_cast<SQLPOINTER>(paramset_size), 0),
              SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAM_STATUS_PTR, param_status, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMS_PROCESSED_PTR, &processed, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_ROWS_FETCHED_PTR, &fetched, 0), SQL_SUCCESS);

    EXPECT_EQ(stmt_.bulkOperations(SQL_ADD), SQL_SUCCESS);

    ASSERT_EQ(bridge_->statements.size(), 3u);
    EXPECT_NE(bridge_->statements[0].find("VALUES (10,'alpha',1)"), std::string::npos);
    EXPECT_NE(bridge_->statements[1].find("VALUES (20,NULL,0)"), std::string::npos);
    EXPECT_NE(bridge_->statements[2].find("VALUES (30,'gamma',1)"), std::string::npos);

    EXPECT_EQ(param_status[0], SQL_PARAM_SUCCESS);
    EXPECT_EQ(param_status[1], SQL_PARAM_SUCCESS);
    EXPECT_EQ(param_status[2], SQL_PARAM_SUCCESS);
    EXPECT_EQ(processed, 3u);
    EXPECT_EQ(fetched, 3u);
    EXPECT_EQ(stmt_.row_count_, 3u);
}

TEST_F(OdbcBulkOperationsTest, BulkOperationsUsesBindOffsetInArrayAddressing) {
    const char* sql = "UPDATE bulk_flags SET value = ? WHERE id = ?";
    ASSERT_EQ(stmt_.prepare(reinterpret_cast<SQLCHAR*>(const_cast<char*>(sql)), SQL_NTS), SQL_SUCCESS);

    SQLINTEGER flags[] = {2, 4, 6, 8};
    SQLINTEGER ids[] = {10, 20, 30, 40};
    SQLLEN ind_flags[] = {0, 0, 0, 0};
    SQLLEN ind_ids[] = {0, 0, 0, 0};

    ASSERT_EQ(stmt_.bindParameter(1, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER,
                                 0, 0, flags, 0, ind_flags), SQL_SUCCESS);
    ASSERT_EQ(stmt_.bindParameter(2, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER,
                                 0, 0, ids, 0, ind_ids), SQL_SUCCESS);

    SQLLEN bind_offset = sizeof(SQLINTEGER);
    SQLULEN paramset_size = 3;
    SQLUSMALLINT param_status[3] = {0};
    SQLULEN processed = 0;
    SQLULEN fetched = 0;

    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAM_BIND_OFFSET_PTR, &bind_offset, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMSET_SIZE, reinterpret_cast<SQLPOINTER>(paramset_size), 0),
              SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAM_STATUS_PTR, param_status, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMS_PROCESSED_PTR, &processed, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_ROWS_FETCHED_PTR, &fetched, 0), SQL_SUCCESS);

    EXPECT_EQ(stmt_.bulkOperations(SQL_ADD), SQL_SUCCESS);

    ASSERT_EQ(bridge_->statements.size(), 3u);
    EXPECT_NE(bridge_->statements[0].find("UPDATE bulk_flags SET value = 2 WHERE id = 10"), std::string::npos);
    EXPECT_NE(bridge_->statements[1].find("UPDATE bulk_flags SET value = 4 WHERE id = 20"), std::string::npos);
    EXPECT_NE(bridge_->statements[2].find("UPDATE bulk_flags SET value = 6 WHERE id = 30"), std::string::npos);
    EXPECT_NE(bridge_->statements[2].find("UPDATE bulk_flags SET value = 6 WHERE id = 30"), std::string::npos);

    EXPECT_EQ(processed, 3u);
    EXPECT_EQ(fetched, 3u);
}

TEST_F(OdbcBulkOperationsTest, BulkOperationsRejectsUnsupportedOperationCode) {
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMSET_SIZE,
                                 reinterpret_cast<SQLPOINTER>(static_cast<SQLULEN>(1)), 0),
              SQL_SUCCESS);
    EXPECT_EQ(stmt_.bulkOperations(99), SQL_ERROR);
}

TEST_F(OdbcBulkOperationsTest, BulkOperationsSupportsUpdateAndDeleteByBookmarkCodes) {
    const char* sql = "DELETE FROM bulk_flags WHERE id = ?";
    ASSERT_EQ(stmt_.prepare(reinterpret_cast<SQLCHAR*>(const_cast<char*>(sql)), SQL_NTS), SQL_SUCCESS);

    SQLINTEGER ids[] = {10, 20};
    SQLLEN ind[] = {0, 0};

    ASSERT_EQ(stmt_.bindParameter(1, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER,
                                 0, 0, ids, 0, ind), SQL_SUCCESS);

    SQLULEN paramset_size = 2;
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMSET_SIZE,
                                 reinterpret_cast<SQLPOINTER>(paramset_size), 0),
              SQL_SUCCESS);

    EXPECT_EQ(stmt_.bulkOperations(SQL_DELETE_BY_BOOKMARK), SQL_SUCCESS);
    EXPECT_EQ(stmt_.bulkOperations(SQL_UPDATE_BY_BOOKMARK), SQL_SUCCESS);
    EXPECT_EQ(bridge_->statements.size(), 4u);
}

TEST_F(OdbcBulkOperationsTest, BulkOperationsNoRowsIsNoOp) {
    const char* sql = "DELETE FROM bulk_load WHERE id = ?";
    ASSERT_EQ(stmt_.prepare(reinterpret_cast<SQLCHAR*>(const_cast<char*>(sql)), SQL_NTS), SQL_SUCCESS);

    SQLUSMALLINT param_status[4] = {0};
    SQLULEN processed = 0;
    SQLULEN fetched = 0;

    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMSET_SIZE,
                                 reinterpret_cast<SQLPOINTER>(static_cast<SQLULEN>(0)), 0),
              SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAM_STATUS_PTR, param_status, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMS_PROCESSED_PTR, &processed, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_ROWS_FETCHED_PTR, &fetched, 0), SQL_SUCCESS);

    EXPECT_EQ(stmt_.bulkOperations(SQL_ADD), SQL_SUCCESS);
    EXPECT_EQ(processed, 0u);
    EXPECT_EQ(fetched, 0u);
    EXPECT_EQ(param_status[0], 0u);
    EXPECT_TRUE(bridge_->statements.empty());
}

TEST_F(OdbcBulkOperationsTest, BulkOperationsRejectsNonColumnWiseBindingMode) {
    const char* sql = "UPDATE bulk_flags SET value = ? WHERE id = ?";
    ASSERT_EQ(stmt_.prepare(reinterpret_cast<SQLCHAR*>(const_cast<char*>(sql)), SQL_NTS), SQL_SUCCESS);

    SQLINTEGER values[] = {1, 2};
    SQLINTEGER ids[] = {10, 20};
    SQLLEN ind_values[] = {0, 0};
    SQLLEN ind_ids[] = {0, 0};

    ASSERT_EQ(stmt_.bindParameter(1, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER,
                                 0, 0, values, 0, ind_values), SQL_SUCCESS);
    ASSERT_EQ(stmt_.bindParameter(2, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER,
                                 0, 0, ids, 0, ind_ids), SQL_SUCCESS);

    SQLULEN paramset_size = 2;
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMSET_SIZE,
                                 reinterpret_cast<SQLPOINTER>(paramset_size), 0),
              SQL_SUCCESS);
    // Use an unsupported parameter bind mode (non-zero) to verify required HYC00 handling.
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAM_BIND_TYPE,
                                 reinterpret_cast<SQLPOINTER>(static_cast<SQLULEN>(1)),
                                 0),
              SQL_SUCCESS);

    EXPECT_EQ(stmt_.bulkOperations(SQL_ADD), SQL_ERROR);
}

TEST_F(OdbcBulkOperationsTest, BulkOperationsPartialFailureStopsExecution) {
    const char* sql = "INSERT INTO bulk_audit (id, note) VALUES (?, ?)";
    ASSERT_EQ(stmt_.prepare(reinterpret_cast<SQLCHAR*>(const_cast<char*>(sql)), SQL_NTS), SQL_SUCCESS);

    SQLINTEGER ids[] = {1, 2, 3};
    SQLLEN id_ind[] = {0, 0, 0};
    char notes[3][12] = {};
    std::strcpy(notes[0], "a");
    std::strcpy(notes[1], "b");
    std::strcpy(notes[2], "c");
    SQLLEN note_ind[] = {0, 0, 0};

    ASSERT_EQ(stmt_.bindParameter(1, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER,
                                 0, 0, ids, 0, id_ind),
              SQL_SUCCESS);
    ASSERT_EQ(stmt_.bindParameter(2, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR,
                                 sizeof(notes[0]), 0, notes, sizeof(notes[0]), note_ind),
              SQL_SUCCESS);

    auto flaky_bridge = std::make_unique<OdbcFlakyBulkClientBridge>(2);
    auto* flaky_ptr = flaky_bridge.get();
    conn_.client_bridge_ = std::move(flaky_bridge);

    SQLULEN paramset_size = 3;
    SQLUSMALLINT param_status[3] = {0};
    SQLULEN processed = 0;
    SQLULEN fetched = 0;
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMSET_SIZE, reinterpret_cast<SQLPOINTER>(paramset_size), 0),
              SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAM_STATUS_PTR, param_status, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_PARAMS_PROCESSED_PTR, &processed, 0), SQL_SUCCESS);
    ASSERT_EQ(stmt_.setAttribute(SQL_ATTR_ROWS_FETCHED_PTR, &fetched, 0), SQL_SUCCESS);

    EXPECT_EQ(stmt_.bulkOperations(SQL_ADD), SQL_ERROR);
    EXPECT_EQ(processed, 1u);
    EXPECT_EQ(fetched, 1u);
    EXPECT_EQ(param_status[0], SQL_PARAM_SUCCESS);
    EXPECT_EQ(param_status[1], SQL_PARAM_ERROR);
    EXPECT_EQ(param_status[2], 0u);
    EXPECT_EQ(flaky_ptr->statements.size(), 2u);
    EXPECT_EQ(conn_.client_bridge_.get(), flaky_ptr);
}

}  // namespace
