#include <gtest/gtest.h>

#include <cstring>
#include <memory>
#include <string>
#include <vector>

#define private public
#include "scratchbird/odbc/odbc_handles.h"
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

TEST_F(OdbcBulkOperationsTest, BulkOperationsExecutesEachRowInOrder) {
    ASSERT_EQ(stmt_.prepare(
        reinterpret_cast<SQLCHAR*>(const_cast<char*>(
            "INSERT INTO bulk_load (id, note, is_active) VALUES (?, ?, ?)")),
        SQL_SUCCESS);

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
    ASSERT_EQ(stmt_.prepare(
        reinterpret_cast<SQLCHAR*>(const_cast<char*>(
            "UPDATE bulk_flags SET value = ? WHERE id = ?")),
        SQL_SUCCESS);

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
    EXPECT_NE(bridge_->statements[1].find("UPDATE bulk_flags SET value = 4 WHERE id = 20"), std::string::npos);
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

}  // namespace
