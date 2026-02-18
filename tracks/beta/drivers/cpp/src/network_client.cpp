/**
 * ScratchBird Network Client (SBWP v1.1)
 */

#include "scratchbird/client/network_client.h"
#include "scratchbird/client/driver_config.h"

#include <algorithm>
#include <chrono>
#include <cctype>
#include <cstring>
#include <iomanip>
#include <random>
#include <sstream>

#include <openssl/evp.h>
#include <openssl/hmac.h>
#include <openssl/rand.h>

namespace scratchbird {
namespace client {

namespace {
constexpr uint32_t kDefaultTimeoutMs = 30000;
constexpr uint32_t kCancelTypeStatement = 0;
constexpr uint8_t kDescribeStatement = 'S';
constexpr uint8_t kCloseStatement = 'S';
constexpr int64_t kMicrosPerSecond = 1000000LL;
constexpr int64_t kMicrosPerDay = 86400LL * kMicrosPerSecond;
constexpr int64_t kDaysFrom1970To2000 = 10957;

core::Status setError(core::ErrorContext* ctx, core::Status status, const std::string& message) {
    if (ctx) {
        ctx->set(status, message.c_str(), __FILE__, __LINE__, __func__);
    }
    return status;
}

std::string toLower(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(),
                   [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });
    return value;
}

bool isNativeProtocol(const std::string& value) {
    std::string lower = toLower(value);
    return lower.empty() || lower == "native";
}

std::string base64Encode(const std::vector<uint8_t>& data) {
    if (data.empty()) {
        return "";
    }
    std::string out;
    out.resize(4 * ((data.size() + 2) / 3));
    int len = EVP_EncodeBlock(reinterpret_cast<unsigned char*>(&out[0]),
                              data.data(),
                              static_cast<int>(data.size()));
    if (len < 0) {
        return "";
    }
    out.resize(static_cast<size_t>(len));
    return out;
}

std::vector<uint8_t> base64Decode(const std::string& input) {
    if (input.empty()) {
        return {};
    }
    size_t out_len = (input.size() / 4) * 3;
    std::vector<uint8_t> out(out_len);
    int len = EVP_DecodeBlock(out.data(),
                              reinterpret_cast<const unsigned char*>(input.data()),
                              static_cast<int>(input.size()));
    if (len < 0) {
        return {};
    }
    size_t padding = 0;
    if (!input.empty() && input.back() == '=') {
        padding++;
        if (input.size() > 1 && input[input.size() - 2] == '=') {
            padding++;
        }
    }
    size_t final_len = static_cast<size_t>(len);
    if (final_len >= padding) {
        final_len -= padding;
    }
    out.resize(final_len);
    return out;
}

std::string escapeScram(const std::string& value) {
    std::string out;
    out.reserve(value.size());
    for (char c : value) {
        if (c == '=') {
            out += "=3D";
        } else if (c == ',') {
            out += "=2C";
        } else {
            out.push_back(c);
        }
    }
    return out;
}

std::string generateNonce() {
    std::vector<uint8_t> buf(18);
    if (RAND_bytes(buf.data(), static_cast<int>(buf.size())) != 1) {
        return "";
    }
    return base64Encode(buf);
}

const EVP_MD* scramDigest(protocol::AuthMethod /*method*/) {
    return EVP_sha256();
}

bool scramSaltedPassword(const std::string& password,
                         const std::vector<uint8_t>& salt,
                         uint32_t iterations,
                         protocol::AuthMethod method,
                         std::vector<uint8_t>& out) {
    const EVP_MD* md = scramDigest(method);
    int hash_len = 32;
    out.assign(static_cast<size_t>(hash_len), 0);
    if (PKCS5_PBKDF2_HMAC(password.c_str(),
                          static_cast<int>(password.size()),
                          salt.data(),
                          static_cast<int>(salt.size()),
                          static_cast<int>(iterations),
                          md,
                          hash_len,
                          out.data()) != 1) {
        return false;
    }
    return true;
}

bool scramHmac(const std::vector<uint8_t>& key,
               const std::string& message,
               protocol::AuthMethod method,
               std::vector<uint8_t>& out) {
    const EVP_MD* md = scramDigest(method);
    unsigned int out_len = 32;
    out.assign(out_len, 0);
    if (!HMAC(md,
              key.data(),
              static_cast<int>(key.size()),
              reinterpret_cast<const unsigned char*>(message.data()),
              message.size(),
              out.data(),
              &out_len)) {
        return false;
    }
    out.resize(out_len);
    return true;
}

bool scramHash(const std::vector<uint8_t>& input,
               protocol::AuthMethod method,
               std::vector<uint8_t>& out) {
    const EVP_MD* md = scramDigest(method);
    unsigned int out_len = 32;
    out.assign(out_len, 0);
    EVP_MD_CTX* ctx = EVP_MD_CTX_new();
    if (!ctx) {
        return false;
    }
    bool ok = EVP_DigestInit_ex(ctx, md, nullptr) == 1;
    ok = ok && (EVP_DigestUpdate(ctx, input.data(), input.size()) == 1);
    ok = ok && (EVP_DigestFinal_ex(ctx, out.data(), &out_len) == 1);
    EVP_MD_CTX_free(ctx);
    if (!ok) {
        return false;
    }
    out.resize(out_len);
    return true;
}

struct ScramClient {
    std::string client_nonce;
    std::string client_first_bare;
    std::vector<uint8_t> server_signature;
    protocol::AuthMethod method{protocol::AuthMethod::ScramSha256};

    std::string clientFirst(const std::string& username) {
        client_nonce = generateNonce();
        client_first_bare = "n=" + escapeScram(username) + ",r=" + client_nonce;
        return "n,," + client_first_bare;
    }

