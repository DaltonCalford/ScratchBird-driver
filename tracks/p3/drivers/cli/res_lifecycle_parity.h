#pragma once

#include <cstdint>
#include <string>

#include <nlohmann/json.hpp>

#include "scratchbird/core/error_context.h"
#include "scratchbird/core/status.h"

namespace scratchbird::cli::parity {

struct LifecycleObservation {
    int64_t rows_affected{0};
    int64_t rows_returned{0};
};

class ResourceLifecycleClient {
public:
    virtual ~ResourceLifecycleClient() = default;

    virtual core::Status connect(core::ErrorContext* ctx) = 0;
    virtual core::Status executeStatement(const std::string& sql,
                                          LifecycleObservation* observation,
                                          core::ErrorContext* ctx) = 0;
    virtual void disconnect() = 0;
    virtual std::string lastError() const = 0;
};

// Execute repeated connect/execute/disconnect cycles with cleanup guarantees.
// Required fields:
// - sql
// Optional fields:
// - loop_iterations (default: 1)
// - expect_total_rows_affected
// - expect_total_rows
void runResourceLifecycleLoopCase(ResourceLifecycleClient& client,
                                  const nlohmann::json& test,
                                  nlohmann::json& result,
                                  bool* had_error,
                                  core::ErrorContext* ctx);

}  // namespace scratchbird::cli::parity
