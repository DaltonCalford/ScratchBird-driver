#include "scratchbird/client/driver_config.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <sstream>

namespace scratchbird {
namespace client {

namespace {
std::string toLower(const std::string& value) {
    std::string out = value;
    std::transform(out.begin(), out.end(), out.begin(),
                   [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });
    return out;
}

std::string trim(std::string value) {
    auto first = value.find_first_not_of(" \t\n\r");
    if (first == std::string::npos) {
        return "";
    }
    auto last = value.find_last_not_of(" \t\n\r");
    value.erase(last + 1);
    value.erase(0, first);
    return value;
}

bool parseUint32(const std::string& value, uint32_t& out) {
    try {
        size_t idx = 0;
        unsigned long parsed = std::stoul(value, &idx);
        if (idx != value.size()) {
            return false;
        }
        out = static_cast<uint32_t>(parsed);
        return true;
    } catch (...) {
        return false;
    }
}

bool parseBool(const std::string& value, bool& out) {
    std::string lower = toLower(trim(value));
    if (lower == "true" || lower == "1" || lower == "yes" || lower == "on") {
        out = true;
        return true;
    }
    if (lower == "false" || lower == "0" || lower == "no" || lower == "off") {
        out = false;
        return true;
    }
    return false;
}

bool parseProtocol(const std::string& value, std::string& normalized) {
    std::string lower = toLower(trim(value));
    if (lower == "native" || lower == "scratchbird" ||
        lower == "scratchbird-native" || lower == "scratchbird_native") {
        normalized = "native";
        return true;
    }
    return false;
}

bool parseFrontDoorMode(const std::string& value, std::string& normalized) {
    std::string lower = toLower(trim(value));
    if (lower.empty() || lower == "direct") {
        normalized = "direct";
        return true;
    }
    if (lower == "manager_proxy" || lower == "manager-proxy" || lower == "managed") {
        normalized = "manager_proxy";
        return true;
    }
    return false;
}

uint32_t normalizeTimeoutMs(const std::string& key, const std::string& value) {
    uint32_t parsed = 0;
    if (!parseUint32(value, parsed)) {
        return 0;
    }
    std::string lower = toLower(key);
    if (lower.find("_ms") != std::string::npos || lower.find("ms") != std::string::npos) {
        return parsed;
    }
    return parsed * 1000;
}
}

network::SSLMode parseSslMode(const std::string& value) {
    auto mode = toLower(value);
    if (mode == "disable" || mode == "disabled") {
        return network::SSLMode::DISABLED;
    }
    if (mode == "allow") {
        return network::SSLMode::ALLOW;
    }
    if (mode == "prefer") {
        return network::SSLMode::PREFER;
    }
    if (mode == "require") {
        return network::SSLMode::REQUIRE;
    }
    if (mode == "verify-ca" || mode == "verify_ca") {
        return network::SSLMode::VERIFY_CA;
    }
    if (mode == "verify-full" || mode == "verify_full") {
        return network::SSLMode::VERIFY_FULL;
    }
    return network::SSLMode::REQUIRE;
}

protocol::AuthMethod parseAuthMethod(const std::string& value, bool* ok) {
    std::string lower = toLower(value);
    if (lower == "scram-sha-256" || lower == "scram_sha_256" || lower == "scram256") {
        if (ok) {
            *ok = true;
        }
        return protocol::AuthMethod::ScramSha256;
    }
    if (lower == "scram-sha-512" || lower == "scram_sha_512" || lower == "scram512") {
        if (ok) {
            *ok = false;
        }
        return protocol::AuthMethod::ScramSha256;
    }
    if (lower == "password" || lower == "plain") {
        if (ok) {
            *ok = true;
        }
        return protocol::AuthMethod::Password;
    }
    if (lower == "md5") {
        if (ok) {
            *ok = true;
        }
        return protocol::AuthMethod::Md5;
    }
    if (ok) {
        *ok = false;
    }
    return protocol::AuthMethod::ScramSha256;
}

core::Status parseKeyValueConnectionString(const std::string& conn_str,
                                           std::map<std::string, std::string>& params,
                                           core::ErrorContext* ctx) {
    params.clear();

    size_t start = 0;
    while (start < conn_str.size()) {
        size_t end = conn_str.find(';', start);
        if (end == std::string::npos) {
            end = conn_str.size();
        }
        std::string token = conn_str.substr(start, end - start);
        start = end + 1;
        token = trim(token);
        if (token.empty()) {
            continue;
        }
        size_t eq = token.find('=');
        if (eq == std::string::npos) {
            continue;
        }
        std::string key = trim(token.substr(0, eq));
        std::string value = trim(token.substr(eq + 1));
        if (value.size() >= 2 && value.front() == '{' && value.back() == '}') {
            value = value.substr(1, value.size() - 2);
        }
        if (!key.empty()) {
            params[toLower(key)] = value;
        }
    }

    if (params.empty() && ctx) {
        ctx->message = "Empty connection string";
    }
    return core::Status::OK;
}

core::Status parseScratchbirdUrl(const std::string& url,
                                 NetworkClientConfig& config,
                                 core::ErrorContext* ctx) {
    const std::string kPrefix = "scratchbird://";
    if (url.rfind(kPrefix, 0) != 0) {
        if (ctx) {
            ctx->message = "Unsupported URL scheme";
        }
        return core::Status::INVALID_ARGUMENT;
    }

    std::string remainder = url.substr(kPrefix.size());
    std::string query;
    size_t query_pos = remainder.find('?');
    if (query_pos != std::string::npos) {
        query = remainder.substr(query_pos + 1);
        remainder = remainder.substr(0, query_pos);
    }

    std::string userinfo;
    std::string hostport;
    std::string database;

    size_t at_pos = remainder.find('@');
    if (at_pos != std::string::npos) {
        userinfo = remainder.substr(0, at_pos);
        hostport = remainder.substr(at_pos + 1);
    } else {
        hostport = remainder;
    }

    size_t slash_pos = hostport.find('/');
    if (slash_pos != std::string::npos) {
        database = hostport.substr(slash_pos + 1);
        hostport = hostport.substr(0, slash_pos);
    }

    std::string host = hostport;
    std::string port_str;
    size_t colon_pos = hostport.rfind(':');
    if (colon_pos != std::string::npos && colon_pos + 1 < hostport.size()) {
        host = hostport.substr(0, colon_pos);
        port_str = hostport.substr(colon_pos + 1);
    }

    if (!userinfo.empty()) {
        size_t colon = userinfo.find(':');
        if (colon == std::string::npos) {
            config.username = userinfo;
        } else {
            config.username = userinfo.substr(0, colon);
            config.password = userinfo.substr(colon + 1);
        }
    }

    if (!host.empty()) {
        config.host = host;
    }
    if (!port_str.empty()) {
        uint32_t port_val = 0;
        if (!parseUint32(port_str, port_val) || port_val > 65535) {
            if (ctx) {
                ctx->message = "Invalid port in URL";
            }
            return core::Status::INVALID_ARGUMENT;
        }
        config.port = static_cast<uint16_t>(port_val);
    }
    if (!database.empty()) {
        config.database = database;
    }

    if (!query.empty()) {
        std::map<std::string, std::string> params;
        std::stringstream ss(query);
        std::string pair;
        while (std::getline(ss, pair, '&')) {
            size_t eq = pair.find('=');
            if (eq == std::string::npos) {
                continue;
            }
            std::string key = toLower(trim(pair.substr(0, eq)));
            std::string value = trim(pair.substr(eq + 1));
            if (!key.empty()) {
                params[key] = value;
            }
        }
        auto status = applyConnectionParams(params, config, ctx);
        if (status != core::Status::OK) {
            return status;
        }
    }

    return core::Status::OK;
}

core::Status applyConnectionParams(const std::map<std::string, std::string>& params,
                                   NetworkClientConfig& config,
                                   core::ErrorContext* ctx) {
    for (const auto& entry : params) {
        const std::string& key = entry.first;
        const std::string& value = entry.second;
        if (key == "server" || key == "host") {
            config.host = value;
        } else if (key == "port") {
            uint32_t parsed = 0;
            if (!parseUint32(value, parsed) || parsed > 65535) {
                if (ctx) {
                    ctx->message = "Invalid port";
                }
                return core::Status::INVALID_ARGUMENT;
            }
            config.port = static_cast<uint16_t>(parsed);
        } else if (key == "database" || key == "db") {
            config.database = value;
        } else if (key == "uid" || key == "user" || key == "username") {
            config.username = value;
        } else if (key == "pwd" || key == "password") {
            config.password = value;
        } else if (key == "role") {
            config.role = value;
        } else if (key == "schema") {
            config.schema = value;
        } else if (key == "protocol" || key == "parser" || key == "dialect") {
            std::string normalized;
            if (!parseProtocol(value, normalized)) {
                if (ctx) {
                    ctx->message = "Only protocol=native is supported; connect to the native parser listener/port.";
                }
                return core::Status::INVALID_ARGUMENT;
            }
            config.protocol = normalized;
        } else if (key == "front_door_mode" || key == "frontdoormode" ||
                   key == "connection_mode" || key == "ingress_mode") {
            std::string normalized;
            if (!parseFrontDoorMode(value, normalized)) {
                if (ctx) {
                    ctx->message = "front_door_mode must be direct or manager_proxy";
                }
                return core::Status::INVALID_ARGUMENT;
            }
            config.front_door_mode = normalized;
        } else if (key == "manager_auth_token" || key == "mcp_auth_token" ||
                   key == "managerauthtoken") {
            config.manager_auth_token = value;
        } else if (key == "manager_username" || key == "mcp_username") {
            config.manager_username = value;
        } else if (key == "manager_database" || key == "mcp_database") {
            config.manager_database = value;
        } else if (key == "manager_connection_profile" || key == "mcp_connection_profile") {
            config.manager_connection_profile = value;
        } else if (key == "manager_client_intent" || key == "mcp_client_intent") {
            config.manager_client_intent = value;
        } else if (key == "manager_client_flags" || key == "mcp_client_flags") {
            uint32_t parsed = 0;
            if (!parseUint32(value, parsed) || parsed > 65535u) {
                if (ctx) {
                    ctx->message = "Invalid manager_client_flags";
                }
                return core::Status::INVALID_ARGUMENT;
            }
            config.manager_client_flags = static_cast<uint16_t>(parsed);
        } else if (key == "manager_auth_fast_path" || key == "mcp_auth_fast_path") {
            bool parsed = false;
            if (parseBool(value, parsed)) {
                config.manager_auth_fast_path = parsed;
            }
        } else if (key == "applicationname" || key == "application_name" || key == "app") {
            config.application_name = value;
        } else if (key == "ssl" || key == "sslmode") {
            config.ssl_mode = parseSslMode(value);
        } else if (key == "sslcert") {
            config.ssl_cert = value;
        } else if (key == "sslkey") {
            config.ssl_key = value;
        } else if (key == "sslrootcert") {
            config.ssl_root_cert = value;
        } else if (key == "connecttimeout" || key == "connect_timeout" || key == "timeout") {
            uint32_t ms = normalizeTimeoutMs(key, value);
            if (ms > 0) {
                config.connect_timeout_ms = ms;
            }
        } else if (key == "readtimeout" || key == "read_timeout") {
            uint32_t ms = normalizeTimeoutMs(key, value);
            if (ms > 0) {
                config.read_timeout_ms = ms;
            }
        } else if (key == "writetimeout" || key == "write_timeout") {
            uint32_t ms = normalizeTimeoutMs(key, value);
            if (ms > 0) {
                config.write_timeout_ms = ms;
            }
        } else if (key == "querytimeout" || key == "query_timeout") {
            uint32_t ms = normalizeTimeoutMs(key, value);
            if (ms > 0) {
                config.read_timeout_ms = ms;
                config.write_timeout_ms = ms;
            }
        } else if (key == "authmethod" || key == "auth_method") {
            bool ok = false;
            config.auth_method = parseAuthMethod(value, &ok);
            if (!ok && ctx) {
                ctx->message = "Unsupported auth_method";
            }
            if (!ok) {
                return core::Status::INVALID_ARGUMENT;
            }
        } else if (key == "allowpasswordfallback") {
            bool parsed = false;
            if (parseBool(value, parsed)) {
                config.allow_password_fallback = parsed;
            }
        } else if (key == "dsn" && config.host.empty()) {
            config.host = value;
        }
    }

    return core::Status::OK;
}

core::Status parseDriverConnectionString(const std::string& conn_str,
                                         NetworkClientConfig& config,
                                         core::ErrorContext* ctx) {
    std::string trimmed = trim(conn_str);
    if (trimmed.rfind("scratchbird://", 0) == 0) {
        auto status = parseScratchbirdUrl(trimmed, config, ctx);
        if (status != core::Status::OK) {
            return status;
        }
    } else {
        std::map<std::string, std::string> params;
        auto status = parseKeyValueConnectionString(trimmed, params, ctx);
        if (status != core::Status::OK) {
            return status;
        }
        status = applyConnectionParams(params, config, ctx);
        if (status != core::Status::OK) {
            return status;
        }
    }

    applyDriverDefaults(config);
    return core::Status::OK;
}

void applyDriverDefaults(NetworkClientConfig& config) {
    if (config.host.empty()) {
        config.host = "127.0.0.1";
    }
    if (config.application_name.empty()) {
        config.application_name = "scratchbird_driver";
    }
    if (config.front_door_mode.empty()) {
        config.front_door_mode = "direct";
    }
    if (config.manager_username.empty()) {
        config.manager_username = config.username.empty() ? "admin" : config.username;
    }
    if (config.manager_database.empty()) {
        config.manager_database = config.database;
    }
    if (config.manager_connection_profile.empty()) {
        config.manager_connection_profile = "native_v3";
    }
    if (config.manager_client_intent.empty()) {
        config.manager_client_intent = "native_v3";
    }
    applyDriverDefaultsFromEnv(config);
}

void applyDriverDefaultsFromEnv(NetworkClientConfig& config) {
    auto getEnv = [](const char* key) -> const char* {
        return std::getenv(key);
    };
    auto parseU32 = [](const char* value, uint32_t& out) -> bool {
        if (!value) {
            return false;
        }
        char* end = nullptr;
        unsigned long parsed = std::strtoul(value, &end, 10);
        if (!end || *end != '\0') {
            return false;
        }
        out = static_cast<uint32_t>(parsed);
        return true;
    };
    auto parseU16 = [&](const char* value, uint16_t& out) -> bool {
        uint32_t tmp = 0;
        if (!parseU32(value, tmp) || tmp > 65535u) {
            return false;
        }
        out = static_cast<uint16_t>(tmp);
        return true;
    };

    if (const char* host = getEnv("SCRATCHBIRD_HOST")) {
        config.host = host;
    }
    if (const char* port = getEnv("SCRATCHBIRD_PORT")) {
        parseU16(port, config.port);
    }
    if (const char* db = getEnv("SCRATCHBIRD_DB")) {
        config.database = db;
    }
    if (const char* user = getEnv("SCRATCHBIRD_USER")) {
        config.username = user;
    }
    if (const char* pass = getEnv("SCRATCHBIRD_PASSWORD")) {
        config.password = pass;
    }
    if (const char* protocol = getEnv("SCRATCHBIRD_PROTOCOL")) {
        std::string normalized;
        if (parseProtocol(protocol, normalized)) {
            config.protocol = normalized;
        } else {
            config.protocol = "native";
        }
    }
    if (const char* parser = getEnv("SCRATCHBIRD_PARSER")) {
        std::string normalized;
        if (parseProtocol(parser, normalized)) {
            config.protocol = normalized;
        } else {
            config.protocol = "native";
        }
    }
    if (const char* role = getEnv("SCRATCHBIRD_ROLE")) {
        config.role = role;
    }
    if (const char* front_door_mode = getEnv("SCRATCHBIRD_FRONT_DOOR_MODE")) {
        std::string normalized;
        if (parseFrontDoorMode(front_door_mode, normalized)) {
            config.front_door_mode = normalized;
        }
    }
    if (const char* manager_token = getEnv("SCRATCHBIRD_MANAGER_AUTH_TOKEN")) {
        config.manager_auth_token = manager_token;
    }
    if (const char* manager_user = getEnv("SCRATCHBIRD_MANAGER_USERNAME")) {
        config.manager_username = manager_user;
    }
    if (const char* manager_db = getEnv("SCRATCHBIRD_MANAGER_DATABASE")) {
        config.manager_database = manager_db;
    }
    if (const char* manager_profile = getEnv("SCRATCHBIRD_MANAGER_CONNECTION_PROFILE")) {
        config.manager_connection_profile = manager_profile;
    }
    if (const char* manager_intent = getEnv("SCRATCHBIRD_MANAGER_CLIENT_INTENT")) {
        config.manager_client_intent = manager_intent;
    }
    if (const char* manager_flags = getEnv("SCRATCHBIRD_MANAGER_CLIENT_FLAGS")) {
        uint32_t parsed = 0;
        if (parseU32(manager_flags, parsed) && parsed <= 65535u) {
            config.manager_client_flags = static_cast<uint16_t>(parsed);
        }
    }
    if (const char* manager_fast_path = getEnv("SCRATCHBIRD_MANAGER_AUTH_FAST_PATH")) {
        config.manager_auth_fast_path = (std::string(manager_fast_path) == "1" ||
                                         std::string(manager_fast_path) == "true" ||
                                         std::string(manager_fast_path) == "TRUE");
    }
    if (const char* schema = getEnv("SCRATCHBIRD_SCHEMA")) {
        config.schema = schema;
    }
    if (const char* app = getEnv("SCRATCHBIRD_APP_NAME")) {
        config.application_name = app;
    }
    if (const char* sslmode = getEnv("SCRATCHBIRD_SSLMODE")) {
        config.ssl_mode = parseSslMode(sslmode);
    }
    if (const char* ssl_cert = getEnv("SCRATCHBIRD_SSL_CERT")) {
        config.ssl_cert = ssl_cert;
    }
    if (const char* ssl_key = getEnv("SCRATCHBIRD_SSL_KEY")) {
        config.ssl_key = ssl_key;
    }
    if (const char* ssl_root = getEnv("SCRATCHBIRD_SSL_ROOT_CERT")) {
        config.ssl_root_cert = ssl_root;
    }
    if (const char* auth = getEnv("SCRATCHBIRD_AUTH_METHOD")) {
        bool ok = false;
        auto method = parseAuthMethod(auth, &ok);
        if (ok) {
            config.auth_method = method;
        }
    }
    if (const char* allow_pw = getEnv("SCRATCHBIRD_ALLOW_PASSWORD_FALLBACK")) {
        config.allow_password_fallback = (std::string(allow_pw) == "1" ||
                                          std::string(allow_pw) == "true" ||
                                          std::string(allow_pw) == "TRUE");
    }
    if (const char* compression = getEnv("SCRATCHBIRD_ENABLE_COMPRESSION")) {
        config.enable_compression = (std::string(compression) == "1" ||
                                     std::string(compression) == "true" ||
                                     std::string(compression) == "TRUE");
    }
    if (const char* connect_to = getEnv("SCRATCHBIRD_CONNECT_TIMEOUT_MS")) {
        parseU32(connect_to, config.connect_timeout_ms);
    }
    if (const char* read_to = getEnv("SCRATCHBIRD_READ_TIMEOUT_MS")) {
        parseU32(read_to, config.read_timeout_ms);
    }
    if (const char* write_to = getEnv("SCRATCHBIRD_WRITE_TIMEOUT_MS")) {
        parseU32(write_to, config.write_timeout_ms);
    }
    if (const char* copy_window = getEnv("SCRATCHBIRD_COPY_WINDOW_BYTES")) {
        parseU32(copy_window, config.copy_window_bytes);
    }
    if (const char* copy_chunk = getEnv("SCRATCHBIRD_COPY_CHUNK_BYTES")) {
        parseU32(copy_chunk, config.copy_chunk_bytes);
    }
}

} // namespace client
} // namespace scratchbird