    bool handleServerFirst(const std::string& password,
                           const std::string& server_first,
                           std::string& client_final,
                           std::string& error) {
        size_t r_pos = server_first.find("r=");
        size_t s_pos = server_first.find(",s=");
        size_t i_pos = server_first.find(",i=");
        if (r_pos != 0 || s_pos == std::string::npos || i_pos == std::string::npos) {
            error = "Invalid SCRAM server-first";
            return false;
        }
        std::string nonce = server_first.substr(2, s_pos - 2);
        std::string salt_b64 = server_first.substr(s_pos + 3, i_pos - (s_pos + 3));
        std::string iter_str = server_first.substr(i_pos + 3);
        if (nonce.rfind(client_nonce, 0) != 0) {
            error = "SCRAM nonce mismatch";
            return false;
        }
        uint32_t iterations = 0;
        try {
            iterations = static_cast<uint32_t>(std::stoul(iter_str));
        } catch (...) {
            error = "SCRAM invalid iteration count";
            return false;
        }
        auto salt = base64Decode(salt_b64);
        if (salt.empty()) {
            error = "SCRAM invalid salt";
            return false;
        }
        std::vector<uint8_t> salted;
        if (!scramSaltedPassword(password, salt, iterations, method, salted)) {
            error = "SCRAM salted password failed";
            return false;
        }
        std::vector<uint8_t> client_key;
        if (!scramHmac(salted, "Client Key", method, client_key)) {
            error = "SCRAM client key failed";
            return false;
        }
        std::vector<uint8_t> stored_key;
        if (!scramHash(client_key, method, stored_key)) {
            error = "SCRAM stored key failed";
            return false;
        }
        std::string client_final_without_proof = "c=biws,r=" + nonce;
        std::string auth_message = client_first_bare + "," + server_first + "," + client_final_without_proof;
        std::vector<uint8_t> client_signature;
        if (!scramHmac(stored_key, auth_message, method, client_signature)) {
            error = "SCRAM client signature failed";
            return false;
        }
        std::vector<uint8_t> client_proof(client_key.size());
        for (size_t i = 0; i < client_key.size(); ++i) {
            client_proof[i] = client_key[i] ^ client_signature[i];
        }
        std::vector<uint8_t> server_key;
        if (!scramHmac(salted, "Server Key", method, server_key)) {
            error = "SCRAM server key failed";
            return false;
        }
        if (!scramHmac(server_key, auth_message, method, server_signature)) {
            error = "SCRAM server signature failed";
            return false;
        }
        client_final = client_final_without_proof + ",p=" + base64Encode(client_proof);
        return true;
    }

    bool verifyServerFinal(const std::string& server_final) const {
        if (server_final.rfind("v=", 0) != 0) {
            return false;
        }
        auto expected = base64Encode(server_signature);
        return server_final.substr(2) == expected;
    }
};

std::string buildSchemaStatement(const std::string& schema) {
    std::string trimmed = schema;
    trimmed.erase(0, trimmed.find_first_not_of(" \t\n\r"));
    trimmed.erase(trimmed.find_last_not_of(" \t\n\r") + 1);
    if (trimmed.empty()) {
        return "";
    }
    if (trimmed.find(',') == std::string::npos) {
        return "SET SCHEMA \"" + trimmed + "\"";
    }
    std::stringstream ss;
    ss << "SET SEARCH_PATH TO ";
    size_t start = 0;
    bool first = true;
    while (start < trimmed.size()) {
        size_t end = trimmed.find(',', start);
        if (end == std::string::npos) {
            end = trimmed.size();
        }
        std::string part = trimmed.substr(start, end - start);
        part.erase(0, part.find_first_not_of(" \t\n\r"));
        part.erase(part.find_last_not_of(" \t\n\r") + 1);
        if (!part.empty()) {
            if (!first) {
                ss << ", ";
            }
            ss << "\"" << part << "\"";
            first = false;
        }
        start = end + 1;
    }
    return ss.str();
}

core::Status mapProtocolError(const protocol::ProtocolMessage& msg,
                              core::ErrorContext* ctx) {
    std::string severity;
    std::string sqlstate;
    std::string message;
    std::string detail;
    std::string hint;
    auto status = protocol::parseErrorMessage(msg.body, severity, sqlstate, message, detail, hint, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    core::Status mapped = core::Status::INTERNAL_ERROR;
    if (sqlstate.rfind("08", 0) == 0) {
        mapped = core::Status::CONNECTION_FAILURE;
    } else if (sqlstate == "28P01" || sqlstate == "28000") {
        mapped = core::Status::INVALID_PASSWORD;
    } else if (sqlstate.rfind("42", 0) == 0) {
        mapped = core::Status::SYNTAX_ERROR;
    } else if (sqlstate.rfind("23", 0) == 0) {
        mapped = core::Status::CONSTRAINT_VIOLATION;
    } else if (sqlstate == "40001") {
        mapped = core::Status::SERIALIZATION_FAILURE;
    } else if (sqlstate == "40P01") {
        mapped = core::Status::DEADLOCK;
    } else if (sqlstate == "57014") {
        mapped = core::Status::QUERY_CANCELED;
    } else if (sqlstate == "0A000") {
        mapped = core::Status::NOT_SUPPORTED;
    }
    if (!detail.empty()) {
        message += " (" + detail + ")";
    }
    if (ctx) {
        ctx->code = mapped;
        ctx->message = message;
        ctx->hint = hint;
        if (!sqlstate.empty()) {
            ctx->setSQLState(sqlstate.c_str());
        }
    }
    return mapped;
}

std::vector<uint8_t> parseUuidHex(const std::string& value) {
    std::string trimmed;
    trimmed.reserve(32);
    for (char c : value) {
        if (c == '-') {
            continue;
        }
        trimmed.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(c))));
    }
    if (trimmed.size() != 32) {
        return {};
    }
    std::vector<uint8_t> out(16);
    for (size_t i = 0; i < 16; ++i) {
        char hi = trimmed[i * 2];
        char lo = trimmed[i * 2 + 1];
        auto hexToNibble = [](char ch) -> int {
            if (ch >= '0' && ch <= '9') return ch - '0';
            if (ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
            return -1;
        };
        int high = hexToNibble(hi);
        int low = hexToNibble(lo);
        if (high < 0 || low < 0) {
            return {};
        }
        out[i] = static_cast<uint8_t>((high << 4) | low);
    }
    return out;
}

} // namespace

NetworkPreparedStatement::NetworkPreparedStatement() = default;
NetworkPreparedStatement::~NetworkPreparedStatement() = default;

NetworkPreparedStatement::NetworkPreparedStatement(NetworkPreparedStatement&& other) noexcept = default;
NetworkPreparedStatement& NetworkPreparedStatement::operator=(NetworkPreparedStatement&& other) noexcept = default;

size_t NetworkPreparedStatement::getParameterCount() const {
    return param_count_;
}

bool NetworkPreparedStatement::isValid() const {
    return valid_;
}

void NetworkPreparedStatement::clearParameters() {
    for (auto& param : params_) {
        param.data.clear();
        param.is_null = true;
    }
}

void NetworkPreparedStatement::setNull(size_t index) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = true;
}

void NetworkPreparedStatement::setNull(size_t index, uint32_t type_oid) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = true;
    params_[index - 1].type_oid = type_oid;
    param_type_oids_[index - 1] = type_oid;
}

