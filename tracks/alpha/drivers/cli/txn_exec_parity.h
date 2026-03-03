#pragma once

#include <cstdint>
#include <string>

#include <nlohmann/json.hpp>

#include "scratchbird/core/error_context.h"
#include "scratchbird/core/status.h"

namespace scratchbird::cli::parity {

struct ExecObservation {
    int64_t rows_affected{0};
    int64_t rows_returned{0};
};

class TxnExecClient {
public:
    virtual ~TxnExecClient() = default;

    virtual core::Status executeStatement(const std::string& sql,
                                          ExecObservation* observation,
                                          core::ErrorContext* ctx) = 0;
    virtual core::Status beginTransaction(core::ErrorContext* ctx) = 0;
    virtual core::Status commit(core::ErrorContext* ctx) = 0;
    virtual core::Status rollback(core::ErrorContext* ctx) = 0;
    virtual std::string lastError() const = 0;
};

// Execute a non-prepare statement and validate optional expectations:
// - expect_rows_affected
// - expect_rows
void runNativeExecCase(TxnExecClient& client,
                       const nlohmann::json& test,
                       nlohmann::json& result,
                       bool* had_error,
                       core::ErrorContext* ctx);

// Execute transaction flow:
// begin -> sql -> (commit|rollback) -> optional verify_sql.
// Optional fields:
// - txn_end: "commit" (default) or "rollback"
// - expect_rows_affected
// - verify_sql
// - verify_expect_rows (falls back to expect_rows if omitted)
// - cleanup_sql
void runTxnExecCase(TxnExecClient& client,
                    const nlohmann::json& test,
                    nlohmann::json& result,
                    bool* had_error,
                    core::ErrorContext* ctx);

}  // namespace scratchbird::cli::parity
