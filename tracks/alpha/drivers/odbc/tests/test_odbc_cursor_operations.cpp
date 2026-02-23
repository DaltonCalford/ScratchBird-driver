#include <gtest/gtest.h>

#include <cstdint>
#include <string>
#include <vector>

#define private public
#include "scratchbird/odbc/odbc_handles.h"
#undef private

namespace {

class OdbcCursorOperationTest : public ::testing::Test {
protected:
    scratchbird::odbc::OdbcEnvironment env_{};
    scratchbird::odbc::OdbcConnection conn_{&env_};
    scratchbird::odbc::OdbcStatement stmt_{&conn_};

    void SetUp() override {
        conn_.connected_ = true;
    }

    void seedRows(size_t row_count) {
        stmt_.rows_.clear();
        for (size_t i = 0; i < row_count; ++i) {
            stmt_.rows_.push_back({"row_" + std::to_string(i + 1)});
        }
        stmt_.columns_ = {
            {"id", "INTEGER", "", "", "", "", SQL_INTEGER, 10, 0, SQL_NO_NULLS,
             false, false, true, SQL_PRED_BASIC, 10, 10}
        };
        stmt_.has_results_ = true;
        stmt_.current_row_ = 0;
        stmt_.row_count_ = static_cast<SQLLEN>(row_count);
    }
};

TEST_F(OdbcCursorOperationTest, FetchScrollHonorsForwardOnlyCursorType) {
    seedRows(3);
    stmt_.cursor_type_ = SQL_CURSOR_FORWARD_ONLY;

    ASSERT_EQ(stmt_.fetchScroll(SQL_FETCH_NEXT, 0), SQL_SUCCESS);
    EXPECT_EQ(stmt_.current_row_, 1u);

    EXPECT_EQ(stmt_.fetchScroll(SQL_FETCH_FIRST, 0), SQL_ERROR);
    EXPECT_EQ(stmt_.current_row_, 1u);

    EXPECT_EQ(stmt_.setPos(2, SQL_POSITION, SQL_LOCK_NO_CHANGE), SQL_ERROR);
    EXPECT_EQ(stmt_.current_row_, 1u);

    EXPECT_EQ(stmt_.fetchScroll(SQL_FETCH_NEXT, 0), SQL_SUCCESS);
    EXPECT_EQ(stmt_.current_row_, 2u);
}

TEST_F(OdbcCursorOperationTest, ForwardOnlyBlocksNonPositionalSetPosOperations) {
    seedRows(2);
    stmt_.cursor_type_ = SQL_CURSOR_FORWARD_ONLY;

    EXPECT_EQ(stmt_.setPos(1, SQL_DELETE, SQL_LOCK_NO_CHANGE), SQL_ERROR);
    EXPECT_EQ(stmt_.setPos(1, SQL_REFRESH, SQL_LOCK_NO_CHANGE), SQL_ERROR);
    EXPECT_EQ(stmt_.setPos(1, SQL_UPDATE, SQL_LOCK_NO_CHANGE), SQL_ERROR);
}

TEST_F(OdbcCursorOperationTest, SetPosSupportsPositionRefreshUpdateDelete) {
    seedRows(3);
    SQLUSMALLINT status_buffer[4] = {0};
    SQLULEN rows_fetched = 0;

    stmt_.cursor_type_ = SQL_CURSOR_STATIC;
    stmt_.concurrency_ = SQL_CONCUR_READ_ONLY;
    stmt_.row_status_ptr_ = status_buffer;
    stmt_.rows_fetched_ptr_ = &rows_fetched;

    EXPECT_EQ(stmt_.setPos(2, SQL_POSITION, SQL_LOCK_NO_CHANGE), SQL_SUCCESS);
    EXPECT_EQ(stmt_.current_row_, 2u);

    EXPECT_EQ(stmt_.setPos(1, SQL_REFRESH, SQL_LOCK_NO_CHANGE), SQL_SUCCESS);
    EXPECT_EQ(stmt_.current_row_, 1u);
    EXPECT_EQ(stmt_.row_status_ptr_[0], SQL_ROW_SUCCESS);
    EXPECT_EQ(stmt_.rows_fetched_ptr_, &rows_fetched);

    EXPECT_EQ(stmt_.setPos(3, SQL_UPDATE, SQL_LOCK_NO_CHANGE), SQL_ERROR);

    stmt_.concurrency_ = SQL_CONCUR_LOCK;
    EXPECT_EQ(stmt_.setPos(2, SQL_UPDATE, SQL_LOCK_NO_CHANGE), SQL_SUCCESS);
    EXPECT_EQ(stmt_.row_status_ptr_[0], SQL_ROW_UPDATED);

    EXPECT_EQ(stmt_.setPos(1, SQL_DELETE, SQL_LOCK_NO_CHANGE), SQL_SUCCESS);
    ASSERT_EQ(stmt_.rows_.size(), 2u);
    EXPECT_EQ(stmt_.current_row_, 1u);
    EXPECT_EQ(stmt_.row_status_ptr_[0], SQL_ROW_DELETED);
}

TEST_F(OdbcCursorOperationTest, SetPosSupportsDeleteEntireRowset) {
    seedRows(4);
    SQLUSMALLINT status_buffer[4] = {0};
    SQLULEN rows_fetched = 0;

    stmt_.cursor_type_ = SQL_CURSOR_STATIC;
    stmt_.concurrency_ = SQL_CONCUR_LOCK;
    stmt_.row_status_ptr_ = status_buffer;
    stmt_.rows_fetched_ptr_ = &rows_fetched;

    EXPECT_EQ(stmt_.setPos(SQL_ENTIRE_ROWSET, SQL_DELETE, SQL_LOCK_NO_CHANGE), SQL_SUCCESS);
    EXPECT_TRUE(stmt_.rows_.empty());
    EXPECT_EQ(stmt_.current_row_, 0u);
    EXPECT_EQ(stmt_.row_count_, 4);
    EXPECT_EQ(stmt_.row_status_ptr_[0], SQL_ROW_DELETED);
    EXPECT_EQ(stmt_.rows_fetched_ptr_[0], 4u);
}

TEST_F(OdbcCursorOperationTest, SetPosRejectsInvalidRowsAndUnsupportedOps) {
    seedRows(1);
    stmt_.cursor_type_ = SQL_CURSOR_STATIC;
    stmt_.concurrency_ = SQL_CONCUR_LOCK;

    EXPECT_EQ(stmt_.setPos(0, SQL_POSITION, SQL_LOCK_NO_CHANGE), SQL_ERROR);
    EXPECT_EQ(stmt_.setPos(2, SQL_POSITION, SQL_LOCK_NO_CHANGE), SQL_ERROR);
    EXPECT_EQ(stmt_.setPos(1, 99, SQL_LOCK_NO_CHANGE), SQL_ERROR);
    EXPECT_EQ(stmt_.setPos(1, SQL_DELETE_BY_BOOKMARK, SQL_LOCK_NO_CHANGE), SQL_ERROR);
}

}  // namespace