void NetworkPreparedStatement::setBool(size_t index, bool value) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidBool;
    params_[index - 1].data = { static_cast<uint8_t>(value ? 1 : 0) };
    param_type_oids_[index - 1] = protocol::kOidBool;
}

void NetworkPreparedStatement::setInt16(size_t index, int16_t value) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidInt2;
    params_[index - 1].data.resize(2);
    params_[index - 1].data[0] = static_cast<uint8_t>(value & 0xFF);
    params_[index - 1].data[1] = static_cast<uint8_t>((value >> 8) & 0xFF);
    param_type_oids_[index - 1] = protocol::kOidInt2;
}

void NetworkPreparedStatement::setInt32(size_t index, int32_t value) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidInt4;
    params_[index - 1].data.resize(4);
    params_[index - 1].data[0] = static_cast<uint8_t>(value & 0xFF);
    params_[index - 1].data[1] = static_cast<uint8_t>((value >> 8) & 0xFF);
    params_[index - 1].data[2] = static_cast<uint8_t>((value >> 16) & 0xFF);
    params_[index - 1].data[3] = static_cast<uint8_t>((value >> 24) & 0xFF);
    param_type_oids_[index - 1] = protocol::kOidInt4;
}

void NetworkPreparedStatement::setInt64(size_t index, int64_t value) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidInt8;
    params_[index - 1].data.resize(8);
    for (size_t i = 0; i < 8; ++i) {
        params_[index - 1].data[i] = static_cast<uint8_t>((static_cast<uint64_t>(value) >> (8 * i)) & 0xFF);
    }
    param_type_oids_[index - 1] = protocol::kOidInt8;
}

void NetworkPreparedStatement::setFloat(size_t index, float value) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    uint32_t bits = 0;
    std::memcpy(&bits, &value, sizeof(bits));
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidFloat4;
    params_[index - 1].data.resize(4);
    params_[index - 1].data[0] = static_cast<uint8_t>(bits & 0xFF);
    params_[index - 1].data[1] = static_cast<uint8_t>((bits >> 8) & 0xFF);
    params_[index - 1].data[2] = static_cast<uint8_t>((bits >> 16) & 0xFF);
    params_[index - 1].data[3] = static_cast<uint8_t>((bits >> 24) & 0xFF);
    param_type_oids_[index - 1] = protocol::kOidFloat4;
}

void NetworkPreparedStatement::setDouble(size_t index, double value) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    uint64_t bits = 0;
    std::memcpy(&bits, &value, sizeof(bits));
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidFloat8;
    params_[index - 1].data.resize(8);
    for (size_t i = 0; i < 8; ++i) {
        params_[index - 1].data[i] = static_cast<uint8_t>((bits >> (8 * i)) & 0xFF);
    }
    param_type_oids_[index - 1] = protocol::kOidFloat8;
}

void NetworkPreparedStatement::setString(size_t index, const std::string& value) {
    setString(index, value, protocol::kOidText);
}

void NetworkPreparedStatement::setString(size_t index, const std::string& value, uint32_t type_oid) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    std::vector<uint8_t> data(value.begin(), value.end());
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = type_oid;
    params_[index - 1].data = std::move(data);
    param_type_oids_[index - 1] = type_oid;
}

void NetworkPreparedStatement::setBytes(size_t index, const std::vector<uint8_t>& value) {
    setBytes(index, value.data(), value.size());
}

void NetworkPreparedStatement::setBytes(size_t index, const uint8_t* data, size_t length) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    std::vector<uint8_t> bytes;
    if (data && length > 0) {
        bytes.assign(data, data + length);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidBytea;
    params_[index - 1].data = std::move(bytes);
    param_type_oids_[index - 1] = protocol::kOidBytea;
}

void NetworkPreparedStatement::setBinary(size_t index, const uint8_t* data, size_t length, uint32_t type_oid, bool length_prefixed) {
    (void)length_prefixed;
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    std::vector<uint8_t> bytes;
    if (data && length > 0) {
        bytes.assign(data, data + length);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = type_oid;
    params_[index - 1].data = std::move(bytes);
    param_type_oids_[index - 1] = type_oid;
}

void NetworkPreparedStatement::setTimestamp(size_t index, int64_t microseconds) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    int64_t micros_since_2000 = microseconds - (kDaysFrom1970To2000 * kMicrosPerDay);
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidTimestamptz;
    params_[index - 1].data.resize(8);
    for (size_t i = 0; i < 8; ++i) {
        params_[index - 1].data[i] = static_cast<uint8_t>((static_cast<uint64_t>(micros_since_2000) >> (8 * i)) & 0xFF);
    }
    param_type_oids_[index - 1] = protocol::kOidTimestamptz;
}

void NetworkPreparedStatement::setDate(size_t index, int32_t days) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidDate;
    params_[index - 1].data.resize(4);
    params_[index - 1].data[0] = static_cast<uint8_t>(days & 0xFF);
    params_[index - 1].data[1] = static_cast<uint8_t>((days >> 8) & 0xFF);
    params_[index - 1].data[2] = static_cast<uint8_t>((days >> 16) & 0xFF);
    params_[index - 1].data[3] = static_cast<uint8_t>((days >> 24) & 0xFF);
    param_type_oids_[index - 1] = protocol::kOidDate;
}

void NetworkPreparedStatement::setTime(size_t index, int64_t microseconds) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidTime;
    params_[index - 1].data.resize(8);
    for (size_t i = 0; i < 8; ++i) {
        params_[index - 1].data[i] = static_cast<uint8_t>((static_cast<uint64_t>(microseconds) >> (8 * i)) & 0xFF);
    }
    param_type_oids_[index - 1] = protocol::kOidTime;
}

void NetworkPreparedStatement::setUUID(size_t index, const std::vector<uint8_t>& value) {
    if (index == 0) {
        return;
    }
    if (params_.size() < index) {
        params_.resize(index);
        param_type_oids_.resize(index);
    }
    params_[index - 1].is_null = false;
    params_[index - 1].format = protocol::kFormatBinary;
    params_[index - 1].type_oid = protocol::kOidUuid;
    params_[index - 1].data = value;
    param_type_oids_[index - 1] = protocol::kOidUuid;
}

void NetworkPreparedStatement::setUUID(size_t index, const std::string& value) {
    auto bytes = parseUuidHex(value);
    if (bytes.empty()) {
        setNull(index, protocol::kOidUuid);
        return;
    }
    setUUID(index, bytes);
}

NetworkClient::NetworkClient() = default;
NetworkClient::~NetworkClient() {
    disconnect();
}

