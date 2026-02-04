#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <limits>
#include <map>
#include <iostream>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include <nlohmann/json.hpp>
#include <openssl/sha.h>

#include "scratchbird/client/driver_config.h"
#include "scratchbird/client/network_client.h"
#include "scratchbird/core/error_context.h"
#include "scratchbird/core/status.h"

using json = nlohmann::json;

namespace {
constexpr uint32_t kOidBoolArray = 1000;
constexpr uint32_t kOidInt2Array = 1005;
constexpr uint32_t kOidInt4Array = 1007;
constexpr uint32_t kOidInt8Array = 1016;
constexpr uint32_t kOidFloat4Array = 1021;
constexpr uint32_t kOidFloat8Array = 1022;
constexpr uint32_t kOidTextArray = 1009;
constexpr uint32_t kOidVarcharArray = 1015;
constexpr uint32_t kOidBpcharArray = 1014;
constexpr uint32_t kOidUuidArray = 2951;

bool g_binary_params = false;
std::string readAllStdin() {
    std::ostringstream buffer;
    buffer << std::cin.rdbuf();
    return buffer.str();
}

std::string toHex(const uint8_t* data, size_t len) {
    std::ostringstream out;
    out << std::hex << std::setfill('0');
    for (size_t i = 0; i < len; ++i) {
        out << std::setw(2) << static_cast<int>(data[i]);
    }
    return out.str();
}

bool readU8(const std::vector<uint8_t>& data, size_t& offset, uint8_t& out) {
    if (offset + 1 > data.size()) {
        return false;
    }
    out = data[offset];
    offset += 1;
    return true;
}

bool readU16(const std::vector<uint8_t>& data, size_t& offset, uint16_t& out) {
    if (offset + 2 > data.size()) {
        return false;
    }
    out = static_cast<uint16_t>(data[offset]) |
          (static_cast<uint16_t>(data[offset + 1]) << 8);
    offset += 2;
    return true;
}

bool readU32(const std::vector<uint8_t>& data, size_t& offset, uint32_t& out) {
    if (offset + 4 > data.size()) {
        return false;
    }
    out = static_cast<uint32_t>(data[offset]) |
          (static_cast<uint32_t>(data[offset + 1]) << 8) |
          (static_cast<uint32_t>(data[offset + 2]) << 16) |
          (static_cast<uint32_t>(data[offset + 3]) << 24);
    offset += 4;
    return true;
}

bool readU64(const std::vector<uint8_t>& data, size_t& offset, uint64_t& out) {
    if (offset + 8 > data.size()) {
        return false;
    }
    out = 0;
    for (size_t i = 0; i < 8; ++i) {
        out |= static_cast<uint64_t>(data[offset + i]) << (8 * i);
    }
    offset += 8;
    return true;
}

bool readBytes(const std::vector<uint8_t>& data,
               size_t& offset,
               size_t len,
               std::vector<uint8_t>& out) {
    if (offset + len > data.size()) {
        return false;
    }
    out.assign(data.begin() + static_cast<long>(offset),
               data.begin() + static_cast<long>(offset + len));
    offset += len;
    return true;
}

std::string sha256Hex(const std::vector<uint8_t>& data) {
    unsigned char digest[SHA256_DIGEST_LENGTH];
    SHA256_CTX ctx;
    SHA256_Init(&ctx);
    if (!data.empty()) {
        SHA256_Update(&ctx, data.data(), data.size());
    }
    SHA256_Final(digest, &ctx);
    return toHex(digest, SHA256_DIGEST_LENGTH);
}

json buildNestedArray(const std::vector<json>& values,
                      const std::vector<size_t>& dims,
                      size_t dim_index,
                      size_t& cursor) {
    if (dim_index >= dims.size()) {
        if (cursor >= values.size()) {
            return nullptr;
        }
        return values[cursor++];
    }
    json arr = json::array();
    for (size_t i = 0; i < dims[dim_index]; ++i) {
        arr.push_back(buildNestedArray(values, dims, dim_index + 1, cursor));
    }
    return arr;
}

bool decodeArrayBinary(const std::vector<uint8_t>& data, json& out) {
    if (data.size() < 2) {
        return false;
    }
    size_t offset = 0;
    uint8_t elem_type = data[offset++];
    uint8_t rank = data[offset++];
    if (data.size() < 2 + rank * 4) {
        return false;
    }
    std::vector<size_t> dims;
    dims.reserve(rank);
    for (uint8_t i = 0; i < rank; ++i) {
        uint32_t dim = 0;
        if (!readU32(data, offset, dim)) {
            return false;
        }
        dims.push_back(dim);
    }
    size_t total = 1;
    for (auto dim : dims) {
        if (dim == 0) {
            total = 0;
            break;
        }
        total *= dim;
    }

    std::vector<json> values;
    values.reserve(total);
    switch (elem_type) {
        case 0: {
            for (size_t i = 0; i < total; ++i) {
                uint32_t bits = 0;
                if (!readU32(data, offset, bits)) {
                    return false;
                }
                values.emplace_back(static_cast<int32_t>(bits));
            }
            break;
        }
        case 1: {
            for (size_t i = 0; i < total; ++i) {
                uint64_t bits = 0;
                if (!readU64(data, offset, bits)) {
                    return false;
                }
                values.emplace_back(static_cast<int64_t>(bits));
            }
            break;
        }
        case 2: {
            for (size_t i = 0; i < total; ++i) {
                uint32_t bits = 0;
                if (!readU32(data, offset, bits)) {
                    return false;
                }
                float val = 0.0f;
                std::memcpy(&val, &bits, sizeof(float));
                values.emplace_back(val);
            }
            break;
        }
        case 3: {
            for (size_t i = 0; i < total; ++i) {
                uint64_t bits = 0;
                if (!readU64(data, offset, bits)) {
                    return false;
                }
                double val = 0.0;
                std::memcpy(&val, &bits, sizeof(double));
                values.emplace_back(val);
            }
            break;
        }
        case 4: {
            for (size_t i = 0; i < total; ++i) {
                uint32_t len = 0;
                if (!readU32(data, offset, len)) {
                    return false;
                }
                std::vector<uint8_t> bytes;
                if (!readBytes(data, offset, len, bytes)) {
                    return false;
                }
                values.emplace_back(std::string(bytes.begin(), bytes.end()));
            }
            break;
        }
        case 5: {
            for (size_t i = 0; i < total; ++i) {
                uint8_t val = 0;
                if (!readU8(data, offset, val)) {
                    return false;
                }
                values.emplace_back(val != 0);
            }
            break;
        }
        default:
            return false;
    }

    if (offset != data.size()) {
        return false;
    }
    size_t cursor = 0;
    out = buildNestedArray(values, dims, 0, cursor);
    return true;
}

bool decodeVectorBinary(const std::vector<uint8_t>& data, json& out) {
    if (data.size() < 5) {
        return false;
    }
    size_t offset = 0;
    uint8_t type = data[offset++];
    uint32_t dims = 0;
    if (!readU32(data, offset, dims)) {
        return false;
    }
    json arr = json::array();
    if (type == 0) {
        for (uint32_t i = 0; i < dims; ++i) {
            uint32_t bits = 0;
            if (!readU32(data, offset, bits)) {
                return false;
            }
            float val = 0.0f;
            std::memcpy(&val, &bits, sizeof(float));
            arr.push_back(val);
        }
    } else if (type == 1) {
        for (uint32_t i = 0; i < dims; ++i) {
            uint64_t bits = 0;
            if (!readU64(data, offset, bits)) {
                return false;
            }
            double val = 0.0;
            std::memcpy(&val, &bits, sizeof(double));
            arr.push_back(val);
        }
    } else {
        return false;
    }

    if (offset != data.size()) {
        return false;
    }
    out = std::move(arr);
    return true;
}

bool decodeRangeBinary(const std::vector<uint8_t>& data, uint32_t type_oid, json& out) {
    if (data.empty()) {
        return false;
    }
    size_t offset = 0;
    uint8_t flags = 0;
    if (!readU8(data, offset, flags)) {
        return false;
    }

    bool is_empty = (flags & 0x01) != 0;
    bool has_lower = (flags & 0x02) != 0;
    bool has_upper = (flags & 0x04) != 0;
    bool lower_inc = (flags & 0x08) != 0;
    bool upper_inc = (flags & 0x10) != 0;

    json lower = nullptr;
    json upper = nullptr;

    auto readInt32 = [&](json& target) -> bool {
        uint32_t bits = 0;
        if (!readU32(data, offset, bits)) {
            return false;
        }
        target = static_cast<int32_t>(bits);
        return true;
    };

    auto readInt64 = [&](json& target) -> bool {
        uint64_t bits = 0;
        if (!readU64(data, offset, bits)) {
            return false;
        }
        target = static_cast<int64_t>(bits);
        return true;
    };

    auto readDouble = [&](json& target) -> bool {
        uint64_t bits = 0;
        if (!readU64(data, offset, bits)) {
            return false;
        }
        double val = 0.0;
        std::memcpy(&val, &bits, sizeof(double));
        target = val;
        return true;
    };

    if (is_empty) {
        out = json{
            {"empty", true},
            {"lower", nullptr},
            {"upper", nullptr},
            {"lower_inclusive", false},
            {"upper_inclusive", false},
            {"lower_infinite", true},
            {"upper_infinite", true}
        };
        return true;
    }

    if (type_oid == scratchbird::protocol::kOidInt4Range) {
        if (has_lower && !readInt32(lower)) {
            return false;
        }
        if (has_upper && !readInt32(upper)) {
            return false;
        }
    } else if (type_oid == scratchbird::protocol::kOidNumRange) {
        if (has_lower && !readDouble(lower)) {
            return false;
        }
        if (has_upper && !readDouble(upper)) {
            return false;
        }
    } else {
        if (has_lower && !readInt64(lower)) {
            return false;
        }
        if (has_upper && !readInt64(upper)) {
            return false;
        }
    }

    if (offset != data.size()) {
        return false;
    }

    out = json{
        {"empty", false},
        {"lower", lower},
        {"upper", upper},
        {"lower_inclusive", lower_inc},
        {"upper_inclusive", upper_inc},
        {"lower_infinite", !has_lower},
        {"upper_infinite", !has_upper}
    };
    return true;
}

std::string formatIpv4(const uint8_t* data) {
    std::ostringstream out;
    out << static_cast<int>(data[0]) << "."
        << static_cast<int>(data[1]) << "."
        << static_cast<int>(data[2]) << "."
        << static_cast<int>(data[3]);
    return out.str();
}

std::string formatIpv6(const uint8_t* data) {
    std::ostringstream out;
    out << std::hex << std::setfill('0');
    for (int i = 0; i < 16; i += 2) {
        if (i > 0) {
            out << ":";
        }
        uint16_t part = static_cast<uint16_t>(data[i]) |
                        (static_cast<uint16_t>(data[i + 1]) << 8);
        out << std::setw(4) << part;
    }
    return out.str();
}

bool decodeInetLike(const std::vector<uint8_t>& data,
                    uint32_t type_oid,
                    json& out) {
    if (data.size() < 2) {
        return false;
    }
    uint8_t family = data[0];
    uint8_t netmask = data[1];
    if (family == 4 && data.size() >= 6) {
        std::string ip = formatIpv4(data.data() + 2);
        if (type_oid == scratchbird::protocol::kOidCidr) {
            ip += "/" + std::to_string(netmask);
        }
        out = ip;
        return true;
    }
    if (family == 6 && data.size() >= 18) {
        std::string ip = formatIpv6(data.data() + 2);
        if (type_oid == scratchbird::protocol::kOidCidr) {
            ip += "/" + std::to_string(netmask);
        }
        out = ip;
        return true;
    }
    return false;
}

bool decodeMacaddr(const std::vector<uint8_t>& data, json& out) {
    if (data.size() != 6 && data.size() != 8) {
        return false;
    }
    std::ostringstream buf;
    buf << std::hex << std::setfill('0');
    for (size_t i = 0; i < data.size(); ++i) {
        if (i > 0) {
            buf << ":";
        }
        buf << std::setw(2) << static_cast<int>(data[i]);
    }
    out = buf.str();
    return true;
}

json columnValueToJson(const scratchbird::protocol::ColumnValue& val,
                       uint32_t type_oid) {
    if (val.is_null) {
        return nullptr;
    }
    const auto& data = val.data;
    switch (type_oid) {
        case scratchbird::protocol::kOidBool:
            if (!data.empty()) {
                return data[0] != 0;
            }
            break;
        case scratchbird::protocol::kOidInt2: {
            if (data.size() >= sizeof(int16_t)) {
                int16_t v = 0;
                std::memcpy(&v, data.data(), sizeof(int16_t));
                return v;
            }
            break;
        }
        case scratchbird::protocol::kOidInt4: {
            if (data.size() >= sizeof(int32_t)) {
                int32_t v = 0;
                std::memcpy(&v, data.data(), sizeof(int32_t));
                return v;
            }
            break;
        }
        case scratchbird::protocol::kOidInt8:
        case scratchbird::protocol::kOidTimestamp:
        case scratchbird::protocol::kOidTimestamptz:
        case scratchbird::protocol::kOidTime:
        case scratchbird::protocol::kOidTimetz:
        case scratchbird::protocol::kOidDate: {
            if (data.size() >= sizeof(int64_t)) {
                int64_t v = 0;
                std::memcpy(&v, data.data(), sizeof(int64_t));
                return v;
            }
            if (data.size() >= sizeof(int32_t)) {
                int32_t v = 0;
                std::memcpy(&v, data.data(), sizeof(int32_t));
                return v;
            }
            break;
        }
        case scratchbird::protocol::kOidFloat4: {
            if (data.size() >= sizeof(float)) {
                float v = 0.0f;
                std::memcpy(&v, data.data(), sizeof(float));
                return v;
            }
            break;
        }
        case scratchbird::protocol::kOidFloat8: {
            if (data.size() >= sizeof(double)) {
                double v = 0.0;
                std::memcpy(&v, data.data(), sizeof(double));
                return v;
            }
            break;
        }
        case scratchbird::protocol::kOidUuid:
            if (data.size() == 16) {
                return toHex(data.data(), data.size());
            }
            break;
        case scratchbird::protocol::kOidBytea:
            return "0x" + toHex(data.data(), data.size());
        case scratchbird::protocol::kOidSbVector: {
            json vec_out;
            if (decodeVectorBinary(data, vec_out)) {
                return vec_out;
            }
            break;
        }
        case scratchbird::protocol::kOidInet:
        case scratchbird::protocol::kOidCidr: {
            json inet_out;
            if (decodeInetLike(data, type_oid, inet_out)) {
                return inet_out;
            }
            break;
        }
        case scratchbird::protocol::kOidMacaddr:
        case scratchbird::protocol::kOidMacaddr8: {
            json mac_out;
            if (decodeMacaddr(data, mac_out)) {
                return mac_out;
            }
            break;
        }
        case scratchbird::protocol::kOidInt4Range:
        case scratchbird::protocol::kOidInt8Range:
        case scratchbird::protocol::kOidNumRange:
        case scratchbird::protocol::kOidTsRange:
        case scratchbird::protocol::kOidTstzRange:
        case scratchbird::protocol::kOidDateRange: {
            json range_out;
            if (decodeRangeBinary(data, type_oid, range_out)) {
                return range_out;
            }
            break;
        }
        default:
            break;
    }
    if (type_oid == scratchbird::protocol::kOidRecord ||
        type_oid == kOidBoolArray ||
        type_oid == kOidInt2Array ||
        type_oid == kOidInt4Array ||
        type_oid == kOidInt8Array ||
        type_oid == kOidFloat4Array ||
        type_oid == kOidFloat8Array ||
        type_oid == kOidTextArray ||
        type_oid == kOidVarcharArray ||
        type_oid == kOidBpcharArray ||
        type_oid == kOidUuidArray) {
        json array_out;
        if (decodeArrayBinary(data, array_out)) {
            return array_out;
        }
    }
    return std::string(data.begin(), data.end());
}

std::string jsonParamToString(const json& value);

scratchbird::protocol::ParamValue jsonParamToParamValue(const json& value) {
    scratchbird::protocol::ParamValue param;
    if (value.is_null()) {
        param.is_null = true;
        return param;
    }
    if (!g_binary_params) {
        std::string text = jsonParamToString(value);
        param.format = scratchbird::protocol::kFormatText;
        param.data.assign(text.begin(), text.end());
        return param;
    }

    param.format = scratchbird::protocol::kFormatBinary;
    if (value.is_boolean()) {
        param.data = {static_cast<uint8_t>(value.get<bool>() ? 1 : 0)};
    } else if (value.is_number_integer()) {
        int64_t num = value.get<int64_t>();
        if (num >= std::numeric_limits<int32_t>::min() &&
            num <= std::numeric_limits<int32_t>::max()) {
            int32_t v32 = static_cast<int32_t>(num);
            param.data.resize(sizeof(int32_t));
            std::memcpy(param.data.data(), &v32, sizeof(int32_t));
        } else {
            int64_t v64 = static_cast<int64_t>(num);
            param.data.resize(sizeof(int64_t));
            std::memcpy(param.data.data(), &v64, sizeof(int64_t));
        }
    } else if (value.is_number_float()) {
        double v = value.get<double>();
        param.data.resize(sizeof(double));
        std::memcpy(param.data.data(), &v, sizeof(double));
    } else if (value.is_string()) {
        std::string text = value.get<std::string>();
        param.data.assign(text.begin(), text.end());
    } else {
        std::string text = jsonParamToString(value);
        param.data.assign(text.begin(), text.end());
    }
    return param;
}

std::string jsonParamToString(const json& value) {
    if (value.is_null()) {
        return "";
    }
    if (value.is_string()) {
        return value.get<std::string>();
    }
    if (value.is_boolean()) {
        return value.get<bool>() ? "true" : "false";
    }
    if (value.is_number_integer()) {
        return std::to_string(value.get<int64_t>());
    }
    if (value.is_number_float()) {
        std::ostringstream out;
        out << std::setprecision(15) << value.get<double>();
        return out.str();
    }
    return value.dump();
}

struct CancelOutcome {
    std::atomic<int64_t> rows{0};
    std::atomic<bool> done{false};
    std::atomic<bool> canceled{false};
    scratchbird::core::Status status{scratchbird::core::Status::OK};
    std::string message;
    std::string sqlstate;
};

bool buildConfig(const std::string& base_dsn,
                 const std::string& dsn_append,
                 scratchbird::client::NetworkClientConfig& config,
                 scratchbird::core::ErrorContext* ctx) {
    auto status = scratchbird::client::parseDriverConnectionString(base_dsn, config, ctx);
    if (status != scratchbird::core::Status::OK) {
        return false;
    }
    if (!dsn_append.empty()) {
        std::map<std::string, std::string> params;
        auto param_status = scratchbird::client::parseKeyValueConnectionString(dsn_append, params, ctx);
        if (param_status != scratchbird::core::Status::OK) {
            return false;
        }
        param_status = scratchbird::client::applyConnectionParams(params, config, ctx);
        if (param_status != scratchbird::core::Status::OK) {
            return false;
        }
    }
    return true;
}

json makeErrorResult(const std::string& test_id, const std::string& message) {
    json result;
    result["test_id"] = test_id;
    result["status"] = "error";
    result["errors"] = json::array({message});
    result["rows"] = json::array();
    result["columns"] = json::array();
    return result;
}

void fillResultRows(json& result,
                    const scratchbird::client::NetworkResultSet& results) {
    result["columns"] = json::array();
    for (const auto& col : results.columns) {
        result["columns"].push_back(col.name);
    }

    json rows = json::array();
    for (const auto& row : results.rows) {
        json row_out = json::array();
        for (size_t i = 0; i < row.size(); ++i) {
            uint32_t type_oid = 0;
            if (i < results.columns.size()) {
                type_oid = results.columns[i].type_oid;
            }
            row_out.push_back(columnValueToJson(row[i], type_oid));
        }
        rows.push_back(std::move(row_out));
    }
    result["rows"] = std::move(rows);
}

void seedConformanceFixtures(const scratchbird::client::NetworkClientConfig& config) {
    scratchbird::client::NetworkClient client;
    scratchbird::core::ErrorContext ctx;
    if (client.connect(config, &ctx) != scratchbird::core::Status::OK) {
        std::cerr << "[conformance_debug] setup connect failed: "
                  << (ctx.message.empty() ? client.lastError() : ctx.message) << "\n";
        return;
    }

    auto exec_sql = [&](const std::string& sql) {
        scratchbird::client::NetworkResultSet rs;
        auto status = client.executeQuery(sql, rs, &ctx);
        if (status != scratchbird::core::Status::OK) {
            std::string msg = ctx.message.empty() ? client.lastError() : ctx.message;
            std::cerr << "[conformance_debug] setup query failed: " << msg
                      << " sql=\"" << sql << "\"\n";
        }
    };

    exec_sql("CREATE TABLE basic_table (id INT32)");
    exec_sql("DELETE FROM basic_table");
    exec_sql("INSERT INTO basic_table (id) VALUES (1), (2), (3)");

    client.disconnect();
}
}

