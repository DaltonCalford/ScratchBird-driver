#include <gtest/gtest.h>

#include <algorithm>
#include <cstdint>
#include <string>
#include <vector>

#define private public
#include "scratchbird/odbc/odbc_handles.h"
#undef private

namespace {

class OdbcLobStreamingTest : public ::testing::Test {
protected:
    scratchbird::odbc::OdbcEnvironment env_{};
    scratchbird::odbc::OdbcConnection conn_{&env_};
    scratchbird::odbc::OdbcStatement stmt_{&conn_};

    void SetUp() override {
        conn_.connected_ = true;
        stmt_.has_results_ = true;
    }

    void seedTextRows(std::vector<std::string> rows, SQLSMALLINT sql_type = SQL_VARCHAR) {
        stmt_.rows_.clear();
        for (auto& row : rows) {
            stmt_.rows_.push_back({row});
        }
        stmt_.columns_ = {
            {"body", "VARCHAR", "", "", "", "", sql_type, static_cast<SQLULEN>(rows.empty() ? 0 : rows[0].size()),
             0, SQL_NO_NULLS, false, false, true, SQL_PRED_BASIC, 0, 0}
        };
        stmt_.row_count_ = static_cast<SQLLEN>(rows.size());
        stmt_.current_row_ = rows.empty() ? 0 : 1;
    }
};

TEST_F(OdbcLobStreamingTest, TextGetDataStreamsInChunksAndFinishes) {
    seedTextRows({"ABCDEFGHIJKLMNOPQRSTUVWXYZ"});

    char chunk[6] = {};
    SQLLEN indicator = -1;

    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, chunk, sizeof(chunk), &indicator), SQL_SUCCESS_WITH_INFO);
    EXPECT_EQ(indicator, 26);
    EXPECT_STREQ(chunk, "ABCDE");

    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, chunk, sizeof(chunk), &indicator), SQL_SUCCESS_WITH_INFO);
    EXPECT_EQ(indicator, 26);
    EXPECT_STREQ(chunk, "FGHIJ");

    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, chunk, sizeof(chunk), &indicator), SQL_SUCCESS_WITH_INFO);
    EXPECT_EQ(indicator, 26);
    EXPECT_STREQ(chunk, "KLMNO");

    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, chunk, sizeof(chunk), &indicator), SQL_SUCCESS_WITH_INFO);
    EXPECT_EQ(indicator, 26);
    EXPECT_STREQ(chunk, "PQRST");

    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, chunk, sizeof(chunk), &indicator), SQL_SUCCESS_WITH_INFO);
    EXPECT_EQ(indicator, 26);
    EXPECT_STREQ(chunk, "UVWXY");

    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, chunk, sizeof(chunk), &indicator), SQL_SUCCESS);
    EXPECT_EQ(indicator, 0);
    EXPECT_STREQ(chunk, "Z");

    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, chunk, sizeof(chunk), &indicator), SQL_SUCCESS);
    EXPECT_EQ(indicator, 0);
}

TEST_F(OdbcLobStreamingTest, BinaryGetDataStreamsRawBytes) {
    std::string blob;
    blob.push_back('\x01');
    blob.push_back('\x00');
    blob.push_back('\x02');
    blob.push_back('\xFE');
    blob.push_back('\x00');
    blob.push_back('\x7F');
    seedTextRows({blob}, SQL_VARBINARY);

    uint8_t chunk[4] = {};
    SQLLEN indicator = -1;
    uint8_t expected1[] = {0x01, 0x00, 0x02, static_cast<uint8_t>(0xFE)};
    uint8_t expected2[] = {0x00, 0x7F};

    std::fill(std::begin(chunk), std::end(chunk), 0);
    EXPECT_EQ(stmt_.getData(1, SQL_C_BINARY, chunk, sizeof(chunk), &indicator), SQL_SUCCESS_WITH_INFO);
    EXPECT_EQ(indicator, 6);
    EXPECT_EQ(std::vector<uint8_t>(chunk, chunk + 4), std::vector<uint8_t>(std::begin(expected1), std::end(expected1)));

    std::fill(std::begin(chunk), std::end(chunk), 0);
    EXPECT_EQ(stmt_.getData(1, SQL_C_BINARY, chunk, sizeof(chunk), &indicator), SQL_SUCCESS);
    EXPECT_EQ(indicator, 6);
    EXPECT_EQ(std::vector<uint8_t>(chunk, chunk + 2), std::vector<uint8_t>(std::begin(expected2), std::end(expected2)));
}

TEST_F(OdbcLobStreamingTest, StreamStateResetsOnPositionChange) {
    seedTextRows({"first-row-data", "second-row-data"});
    stmt_.cursor_type_ = SQL_CURSOR_STATIC;
    stmt_.current_row_ = 1;

    char row1_chunk[8] = {};
    SQLLEN indicator = -1;
    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, row1_chunk, sizeof(row1_chunk), &indicator), SQL_SUCCESS_WITH_INFO);
    EXPECT_EQ(indicator, 14);
    EXPECT_STREQ(row1_chunk, "first-r");

    EXPECT_EQ(stmt_.setPos(2, SQL_POSITION, SQL_LOCK_NO_CHANGE), SQL_SUCCESS);
    EXPECT_EQ(stmt_.current_row_, 2u);

    char row2_chunk[8] = {};
    EXPECT_EQ(stmt_.getData(1, SQL_C_CHAR, row2_chunk, sizeof(row2_chunk), &indicator), SQL_SUCCESS_WITH_INFO);
    EXPECT_EQ(indicator, 15);
    EXPECT_STREQ(row2_chunk, "second-");
}
}  // namespace