core::Status NetworkClient::connect(const NetworkClientConfig& config,
                                    core::ErrorContext* ctx) {
    if (connected_) {
        return setError(ctx, core::Status::INVALID_ARGUMENT, "Already connected");
    }
    if (!isNativeProtocol(config.protocol)) {
        return setError(ctx,
                        core::Status::INVALID_ARGUMENT,
                        "Only protocol=native is supported; configure the native parser listener.");
    }
    config_ = config;
    network::NetworkInitGuard guard;
    if (!guard.isInitialized()) {
        return setError(ctx, core::Status::CONNECTION_FAILURE, "Network init failed");
    }

    network::NetworkAddress address;
    address.family = network::AddressFamily::IPV4;
    address.host = config_.host;
    address.port = config_.port;

    network::SocketOptions options;
    options.connect_timeout_ms = config_.connect_timeout_ms;
    options.read_timeout_ms = config_.read_timeout_ms;
    options.write_timeout_ms = config_.write_timeout_ms;

    socket_ = network::Socket::connect(address, options, ctx);
    if (!socket_) {
        return setError(ctx, core::Status::CONNECTION_FAILURE, "Connection failed");
    }

    if (config_.ssl_mode != network::SSLMode::DISABLED) {
        security::TLSClientConfig tls_config;
        tls_config.expected_hostname = config_.host;
        tls_config.sni_hostname = config_.host;
        tls_config.cert_file = config_.ssl_cert;
        tls_config.key_file = config_.ssl_key;
        tls_config.ca_file = config_.ssl_root_cert;
        tls_config.verify_server = (config_.ssl_mode == network::SSLMode::VERIFY_CA ||
                                    config_.ssl_mode == network::SSLMode::VERIFY_FULL ||
                                    config_.ssl_mode == network::SSLMode::REQUIRE);

        tls_ctx_ = security::TLSContext::createClient(tls_config, ctx);
        if (!tls_ctx_ || !tls_ctx_->isValid()) {
            return setError(ctx, core::Status::CONNECTION_FAILURE, "TLS context init failed");
        }
        tls_conn_ = std::make_unique<security::TLSConnection>(*tls_ctx_);
        if (tls_conn_->setFd(socket_->getFd()) != core::Status::OK) {
            return setError(ctx, core::Status::CONNECTION_FAILURE, "TLS socket attach failed");
        }
        if (tls_config.sni_hostname.size() > 0) {
            tls_conn_->setSNIHostname(tls_config.sni_hostname);
        }
        if (tls_conn_->connect() != core::Status::OK) {
            return setError(ctx, core::Status::CONNECTION_FAILURE, "TLS handshake failed");
        }
        tls_active_ = true;
    } else {
        return setError(ctx, core::Status::CONNECTION_FAILURE, "TLS is required");
    }

    auto status = handshake(ctx);
    if (status != core::Status::OK) {
        disconnect();
        return status;
    }

    if (!config_.schema.empty()) {
        std::string schema_stmt = buildSchemaStatement(config_.schema);
        if (!schema_stmt.empty()) {
            NetworkResultSet ignore;
            status = executeQuery(schema_stmt, ignore, ctx);
            if (status != core::Status::OK) {
                disconnect();
                return status;
            }
        }
    }

    connected_ = true;
    return core::Status::OK;
}

void NetworkClient::disconnect() {
    if (tls_conn_) {
        tls_conn_->shutdown();
        tls_conn_.reset();
    }
    if (socket_) {
        socket_->close();
        socket_.reset();
    }
    tls_ctx_.reset();
    connected_ = false;
    in_transaction_ = false;
    last_error_.clear();
}

bool NetworkClient::isConnected() const {
    return connected_;
}