int main(int argc, char** argv) {
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--binary-params") {
            g_binary_params = true;
        } else if (arg == "--text-params") {
            g_binary_params = false;
        } else if (arg == "--help" || arg == "-h") {
            std::cout << "Usage: sbdriver-conformance [--binary-params|--text-params]\n";
            return 0;
        }
    }
    const char* dsn_env = std::getenv("SB_CONFORMANCE_DSN");
    std::string base_dsn = dsn_env ? dsn_env : "";
    if (base_dsn.empty()) {
        std::cerr << "Missing SB_CONFORMANCE_DSN\n";
        return 2;
    }

    std::string payload = readAllStdin();
    if (payload.empty()) {
        std::cerr << "Missing manifest input\n";
        return 2;
    }

    json manifest;
    try {
        manifest = json::parse(payload);
    } catch (const json::exception& ex) {
        std::cerr << "Invalid manifest JSON: " << ex.what() << "\n";
        return 2;
    }

    json results_out = json::array();
    bool had_error = false;

    scratchbird::client::NetworkClientConfig setup_config;
    scratchbird::core::ErrorContext setup_ctx;
    if (buildConfig(base_dsn, "", setup_config, &setup_ctx)) {
        seedConformanceFixtures(setup_config);
    } else if (!setup_ctx.message.empty()) {
        std::cerr << "[conformance_debug] setup config failed: " << setup_ctx.message << "\n";
    }

    auto tests = manifest.value("tests", json::array());
    for (const auto& test : tests) {
        std::string test_id = test.value("id", "");
        std::string kind = test.value("kind", "query");
        std::string sql = test.value("sql", "");
        std::string dsn_append = test.value("dsn_append", "");
        int64_t expect_rows = test.value("expect_rows", -1);

        std::cerr << "[conformance_debug] start test=" << test_id
                  << " kind=" << kind << "\n";
        json result;
        result["test_id"] = test_id;
        result["status"] = "ok";
        result["errors"] = json::array();
        result["rows"] = json::array();
        result["columns"] = json::array();

        scratchbird::client::NetworkClientConfig config;
        scratchbird::core::ErrorContext ctx;
        if (!buildConfig(base_dsn, dsn_append, config, &ctx)) {
            results_out.push_back(makeErrorResult(test_id,
                                                  ctx.message.empty() ? "Invalid DSN" : ctx.message));
            had_error = true;
            continue;
        }

        scratchbird::client::NetworkClient client;
        std::cerr << "[conformance_debug] dsn host=" << config.host
                  << " port=" << config.port
                  << " db=" << config.database
                  << " ssl=" << static_cast<int>(config.ssl_mode) << "\n";
        auto status = client.connect(config, &ctx);
        if (status != scratchbird::core::Status::OK) {
            results_out.push_back(makeErrorResult(test_id,
                                                  ctx.message.empty() ? client.lastError() : ctx.message));
            had_error = true;
            std::cerr << "[conformance_debug] connect failed test=" << test_id
                      << " err=" << (ctx.message.empty() ? client.lastError() : ctx.message) << "\n";
            continue;
        }
        std::cerr << "[conformance_debug] connected test=" << test_id << "\n";

        if (kind == "auth") {
            result["status"] = "ok";
        } else if (kind == "query") {
            scratchbird::client::NetworkResultSet query_results;
            status = client.executeQuery(sql, query_results, &ctx);
            if (status != scratchbird::core::Status::OK) {
                result["status"] = "error";
                result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                had_error = true;
                std::cerr << "[conformance_debug] query failed test=" << test_id
                          << " err=" << (ctx.message.empty() ? client.lastError() : ctx.message) << "\n";
            } else {
                fillResultRows(result, query_results);
                if (expect_rows >= 0 &&
                    static_cast<int64_t>(query_results.rows.size()) != expect_rows) {
                    result["status"] = "error";
                    result["errors"].push_back("Row count mismatch");
                    had_error = true;
                }
            }
        } else if (kind == "prepare_bind") {
            std::string expect_sqlstate = test.value("expect_sqlstate", "");
            uint32_t stmt_id = 0;
            status = client.prepareServerStatement(sql, stmt_id, &ctx);
            if (status != scratchbird::core::Status::OK) {
                if (!expect_sqlstate.empty() && ctx.sqlstate == expect_sqlstate) {
                    result["status"] = "ok";
                } else {
                    result["status"] = "error";
                    result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                    had_error = true;
                }
            } else {
                std::vector<scratchbird::protocol::ParamValue> params;
                for (const auto& param : test.value("params", json::array())) {
                    params.push_back(jsonParamToParamValue(param));
                }
                scratchbird::client::NetworkResultSet query_results;
                bool suspended = false;
                status = client.executeServerStatement(stmt_id, params, query_results, 0, false, &suspended, &ctx);
                if (status != scratchbird::core::Status::OK) {
                    if (!expect_sqlstate.empty() && ctx.sqlstate == expect_sqlstate) {
                        result["status"] = "ok";
                    } else {
                        result["status"] = "error";
                        result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                        had_error = true;
                    }
                } else {
                    if (!expect_sqlstate.empty()) {
                        result["status"] = "error";
                        result["errors"].push_back("Expected SQLSTATE failure");
                        had_error = true;
                    }
                    fillResultRows(result, query_results);
                }
                client.closeServerStatement(stmt_id, &ctx);
            }
        } else if (kind == "prepare_reuse") {
            uint32_t stmt_id = 0;
            int reuse_count = test.value("reuse_count", 1);
            status = client.prepareServerStatement(sql, stmt_id, &ctx);
            if (status != scratchbird::core::Status::OK) {
                result["status"] = "error";
                result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                had_error = true;
            } else {
                std::vector<scratchbird::protocol::ParamValue> params;
                for (const auto& param : test.value("params", json::array())) {
                    params.push_back(jsonParamToParamValue(param));
                }
                scratchbird::client::NetworkResultSet last_results;
                for (int i = 0; i < reuse_count; ++i) {
                    scratchbird::client::NetworkResultSet query_results;
                    bool suspended = false;
                    status = client.executeServerStatement(stmt_id, params, query_results, 0, false, &suspended, &ctx);
                    if (status != scratchbird::core::Status::OK) {
                        result["status"] = "error";
                        result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                        had_error = true;
                        break;
                    }
                    last_results = std::move(query_results);
                }
                if (result["status"] == "ok") {
                    fillResultRows(result, last_results);
                }
                client.closeServerStatement(stmt_id, &ctx);
            }
        } else if (kind == "portal_paging") {
            uint32_t stmt_id = 0;
            uint32_t fetch_size = static_cast<uint32_t>(test.value("fetch_size", 1));
            status = client.prepareServerStatement(sql, stmt_id, &ctx);
            if (status != scratchbird::core::Status::OK) {
                result["status"] = "error";
                result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                had_error = true;
            } else {
                std::vector<scratchbird::protocol::ParamValue> params;
                scratchbird::client::NetworkResultSet merged;
                bool suspended = false;
                do {
                    scratchbird::client::NetworkResultSet page;
                    status = client.executeServerStatement(stmt_id, params, page, fetch_size, false,
                                                           &suspended, &ctx);
                    if (status != scratchbird::core::Status::OK) {
                        result["status"] = "error";
                        result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                        had_error = true;
                        break;
                    }
                    if (merged.columns.empty()) {
                        merged.columns = page.columns;
                    }
                    for (auto& row : page.rows) {
                        merged.rows.push_back(std::move(row));
                    }
                } while (suspended && result["status"] == "ok");

                if (result["status"] == "ok") {
                    fillResultRows(result, merged);
                    if (expect_rows >= 0 &&
                        static_cast<int64_t>(merged.rows.size()) != expect_rows) {
                        result["status"] = "error";
                        result["errors"].push_back("Row count mismatch");
                        had_error = true;
                    }
                }
                client.closeServerStatement(stmt_id, &ctx);
            }
        } else if (kind == "progress") {
            bool expect_progress = test.value("expect_progress", true);
            scratchbird::client::NetworkResultSet query_results;
            status = client.executeQuery(sql, query_results, &ctx);
            if (status != scratchbird::core::Status::OK) {
                result["status"] = "error";
                result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                had_error = true;
            } else {
                auto progress = client.queryProgress();
                if (expect_progress && progress.rows_processed == 0 && progress.bytes_processed == 0) {
                    result["status"] = "error";
                    result["errors"].push_back("No progress frames observed");
                    had_error = true;
                } else {
                    fillResultRows(result, query_results);
                }
            }
        } else if (kind == "notify") {
            std::string channel = test.value("notify_channel", "sb_event");
            std::string payload_text = test.value("notify_payload", "hello");
            std::vector<uint8_t> payload(payload_text.begin(), payload_text.end());

            status = client.subscribeNotifications(0, channel, "", &ctx);
            if (status != scratchbird::core::Status::OK) {
                result["status"] = "error";
                result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                had_error = true;
            } else {
                scratchbird::client::NetworkResultSet query_results;
                status = client.executeQuery(sql, query_results, &ctx);
                if (status != scratchbird::core::Status::OK) {
                    result["status"] = "error";
                    result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                    had_error = true;
                } else {
                    std::vector<scratchbird::client::NetworkClient::Notification> notes;
                    client.drainNotifications(notes);
                    bool matched = false;
                    for (const auto& note : notes) {
                        if (note.channel == channel && note.payload == payload) {
                            matched = true;
                            break;
                        }
                    }
                    if (!matched) {
                        result["status"] = "error";
                        result["errors"].push_back("Notification not received");
                        had_error = true;
                    } else {
                        fillResultRows(result, query_results);
                    }
                }
                client.unsubscribeNotifications(channel, &ctx);
            }
        } else if (kind == "copy") {
            std::string direction = test.value("copy_direction", "");
            if (direction == "in") {
                std::string data_file = test.value("copy_data_file", "");
                std::ifstream input(data_file, std::ios::binary);
                if (!input) {
                    result["status"] = "error";
                    result["errors"].push_back("Failed to open copy input file");
                    had_error = true;
                } else {
                    client.setCopyInputStream(&input);
                    scratchbird::client::NetworkResultSet query_results;
                    status = client.executeQuery(sql, query_results, &ctx);
                    client.setCopyInputStream(nullptr);
                    if (status != scratchbird::core::Status::OK) {
                        result["status"] = "error";
                        result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                        had_error = true;
                    } else if (expect_rows >= 0 && query_results.rows_affected != expect_rows) {
                        result["status"] = "error";
                        result["errors"].push_back("Row count mismatch");
                        had_error = true;
                    }
                }
            } else {
                std::string expect_file = test.value("copy_expect_file", "");
                std::ifstream expected(expect_file, std::ios::binary);
                std::string expected_bytes;
                if (expected) {
                    std::ostringstream buffer;
                    buffer << expected.rdbuf();
                    expected_bytes = buffer.str();
                }
                std::ostringstream output;
                client.setCopyOutputStream(&output);
                scratchbird::client::NetworkResultSet query_results;
                status = client.executeQuery(sql, query_results, &ctx);
                client.setCopyOutputStream(nullptr);
                if (status != scratchbird::core::Status::OK) {
                    result["status"] = "error";
                    result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                    had_error = true;
                } else if (!expected_bytes.empty() && output.str() != expected_bytes) {
                    result["status"] = "error";
                    result["errors"].push_back("COPY output mismatch");
                    had_error = true;
                }
            }
        } else if (kind == "lob_stream") {
            scratchbird::client::NetworkResultSet query_results;
            status = client.executeQuery(sql, query_results, &ctx);
            if (status != scratchbird::core::Status::OK) {
                result["status"] = "error";
                result["errors"].push_back(ctx.message.empty() ? client.lastError() : ctx.message);
                had_error = true;
            } else if (query_results.rows.empty() || query_results.rows[0].empty()) {
                result["status"] = "error";
                result["errors"].push_back("LOB query returned no data");
                had_error = true;
            } else {
                const auto& value = query_results.rows[0][0];
                std::vector<uint8_t> data = value.data;
                std::string expect_sha = test.value("lob_expect_sha256", "");
                std::string expect_file = test.value("lob_payload_file", "");
                if (!expect_file.empty()) {
                    std::ifstream payload(expect_file, std::ios::binary);
                    if (payload) {
                        std::ostringstream buffer;
                        buffer << payload.rdbuf();
                        std::string expected_bytes = buffer.str();
                        if (expected_bytes.size() != data.size() ||
                            !std::equal(expected_bytes.begin(), expected_bytes.end(), data.begin())) {
                            result["status"] = "error";
                            result["errors"].push_back("LOB payload mismatch");
                            had_error = true;
                        }
                    }
                }
                if (result["status"] == "ok" && !expect_sha.empty()) {
                    if (sha256Hex(data) != expect_sha) {
                        result["status"] = "error";
                        result["errors"].push_back("LOB checksum mismatch");
                        had_error = true;
                    }
                }
            }
        } else if (kind == "cancel") {
            int64_t cancel_after = test.value("cancel_after_rows", 0);
            std::string expect_sqlstate = test.value("expect_sqlstate", "");
            CancelOutcome outcome;
            std::atomic<bool> cancel_requested{false};

            std::thread worker([&]() {
                scratchbird::client::NetworkClient worker_client;
                scratchbird::core::ErrorContext worker_ctx;
                if (worker_client.connect(config, &worker_ctx) != scratchbird::core::Status::OK) {
                    outcome.status = worker_ctx.code;
                    outcome.message = worker_ctx.message;
                    outcome.sqlstate = worker_ctx.sqlstate;
                    outcome.done = true;
                    return;
                }

                uint32_t stmt_id = 0;
                if (worker_client.prepareServerStatement(sql, stmt_id, &worker_ctx) != scratchbird::core::Status::OK) {
                    outcome.status = worker_ctx.code;
                    outcome.message = worker_ctx.message;
                    outcome.sqlstate = worker_ctx.sqlstate;
                    outcome.done = true;
                    return;
                }

                std::vector<scratchbird::protocol::ParamValue> params;
                bool suspended = false;
                bool cancel_sent = false;

                while (true) {
                    scratchbird::client::NetworkResultSet page;
                    auto status_page = worker_client.executeServerStatement(
                        stmt_id, params, page, 1, false, &suspended, &worker_ctx);
                    if (status_page != scratchbird::core::Status::OK) {
                        outcome.status = status_page;
                        outcome.message = worker_ctx.message;
                        outcome.sqlstate = worker_ctx.sqlstate;
                        break;
                    }
                    outcome.rows.fetch_add(static_cast<int64_t>(page.rows.size()));

                    if (cancel_requested.load() && !cancel_sent) {
                        worker_client.sendQueryCancel(&worker_ctx);
                        cancel_sent = true;
                        continue;
                    }

                    if (!suspended) {
                        break;
                    }
                }

                worker_client.closeServerStatement(stmt_id, &worker_ctx);
                if (outcome.status == scratchbird::core::Status::OK && cancel_sent) {
                    outcome.message = "Cancel did not interrupt execution";
                }
                outcome.done = true;
            });

            while (!outcome.done.load()) {
                if (cancel_after > 0 && outcome.rows.load() >= cancel_after) {
                    cancel_requested = true;
                    break;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(5));
            }

            worker.join();

            if (!expect_sqlstate.empty()) {
                if (outcome.sqlstate != expect_sqlstate) {
                    result["status"] = "error";
                    result["errors"].push_back("Cancel SQLSTATE mismatch");
                    had_error = true;
                }
            } else if (outcome.status != scratchbird::core::Status::OK) {
                result["status"] = "error";
                result["errors"].push_back(outcome.message.empty() ? "Cancel failed" : outcome.message);
                had_error = true;
            }
        } else {
            result["status"] = "error";
            result["errors"].push_back("Unsupported test kind: " + kind);
            had_error = true;
        }

        client.disconnect();
        std::cerr << "[conformance_debug] finish test=" << test_id << "\n";
        results_out.push_back(std::move(result));
    }

    std::cout << results_out.dump(2) << "\n";
    return had_error ? 1 : 0;
}
