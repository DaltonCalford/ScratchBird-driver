#include "res_lifecycle_parity.h"

#include <cctype>
#include <string>

namespace scratchbird::cli::parity {
namespace {

std::string trimCopy(const std::string& value) {
    size_t begin = 0;
    while (begin < value.size() && std::isspace(static_cast<unsigned char>(value[begin])) != 0) {
        ++begin;
    }
    size_t end = value.size();
    while (end > begin && std::isspace(static_cast<unsigned char>(value[end - 1])) != 0) {
        --end;
    }
    return value.substr(begin, end - begin);
}

std::string bestError(const ResourceLifecycleClient& client, const core::ErrorContext* ctx) {
    if (ctx != nullptr && !ctx->message.empty()) {
        return ctx->message;
    }
    std::string last_error = client.lastError();
    if (!last_error.empty()) {
        return last_error;
    }
    return "Operation failed";
}

void addError(nlohmann::json& result, bool* had_error, const std::string& message) {
    result["status"] = "error";
    result["errors"].push_back(message);
    if (had_error != nullptr) {
        *had_error = true;
    }
}

bool readOptionalInt64(const nlohmann::json& test,
                       const char* key,
                       int64_t* out,
                       bool* has_value,
                       std::string* error) {
    if (has_value != nullptr) {
        *has_value = false;
    }
    auto it = test.find(key);
    if (it == test.end()) {
        return true;
    }
    if (!it->is_number_integer()) {
        if (error != nullptr) {
            *error = std::string("Field '") + key + "' must be an integer";
        }
        return false;
    }
    if (out != nullptr) {
        *out = it->get<int64_t>();
    }
    if (has_value != nullptr) {
        *has_value = true;
    }
    return true;
}

}  // namespace

void runResourceLifecycleLoopCase(ResourceLifecycleClient& client,
                                  const nlohmann::json& test,
                                  nlohmann::json& result,
                                  bool* had_error,
                                  core::ErrorContext* ctx) {
    const std::string sql = trimCopy(test.value("sql", ""));
    if (sql.empty()) {
        addError(result, had_error, "res_loop_exec requires sql");
        return;
    }

    int64_t loop_iterations = 1;
    int64_t expect_total_rows_affected = 0;
    int64_t expect_total_rows = 0;
    bool has_expect_total_rows_affected = false;
    bool has_expect_total_rows = false;
    std::string parse_error;

    if (!readOptionalInt64(test, "loop_iterations", &loop_iterations, nullptr, &parse_error)) {
        addError(result, had_error, parse_error);
        return;
    }
    if (!readOptionalInt64(test, "expect_total_rows_affected", &expect_total_rows_affected,
                           &has_expect_total_rows_affected, &parse_error)) {
        addError(result, had_error, parse_error);
        return;
    }
    if (!readOptionalInt64(test, "expect_total_rows", &expect_total_rows,
                           &has_expect_total_rows, &parse_error)) {
        addError(result, had_error, parse_error);
        return;
    }

    if (loop_iterations <= 0) {
        addError(result, had_error, "loop_iterations must be greater than zero");
        return;
    }

    int64_t total_rows_affected = 0;
    int64_t total_rows = 0;
    for (int64_t iteration = 1; iteration <= loop_iterations; ++iteration) {
        bool connected = false;
        core::Status status = client.connect(ctx);
        if (status != core::Status::OK) {
            addError(result,
                     had_error,
                     "connect failed at iteration " + std::to_string(iteration) + ": " +
                         bestError(client, ctx));
            return;
        }
        connected = true;

        LifecycleObservation observation;
        status = client.executeStatement(sql, &observation, ctx);
        if (status != core::Status::OK) {
            if (connected) {
                client.disconnect();
            }
            addError(result,
                     had_error,
                     "execute failed at iteration " + std::to_string(iteration) + ": " +
                         bestError(client, ctx));
            return;
        }

        total_rows_affected += observation.rows_affected;
        total_rows += observation.rows_returned;

        if (connected) {
            client.disconnect();
        }
    }

    result["loop_iterations"] = loop_iterations;
    result["total_rows_affected"] = total_rows_affected;
    result["total_rows"] = total_rows;

    if (has_expect_total_rows_affected &&
        total_rows_affected != expect_total_rows_affected) {
        addError(result,
                 had_error,
                 "total_rows_affected mismatch (expected " +
                     std::to_string(expect_total_rows_affected) +
                     ", got " + std::to_string(total_rows_affected) + ")");
        return;
    }
    if (has_expect_total_rows && total_rows != expect_total_rows) {
        addError(result,
                 had_error,
                 "total_rows mismatch (expected " + std::to_string(expect_total_rows) +
                     ", got " + std::to_string(total_rows) + ")");
    }
}

}  // namespace scratchbird::cli::parity