core::Status NetworkClient::executeQuery(const std::string& sql,
                                         NetworkResultSet& results,
                                         core::ErrorContext* ctx) {
    results = NetworkResultSet{};
    uint32_t seq = 0;
    auto payload = protocol::buildQueryPayload(sql, protocol::kQueryFlagBinaryResult, 0, 0);
    auto status = sendMessage(protocol::MessageType::Query, payload, 0, false, &seq, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    last_query_sequence_ = seq;
    status = sendMessage(protocol::MessageType::Sync, {}, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }

    std::vector<protocol::ColumnInfo> cols;
    while (true) {
        protocol::ProtocolMessage msg;
        status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::RowDescription: {
                cols.clear();
                status = protocol::parseRowDescription(msg.body, cols, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.columns.clear();
                results.columns.reserve(cols.size());
                for (const auto& col : cols) {
                    NetworkColumn out;
                    out.name = col.name;
                    out.type_oid = col.type_oid;
                    out.type_modifier = col.type_modifier;
                    out.format = col.format;
                    out.nullable = col.nullable;
                    results.columns.push_back(std::move(out));
                }
                break;
            }
            case protocol::MessageType::DataRow: {
                std::vector<protocol::ColumnValue> values;
                status = protocol::parseDataRow(msg.body, cols.size(), values, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows.push_back(std::move(values));
                break;
            }
            case protocol::MessageType::CommandComplete: {
                uint8_t command_type = 0;
                uint64_t rows = 0;
                uint64_t last_id = 0;
                std::string tag;
                status = protocol::parseCommandComplete(msg.body, command_type, rows, last_id, tag, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows_affected = static_cast<int64_t>(rows);
                results.command_tag = std::move(tag);
                break;
            }
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            case protocol::MessageType::Ready: {
                uint8_t status_byte = 0;
                uint64_t txn_id = 0;
                uint64_t epoch = 0;
                status = protocol::parseReady(msg.body, status_byte, txn_id, epoch, ctx);
                if (status == core::Status::OK) {
                    in_transaction_ = status_byte != 0;
                    if (txn_id != 0) {
                        // Update current txn id
                    }
                }
                return status;
            }
            default:
                break;
        }
    }
}

core::Status NetworkClient::prepare(const std::string& sql,
                                    NetworkPreparedStatement& stmt,
                                    core::ErrorContext* ctx) {
    stmt = NetworkPreparedStatement{};
    stmt.sql_ = sql;
    stmt.statement_name_ = "stmt_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count());

    auto parse_payload = protocol::buildParsePayload(stmt.statement_name_, sql, {});
    auto status = sendMessage(protocol::MessageType::Parse, parse_payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    auto describe_payload = protocol::buildDescribePayload(kDescribeStatement, stmt.statement_name_);
    status = sendMessage(protocol::MessageType::Describe, describe_payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    status = sendMessage(protocol::MessageType::Sync, {}, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }

    while (true) {
        protocol::ProtocolMessage msg;
        status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::ParameterDescription: {
                std::vector<uint32_t> types;
                status = protocol::parseParameterDescription(msg.body, types, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                stmt.param_count_ = types.size();
                break;
            }
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            case protocol::MessageType::Ready: {
                uint8_t status_byte = 0;
                uint64_t txn_id = 0;
                uint64_t epoch = 0;
                status = protocol::parseReady(msg.body, status_byte, txn_id, epoch, ctx);
                stmt.valid_ = (status == core::Status::OK);
                return status;
            }
            default:
                break;
        }
    }
}

core::Status NetworkClient::executePrepared(NetworkPreparedStatement& stmt,
                                            NetworkResultSet& results,
                                            core::ErrorContext* ctx) {
    if (!stmt.valid_) {
        return setError(ctx, core::Status::INVALID_ARGUMENT, "Prepared statement is not valid");
    }
    results = NetworkResultSet{};

    std::string portal_name = "portal_" + std::to_string(next_sequence_);
    auto bind_payload = protocol::buildBindPayload(portal_name, stmt.statement_name_, stmt.params_, {protocol::kFormatBinary});
    auto status = sendMessage(protocol::MessageType::Bind, bind_payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    auto exec_payload = protocol::buildExecutePayload(portal_name, 0);
    uint32_t seq = 0;
    status = sendMessage(protocol::MessageType::Execute, exec_payload, 0, false, &seq, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    last_query_sequence_ = seq;
    status = sendMessage(protocol::MessageType::Sync, {}, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }

    std::vector<protocol::ColumnInfo> cols;
    while (true) {
        protocol::ProtocolMessage msg;
        status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::RowDescription: {
                cols.clear();
                status = protocol::parseRowDescription(msg.body, cols, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.columns.clear();
                results.columns.reserve(cols.size());
                for (const auto& col : cols) {
                    NetworkColumn out;
                    out.name = col.name;
                    out.type_oid = col.type_oid;
                    out.type_modifier = col.type_modifier;
                    out.format = col.format;
                    out.nullable = col.nullable;
                    results.columns.push_back(std::move(out));
                }
                break;
            }
            case protocol::MessageType::DataRow: {
                std::vector<protocol::ColumnValue> values;
                status = protocol::parseDataRow(msg.body, cols.size(), values, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows.push_back(std::move(values));
                break;
            }
            case protocol::MessageType::CommandComplete: {
                uint8_t command_type = 0;
                uint64_t rows = 0;
                uint64_t last_id = 0;
                std::string tag;
                status = protocol::parseCommandComplete(msg.body, command_type, rows, last_id, tag, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows_affected = static_cast<int64_t>(rows);
                results.command_tag = std::move(tag);
                break;
            }
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            case protocol::MessageType::Ready: {
                uint8_t status_byte = 0;
                uint64_t txn_id = 0;
                uint64_t epoch = 0;
                status = protocol::parseReady(msg.body, status_byte, txn_id, epoch, ctx);
                return status;
            }
            default:
                break;
        }
    }
}

core::Status NetworkClient::prepareServerStatement(const std::string& sql,
                                                   uint32_t& stmt_id,
                                                   core::ErrorContext* ctx) {
    NetworkPreparedStatement stmt;
    auto status = prepare(sql, stmt, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    static uint32_t next_id = 1;
    stmt_id = next_id++;
    prepared_statements_[stmt_id] = std::move(stmt);
    return core::Status::OK;
}

core::Status NetworkClient::executeServerStatement(uint32_t stmt_id,
                                                   const std::vector<protocol::ParamValue>& params,
                                                   NetworkResultSet& results,
                                                   uint32_t max_rows,
                                                   bool /*backward*/,
                                                   bool* portal_suspended_out,
                                                   core::ErrorContext* ctx) {
    auto it = prepared_statements_.find(stmt_id);
    if (it == prepared_statements_.end()) {
        return setError(ctx, core::Status::INVALID_ARGUMENT, "Statement not found");
    }
    results = NetworkResultSet{};
    if (portal_suspended_out) {
        *portal_suspended_out = false;
    }

    std::string portal_name = "portal_" + std::to_string(next_sequence_);
    auto bind_payload = protocol::buildBindPayload(portal_name, it->second.statement_name_, params, {protocol::kFormatBinary});
    auto status = sendMessage(protocol::MessageType::Bind, bind_payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    auto exec_payload = protocol::buildExecutePayload(portal_name, max_rows);
    uint32_t seq = 0;
    status = sendMessage(protocol::MessageType::Execute, exec_payload, 0, false, &seq, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    last_query_sequence_ = seq;
    status = sendMessage(protocol::MessageType::Sync, {}, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }

    std::vector<protocol::ColumnInfo> cols;
    while (true) {
        protocol::ProtocolMessage msg;
        status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::RowDescription: {
                cols.clear();
                status = protocol::parseRowDescription(msg.body, cols, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.columns.clear();
                results.columns.reserve(cols.size());
                for (const auto& col : cols) {
                    NetworkColumn out;
                    out.name = col.name;
                    out.type_oid = col.type_oid;
                    out.type_modifier = col.type_modifier;
                    out.format = col.format;
                    out.nullable = col.nullable;
                    results.columns.push_back(std::move(out));
                }
                break;
            }
            case protocol::MessageType::DataRow: {
                std::vector<protocol::ColumnValue> values;
                status = protocol::parseDataRow(msg.body, cols.size(), values, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows.push_back(std::move(values));
                break;
            }
            case protocol::MessageType::CommandComplete: {
                uint8_t command_type = 0;
                uint64_t rows = 0;
                uint64_t last_id = 0;
                std::string tag;
                status = protocol::parseCommandComplete(msg.body, command_type, rows, last_id, tag, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows_affected = static_cast<int64_t>(rows);
                results.command_tag = std::move(tag);
                break;
            }
            case protocol::MessageType::PortalSuspended:
                if (portal_suspended_out) {
                    *portal_suspended_out = true;
                }
                break;
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            case protocol::MessageType::Ready: {
                uint8_t status_byte = 0;
                uint64_t txn_id = 0;
                uint64_t epoch = 0;
                status = protocol::parseReady(msg.body, status_byte, txn_id, epoch, ctx);
                return status;
            }
            default:
                break;
        }
    }
}

core::Status NetworkClient::closeServerStatement(uint32_t stmt_id,
                                                 core::ErrorContext* ctx) {
    auto it = prepared_statements_.find(stmt_id);
    if (it == prepared_statements_.end()) {
        return setError(ctx, core::Status::INVALID_ARGUMENT, "Statement not found");
    }
    auto close_payload = protocol::buildClosePayload(kCloseStatement, it->second.statement_name_);
    auto status = sendMessage(protocol::MessageType::Close, close_payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    status = sendMessage(protocol::MessageType::Sync, {}, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    prepared_statements_.erase(it);
    std::string tag;
    uint64_t rows = 0;
    uint64_t last_id = 0;
    return drainUntilReady(&tag, &rows, &last_id, ctx);
}

core::Status NetworkClient::sendQueryCancel(core::ErrorContext* ctx) {
    if (!connected_) {
        return setError(ctx, core::Status::CONNECTION_DOES_NOT_EXIST, "Connection not open");
    }
    if (last_query_sequence_ == 0) {
        return setError(ctx, core::Status::INVALID_ARGUMENT, "No in-flight query to cancel");
    }
    auto payload = protocol::buildCancelPayload(kCancelTypeStatement, last_query_sequence_);
    return sendMessage(protocol::MessageType::Cancel, payload, protocol::kFlagUrgent, false, nullptr, ctx);
}

core::Status NetworkClient::subscribeNotifications(uint8_t subscribe_type,
                                                   const std::string& channel,
                                                   const std::string& filter,
                                                   core::ErrorContext* ctx) {
    auto payload = protocol::buildSubscribePayload(subscribe_type, channel, filter);
    auto status = sendMessage(protocol::MessageType::Subscribe, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    return drainUntilReady(nullptr, nullptr, nullptr, ctx);
}

core::Status NetworkClient::unsubscribeNotifications(const std::string& channel,
                                                     core::ErrorContext* ctx) {
    auto payload = protocol::buildUnsubscribePayload(channel);
    auto status = sendMessage(protocol::MessageType::Unsubscribe, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    return drainUntilReady(nullptr, nullptr, nullptr, ctx);
}

core::Status NetworkClient::streamControl(uint8_t control_type,
                                          uint32_t window_size,
                                          uint32_t timeout_ms,
                                          core::ErrorContext* ctx) {
    auto payload = protocol::buildStreamControlPayload(control_type, window_size, timeout_ms);
    return sendMessage(protocol::MessageType::StreamControl, payload, 0, false, nullptr, ctx);
}

core::Status NetworkClient::attachCreate(const std::string& mode,
                                         const std::string& db_name,
                                         core::ErrorContext* ctx) {
    auto payload = protocol::buildAttachCreatePayload(mode, db_name);
    auto status = sendMessage(protocol::MessageType::AttachCreate, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    return drainUntilReady(nullptr, nullptr, nullptr, ctx);
}

core::Status NetworkClient::attachDetach(core::ErrorContext* ctx) {
    auto payload = protocol::buildAttachDetachPayload();
    auto status = sendMessage(protocol::MessageType::AttachDetach, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    return drainUntilReady(nullptr, nullptr, nullptr, ctx);
}

core::Status NetworkClient::attachList(NetworkResultSet& results,
                                       core::ErrorContext* ctx) {
    results = NetworkResultSet{};
    auto payload = protocol::buildAttachListPayload();
    auto status = sendMessage(protocol::MessageType::AttachList, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    status = sendMessage(protocol::MessageType::Sync, {}, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    std::vector<protocol::ColumnInfo> cols;
    while (true) {
        protocol::ProtocolMessage msg;
        status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::RowDescription: {
                cols.clear();
                status = protocol::parseRowDescription(msg.body, cols, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.columns.clear();
                results.columns.reserve(cols.size());
                for (const auto& col : cols) {
                    NetworkColumn out;
                    out.name = col.name;
                    out.type_oid = col.type_oid;
                    out.type_modifier = col.type_modifier;
                    out.format = col.format;
                    out.nullable = col.nullable;
                    results.columns.push_back(std::move(out));
                }
                break;
            }
            case protocol::MessageType::DataRow: {
                std::vector<protocol::ColumnValue> values;
                status = protocol::parseDataRow(msg.body, cols.size(), values, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows.push_back(std::move(values));
                break;
            }
            case protocol::MessageType::CommandComplete: {
                uint8_t command_type = 0;
                uint64_t rows = 0;
                uint64_t last_id = 0;
                std::string tag;
                status = protocol::parseCommandComplete(msg.body, command_type, rows, last_id, tag, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows_affected = static_cast<int64_t>(rows);
                results.command_tag = std::move(tag);
                break;
            }
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            case protocol::MessageType::Ready: {
                uint8_t status_byte = 0;
                uint64_t txn_id = 0;
                uint64_t epoch = 0;
                status = protocol::parseReady(msg.body, status_byte, txn_id, epoch, ctx);
                return status;
            }
            default:
                break;
        }
    }
}

core::Status NetworkClient::setOption(const std::string& name,
                                      const std::string& value,
                                      core::ErrorContext* ctx) {
    auto payload = protocol::buildSetOptionPayload(name, value);
    auto status = sendMessage(protocol::MessageType::SetOption, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    return drainUntilReady(nullptr, nullptr, nullptr, ctx);
}

core::Status NetworkClient::ping(core::ErrorContext* ctx) {
    auto status = sendMessage(protocol::MessageType::Ping, {}, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    while (true) {
        protocol::ProtocolMessage msg;
        status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::Pong:
                return core::Status::OK;
            case protocol::MessageType::Ready: {
                uint8_t status_byte = 0;
                uint64_t txn_id = 0;
                uint64_t epoch = 0;
                status = protocol::parseReady(msg.body, status_byte, txn_id, epoch, ctx);
                if (status == core::Status::OK) {
                    in_transaction_ = status_byte != 0;
                }
                return status;
            }
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            default:
                break;
        }
    }
}

core::Status NetworkClient::executeSblr(uint64_t sblr_hash,
                                        const std::vector<uint8_t>& bytecode,
                                        const std::vector<protocol::ParamValue>& params,
                                        NetworkResultSet& results,
                                        core::ErrorContext* ctx) {
    results = NetworkResultSet{};
    auto payload = protocol::buildSblrExecutePayload(sblr_hash, bytecode, params);
    uint32_t seq = 0;
    auto status = sendMessage(protocol::MessageType::SblrExecute, payload, 0, false, &seq, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    last_query_sequence_ = seq;
    status = sendMessage(protocol::MessageType::Sync, {}, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }

    std::vector<protocol::ColumnInfo> cols;
    while (true) {
        protocol::ProtocolMessage msg;
        status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::RowDescription: {
                cols.clear();
                status = protocol::parseRowDescription(msg.body, cols, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.columns.clear();
                results.columns.reserve(cols.size());
                for (const auto& col : cols) {
                    NetworkColumn out;
                    out.name = col.name;
                    out.type_oid = col.type_oid;
                    out.type_modifier = col.type_modifier;
                    out.format = col.format;
                    out.nullable = col.nullable;
                    results.columns.push_back(std::move(out));
                }
                break;
            }
            case protocol::MessageType::DataRow: {
                std::vector<protocol::ColumnValue> values;
                status = protocol::parseDataRow(msg.body, cols.size(), values, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows.push_back(std::move(values));
                break;
            }
            case protocol::MessageType::CommandComplete: {
                uint8_t command_type = 0;
                uint64_t rows = 0;
                uint64_t last_id = 0;
                std::string tag;
                status = protocol::parseCommandComplete(msg.body, command_type, rows, last_id, tag, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                results.rows_affected = static_cast<int64_t>(rows);
                results.command_tag = std::move(tag);
                break;
            }
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            case protocol::MessageType::Ready: {
                uint8_t status_byte = 0;
                uint64_t txn_id = 0;
                uint64_t epoch = 0;
                status = protocol::parseReady(msg.body, status_byte, txn_id, epoch, ctx);
                return status;
            }
            default:
                break;
        }
    }
}

void NetworkClient::resetQueryProgress() {
    query_progress_ = QueryProgressSnapshot{};
}

void NetworkClient::drainNotifications(std::vector<Notification>& out) {
    out = std::move(notifications_);
    notifications_.clear();
}

bool NetworkClient::takeLastQueryPlan(protocol::QueryPlan& out) {
    if (!last_plan_) {
        return false;
    }
    out = std::move(*last_plan_);
    last_plan_.reset();
    return true;
}

bool NetworkClient::takeLastSblrCompiled(protocol::SblrCompiled& out) {
    if (!last_sblr_) {
        return false;
    }
    out = std::move(*last_sblr_);
    last_sblr_.reset();
    return true;
}

core::Status NetworkClient::beginTransaction(core::ErrorContext* ctx) {
    auto payload = protocol::buildTxnBeginPayload(0, 0, 0, 0, 0, 0, 0, 0);
    auto status = sendMessage(protocol::MessageType::TxnBegin, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    return drainUntilReady(nullptr, nullptr, nullptr, ctx);
}

core::Status NetworkClient::commit(core::ErrorContext* ctx) {
    auto payload = protocol::buildTxnCommitPayload(0);
    auto status = sendMessage(protocol::MessageType::TxnCommit, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    return drainUntilReady(nullptr, nullptr, nullptr, ctx);
}

core::Status NetworkClient::rollback(core::ErrorContext* ctx) {
    auto payload = protocol::buildTxnRollbackPayload(0);
    auto status = sendMessage(protocol::MessageType::TxnRollback, payload, 0, false, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    return drainUntilReady(nullptr, nullptr, nullptr, ctx);
}

core::Status NetworkClient::sendMessage(const protocol::ProtocolMessage& msg,
                                        core::ErrorContext* ctx) {
    auto buf = protocol::encodeMessage(msg.header, msg.body);
    if (tls_active_) {
        size_t total = 0;
        while (total < buf.size()) {
            int rc = tls_conn_->write(buf.data() + total, static_cast<int>(buf.size() - total));
            if (rc <= 0) {
                return setError(ctx, core::Status::CONNECTION_FAILURE, "TLS write failed");
            }
            total += static_cast<size_t>(rc);
        }
        return core::Status::OK;
    }
    size_t written = 0;
    auto status = socket_->writeExact(buf.data(), buf.size(), ctx);
    if (status != core::Status::OK) {
        return setError(ctx, core::Status::CONNECTION_FAILURE, "Socket write failed");
    }
    return core::Status::OK;
}

core::Status NetworkClient::receiveMessage(protocol::ProtocolMessage& msg,
                                           core::ErrorContext* ctx) {
    std::vector<uint8_t> header_bytes(protocol::kHeaderSize);
    auto status = readExactWithTimeout(header_bytes.data(), header_bytes.size(), ctx);
    if (status != core::Status::OK) {
        return status;
    }
    protocol::MessageHeader header;
    status = protocol::decodeHeader(header_bytes, header, ctx);
    if (status != core::Status::OK) {
        return status;
    }
    msg.header = header;
    msg.body.clear();
    if (header.length > 0) {
        msg.body.resize(header.length);
        status = readExactWithTimeout(msg.body.data(), msg.body.size(), ctx);
        if (status != core::Status::OK) {
            return status;
        }
    }
    return core::Status::OK;
}

core::Status NetworkClient::readExactWithTimeout(void* buffer, size_t size,
                                                 core::ErrorContext* ctx) {
    if (size == 0) {
        return core::Status::OK;
    }
    size_t total = 0;
    while (total < size) {
        if (tls_active_) {
            int rc = tls_conn_->read(static_cast<uint8_t*>(buffer) + total,
                                     static_cast<int>(size - total));
            if (rc <= 0) {
                return setError(ctx, core::Status::CONNECTION_FAILURE, "TLS read failed");
            }
            total += static_cast<size_t>(rc);
            continue;
        }
        size_t bytes_read = 0;
        auto status = socket_->readWithTimeout(static_cast<uint8_t*>(buffer) + total,
                                               size - total,
                                               &bytes_read,
                                               config_.read_timeout_ms,
                                               ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (bytes_read == 0) {
            return setError(ctx, core::Status::CONNECTION_FAILURE, "Connection closed");
        }
        total += bytes_read;
    }
    return core::Status::OK;
}

core::Status NetworkClient::handleAsyncMessage(const protocol::ProtocolMessage& msg,
                                               core::ErrorContext* ctx) {
    switch (msg.header.type) {
        case protocol::MessageType::ParameterStatus: {
            std::string name;
            std::string value;
            auto status = protocol::parseParameterStatus(msg.body, name, value, ctx);
            if (status == core::Status::OK) {
                parameter_status_[name] = value;
                if (name == "attachment_id") {
                    auto uuid = parseUuidHex(value);
                    if (uuid.size() == session_id_.size()) {
                        std::copy(uuid.begin(), uuid.end(), session_id_.begin());
                    }
                }
            }
            return status;
        }
        case protocol::MessageType::Notification: {
            protocol::Notification note;
            auto status = protocol::parseNotification(msg.body, note, ctx);
            if (status == core::Status::OK) {
                Notification client_note;
                client_note.process_id = note.process_id;
                client_note.channel = note.channel;
                client_note.payload = std::move(note.payload);
                client_note.change_type = note.change_type;
                client_note.row_id = note.row_id;
                notifications_.push_back(std::move(client_note));
            }
            return status;
        }
        case protocol::MessageType::QueryPlan: {
            auto plan = std::make_unique<protocol::QueryPlan>();
            auto status = protocol::parseQueryPlan(msg.body, *plan, ctx);
            if (status == core::Status::OK) {
                last_plan_ = std::move(plan);
            }
            return status;
        }
        case protocol::MessageType::SblrCompiled: {
            auto compiled = std::make_unique<protocol::SblrCompiled>();
            auto status = protocol::parseSblrCompiled(msg.body, *compiled, ctx);
            if (status == core::Status::OK) {
                last_sblr_ = std::move(compiled);
            }
            return status;
        }
        default:
            return core::Status::OK;
    }
}

core::Status NetworkClient::drainUntilReady(std::string* command_tag,
                                            uint64_t* rows,
                                            uint64_t* last_id,
                                            core::ErrorContext* ctx) {
    std::string tag;
    uint64_t local_rows = 0;
    uint64_t local_last = 0;
    while (true) {
        protocol::ProtocolMessage msg;
        auto status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::CommandComplete: {
                uint8_t command_type = 0;
                status = protocol::parseCommandComplete(msg.body, command_type, local_rows, local_last, tag, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                break;
            }
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            case protocol::MessageType::Ready:
                if (command_tag) {
                    *command_tag = tag;
                }
                if (rows) {
                    *rows = local_rows;
                }
                if (last_id) {
                    *last_id = local_last;
                }
                return core::Status::OK;
            default:
                break;
        }
    }
}

core::Status NetworkClient::sendMessage(protocol::MessageType type,
                                        const std::vector<uint8_t>& payload,
                                        uint8_t flags,
                                        bool force_zero,
                                        uint32_t* sequence_out,
                                        core::ErrorContext* ctx) {
    protocol::ProtocolMessage msg;
    msg.header.type = type;
    msg.header.flags = flags;
    msg.header.sequence = force_zero ? 0 : next_sequence_++;
    if (sequence_out) {
        *sequence_out = msg.header.sequence;
    }
    msg.header.attachment_id = session_id_;
    msg.header.txn_id = 0;
    msg.body = payload;
    return sendMessage(msg, ctx);
}

core::Status NetworkClient::handshake(core::ErrorContext* ctx) {
    next_sequence_ = 1;
    parameter_status_.clear();
    session_id_.fill(0);
    uint64_t features = protocol::kFeatureSblr | protocol::kFeatureNotifications | protocol::kFeatureQueryPlan;
    if (config_.enable_compression) {
        features |= protocol::kFeatureCompression;
    }
    std::map<std::string, std::string> params;
    params["database"] = config_.database;
    params["user"] = config_.username;
    if (!config_.role.empty()) {
        params["role"] = config_.role;
    }
    if (!config_.application_name.empty()) {
        params["application_name"] = config_.application_name;
    }

    auto payload = protocol::buildStartupPayload(features, params);
    auto status = sendMessage(protocol::MessageType::Startup, payload, 0, true, nullptr, ctx);
    if (status != core::Status::OK) {
        return status;
    }

    std::unique_ptr<ScramClient> scram;
    while (true) {
        protocol::ProtocolMessage msg;
        status = receiveMessage(msg, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        if (handleAsyncMessage(msg, ctx) == core::Status::OK &&
            (msg.header.type == protocol::MessageType::ParameterStatus ||
             msg.header.type == protocol::MessageType::Notification ||
             msg.header.type == protocol::MessageType::QueryPlan ||
             msg.header.type == protocol::MessageType::SblrCompiled)) {
            continue;
        }
        switch (msg.header.type) {
            case protocol::MessageType::NegotiateVersion:
                continue;
            case protocol::MessageType::AuthRequest: {
                protocol::AuthMethod method;
                std::vector<uint8_t> data;
                status = protocol::parseAuthRequest(msg.body, method, data, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                if (method == protocol::AuthMethod::Ok) {
                    continue;
                }
                if (method == protocol::AuthMethod::Password) {
                    std::vector<uint8_t> resp(config_.password.begin(), config_.password.end());
                    status = sendMessage(protocol::MessageType::AuthResponse, resp, 0, true, nullptr, ctx);
                    if (status != core::Status::OK) {
                        return status;
                    }
                    continue;
                }
                if (method == protocol::AuthMethod::ScramSha256) {
                    if (!scram) {
                        scram = std::make_unique<ScramClient>();
                        scram->method = method;
                    }
                    std::string first = scram->clientFirst(config_.username);
                    std::vector<uint8_t> resp(first.begin(), first.end());
                    status = sendMessage(protocol::MessageType::AuthResponse, resp, 0, true, nullptr, ctx);
                    if (status != core::Status::OK) {
                        return status;
                    }
                    continue;
                }
                return setError(ctx, core::Status::INVALID_AUTHORIZATION, "Unsupported auth method");
            }
            case protocol::MessageType::AuthContinue: {
                protocol::AuthMethod method;
                uint8_t stage = 0;
                std::vector<uint8_t> data;
                status = protocol::parseAuthContinue(msg.body, method, stage, data, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                if (!scram || method != protocol::AuthMethod::ScramSha256) {
                    return setError(ctx, core::Status::INVALID_AUTHORIZATION, "SCRAM state missing");
                }
                std::string client_final;
                std::string error;
                if (!scram->handleServerFirst(config_.password, std::string(data.begin(), data.end()), client_final, error)) {
                    return setError(ctx, core::Status::INVALID_AUTHORIZATION, error);
                }
                std::vector<uint8_t> resp(client_final.begin(), client_final.end());
                status = sendMessage(protocol::MessageType::AuthResponse, resp, 0, true, nullptr, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                continue;
            }
            case protocol::MessageType::AuthOk: {
                std::vector<uint8_t> session_id;
                std::vector<uint8_t> info;
                status = protocol::parseAuthOk(msg.body, session_id, info, ctx);
                if (status != core::Status::OK) {
                    return status;
                }
                if (msg.header.attachment_id.size() == session_id_.size()) {
                    session_id_ = msg.header.attachment_id;
                }
                if (scram && !info.empty()) {
                    std::string info_str(info.begin(), info.end());
                    if (!scram->verifyServerFinal(info_str)) {
                        return setError(ctx, core::Status::INVALID_AUTHORIZATION, "SCRAM verification failed");
                    }
                }
                continue;
            }
            case protocol::MessageType::Ready: {
                uint8_t status_byte = 0;
                uint64_t txn_id = 0;
                uint64_t epoch = 0;
                return protocol::parseReady(msg.body, status_byte, txn_id, epoch, ctx);
            }
            case protocol::MessageType::Error:
                return mapProtocolError(msg, ctx);
            default:
                break;
        }
    }
}

} // namespace client
} // namespace scratchbird
