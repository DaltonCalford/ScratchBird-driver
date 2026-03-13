#pragma once

#include <string>

#include <nlohmann/json.hpp>

namespace scratchbird::cli::conformance {

// Applies optional manifest expectation fields to a normalized conformance result.
// Returns true when all expectations pass. On failure, this mutates `result` to:
//   - status = "error"
//   - append human-readable expectation failures to `errors`
bool applyManifestExpectations(const nlohmann::json& test,
                               nlohmann::json& result,
                               std::string* summary = nullptr);

}  // namespace scratchbird::cli::conformance
