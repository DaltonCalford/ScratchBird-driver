#include <gtest/gtest.h>

#include <array>
#include <cstdint>
#include <cstring>
#include <functional>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include "scratchbird/client/network_client.h"
#include "scratchbird/core/error_context.h"
#include "scratchbird/core/status.h"
#include "scratchbird/network/network.h"
#include "scratchbird/network/socket.h"
#include "scratchbird/protocol/sbwp_protocol.h"
#include "scratchbird/server/ipc_server.h"

namespace {

uint64_t readU64Le(const uint8_t* data) {
    uint64_t value = 0;
    for (size_t i = 0; i < 8; ++i) {
        value |= static_cast<uint64_t>(data[i]) << (8 * i);
    }
    return value;
}

void writeU16Le(std::vector<uint8_t>& payload, size_t offset, uint16_t value) {
    payload[offset] = static_cast<uint8_t>(value & 0xFF);
    payload[offset + 1] = static_cast<uint8_t>((value >> 8) & 0xFF);
}

void writeU64Le(std::vector<uint8_t>& payload, size_t offset, uint64_t value) {
    for (size_t i = 0; i < 8; ++i) {
        payload[offset + i] = static_cast<uint8_t>((value >> (8 * i)) & 0xFF);
    }
}

bool parseStartupPayload(const std::vector<uint8_t>& payload,
                         uint64_t& features_out,
                         std::unordered_map<std::string, std::string>& params_out,
                         std::string& error_out) {
    if (payload.size() < 12) {
        error_out = "startup payload truncated";
        return false;
    }

    features_out = readU64Le(payload.data() + 4);
    params_out.clear();

    size_t offset = 12;
    while (offset < payload.size()) {
        size_t key_end = offset;
        while (key_end < payload.size() && payload[key_end] != 0) {
            ++key_end;
        }
        if (key_end >= payload.size()) {
            error_out = "startup payload missing key terminator";
            return false;
        }
        if (key_end == offset) {
            return true;
        }

        std::string key(reinterpret_cast<const char*>(payload.data() + offset), key_end - offset);
        offset = key_end + 1;

        size_t value_end = offset;
        while (value_end < payload.size() && payload[value_end] != 0) {
            ++value_end;
        }
        if (value_end >= payload.size()) {
            error_out = "startup payload missing value terminator";
            return false;
        }

        std::string value(reinterpret_cast<const char*>(payload.data() + offset), value_end - offset);
        params_out[key] = value;
        offset = value_end + 1;
    }

    error_out = "startup payload missing final terminator";
    return false;
}

scratchbird::core::Status readMessage(scratchbird::network::Socket* socket,
                                      scratchbird::protocol::ProtocolMessage& msg,
                                      scratchbird::core::ErrorContext* ctx) {
    if (!socket) {
        if (ctx) {
            ctx->message = "socket not set";
        }
        return scratchbird::core::Status::INVALID_ARGUMENT;
    }
    std::array<uint8_t, scratchbird::protocol::kHeaderSize> header_buf{};
    auto status = socket->readExact(header_buf.data(), header_buf.size(), ctx);
    if (status != scratchbird::core::Status::OK) {
        return status;
    }

    std::vector<uint8_t> header_bytes(header_buf.begin(), header_buf.end());
    status = scratchbird::protocol::decodeHeader(header_bytes, msg.header, ctx);
    if (status != scratchbird::core::Status::OK) {
        return status;
    }

    msg.body.clear();
    if (msg.header.length > 0) {
        msg.body.resize(msg.header.length);
        status = socket->readExact(msg.body.data(), msg.body.size(), ctx);
        if (status != scratchbird::core::Status::OK) {
            return status;
        }
    }

    return scratchbird::core::Status::OK;
}

scratchbird::core::Status sendMessage(scratchbird::network::Socket* socket,
                                      scratchbird::protocol::MessageType type,
                                      const std::vector<uint8_t>& payload,
                                      uint32_t sequence,
                                      scratchbird::core::ErrorContext* ctx) {
    if (!socket) {
        if (ctx) {
            ctx->message = "socket not set";
        }
        return scratchbird::core::Status::INVALID_ARGUMENT;
    }

    scratchbird::protocol::MessageHeader header;
    header.type = type;
    header.flags = 0;
    header.length = static_cast<uint32_t>(payload.size());
    header.sequence = sequence;
    auto encoded = scratchbird::protocol::encodeMessage(header, payload);
    return socket->writeExact(encoded.data(), encoded.size(), ctx);
}

std::vector<uint8_t> buildAuthRequestPayload(scratchbird::protocol::AuthMethod method) {
    std::vector<uint8_t> payload(4, 0);
    payload[0] = static_cast<uint8_t>(method);
    return payload;
}

std::vector<uint8_t> buildAuthOkPayload() {
    std::vector<uint8_t> payload(20, 0);
    payload[0] = 0x42;
    return payload;
}

std::vector<uint8_t> buildReadyPayload(uint8_t status = 0,
                                       uint64_t txn_id = 0,
                                       uint64_t epoch = 0) {
    std::vector<uint8_t> payload(20, 0);
    payload[0] = status;
    writeU64Le(payload, 4, txn_id);
    writeU64Le(payload, 12, epoch);
    return payload;
}

std::vector<uint8_t> buildCommandCompletePayload(uint8_t command_type,
                                                 uint64_t rows,
                                                 uint64_t last_id,
                                                 const std::string& tag) {
    std::vector<uint8_t> payload(20 + tag.size() + 1, 0);
    payload[0] = command_type;
    writeU64Le(payload, 4, rows);
    writeU64Le(payload, 12, last_id);
    std::memcpy(payload.data() + 20, tag.data(), tag.size());
    return payload;
}

std::vector<uint8_t> buildParameterDescriptionPayload(const std::vector<uint32_t>& type_oids) {
    std::vector<uint8_t> payload(4 + type_oids.size() * 4, 0);
    writeU16Le(payload, 0, static_cast<uint16_t>(type_oids.size()));
    size_t offset = 4;
    for (uint32_t oid : type_oids) {
        payload[offset + 0] = static_cast<uint8_t>(oid & 0xFF);
        payload[offset + 1] = static_cast<uint8_t>((oid >> 8) & 0xFF);
        payload[offset + 2] = static_cast<uint8_t>((oid >> 16) & 0xFF);
        payload[offset + 3] = static_cast<uint8_t>((oid >> 24) & 0xFF);
        offset += 4;
    }
    return payload;
}

void appendErrorField(std::vector<uint8_t>& payload, uint8_t field, const std::string& value) {
    payload.push_back(field);
    payload.insert(payload.end(), value.begin(), value.end());
    payload.push_back(0);
}

std::vector<uint8_t> buildErrorPayload(const std::string& severity,
                                       const std::string& sqlstate,
                                       const std::string& message,
                                       const std::string& detail = std::string(),
                                       const std::string& hint = std::string()) {
    std::vector<uint8_t> payload;
    appendErrorField(payload, 'S', severity);
    appendErrorField(payload, 'C', sqlstate);
    appendErrorField(payload, 'M', message);
    if (!detail.empty()) {
        appendErrorField(payload, 'D', detail);
    }
    if (!hint.empty()) {
        appendErrorField(payload, 'H', hint);
    }
    payload.push_back(0);
    return payload;
}

bool parseQueryPayloadSql(const std::vector<uint8_t>& payload,
                          std::string& sql_out,
                          std::string& error_out) {
    if (payload.size() < 13) {
        error_out = "query payload truncated";
        return false;
    }
    size_t end = 12;
    while (end < payload.size() && payload[end] != 0) {
        ++end;
    }
    if (end >= payload.size()) {
        error_out = "query payload missing terminator";
        return false;
    }
    sql_out.assign(reinterpret_cast<const char*>(payload.data() + 12), end - 12);
    return true;
}

struct ScriptedResponse {
    scratchbird::protocol::MessageType type;
    std::vector<uint8_t> payload;
};

struct ScriptedExchange {
    scratchbird::protocol::MessageType request_type;
    std::vector<ScriptedResponse> responses;
    std::function<bool(const scratchbird::protocol::ProtocolMessage&, std::string&)> validate;
};

struct ServerHarnessConfig {
    scratchbird::protocol::AuthMethod auth_method{scratchbird::protocol::AuthMethod::Ok};
    std::string expected_auth_response;
    std::vector<ScriptedExchange> exchanges;
    bool drain_after_script{false};
};

struct ServerHarness {
    explicit ServerHarness(ServerHarnessConfig cfg = {}) : config(std::move(cfg)) {}
    ~ServerHarness() {
        stop();
    }

    ServerHarnessConfig config;
    std::unique_ptr<scratchbird::network::Socket> listener;
    uint16_t port = 0;
    std::thread thread;
    std::string error;
    uint64_t startup_features = 0;
    std::unordered_map<std::string, std::string> startup_params;
    bool saw_auth_response = false;

    void start() {
        thread = std::thread([this]() { run(); });
    }

    void stop() {
        if (listener) {
            listener->close();
        }
        if (thread.joinable()) {
            thread.join();
        }
    }

private:
    void run() {
        scratchbird::core::ErrorContext ctx;
        scratchbird::network::NetworkAddress client_addr;
        auto client = listener->accept(&client_addr, &ctx);
        if (!client) {
            error = "accept failed: " + ctx.message;
            return;
        }

        scratchbird::protocol::ProtocolMessage startup;
        auto status = readMessage(client.get(), startup, &ctx);
        if (status != scratchbird::core::Status::OK) {
            error = "read startup failed: " + ctx.message;
            return;
        }
        if (startup.header.type != scratchbird::protocol::MessageType::Startup) {
            error = "unexpected message type";
            return;
        }

        if (!parseStartupPayload(startup.body, startup_features, startup_params, error)) {
            return;
        }

        status = sendMessage(client.get(),
                             scratchbird::protocol::MessageType::AuthRequest,
                             buildAuthRequestPayload(config.auth_method),
                             1,
                             &ctx);
        if (status != scratchbird::core::Status::OK) {
            error = "write auth request failed: " + ctx.message;
            return;
        }

        if (config.auth_method == scratchbird::protocol::AuthMethod::Password) {
            scratchbird::protocol::ProtocolMessage auth_response;
            status = readMessage(client.get(), auth_response, &ctx);
            if (status != scratchbird::core::Status::OK) {
                error = "read auth response failed: " + ctx.message;
                return;
            }
            if (auth_response.header.type != scratchbird::protocol::MessageType::AuthResponse) {
                error = "expected auth response";
                return;
            }
            saw_auth_response = true;
            std::vector<uint8_t> expected(config.expected_auth_response.begin(),
                                          config.expected_auth_response.end());
            if (auth_response.body != expected) {
                error = "auth response payload mismatch";
                return;
            }
        }

        status = sendMessage(client.get(),
                             scratchbird::protocol::MessageType::AuthOk,
                             buildAuthOkPayload(),
                             2,
                             &ctx);
        if (status != scratchbird::core::Status::OK) {
            error = "write auth ok failed: " + ctx.message;
            return;
        }

        status = sendMessage(client.get(),
                             scratchbird::protocol::MessageType::Ready,
                             buildReadyPayload(),
                             3,
                             &ctx);
        if (status != scratchbird::core::Status::OK) {
            error = "write ready failed: " + ctx.message;
            return;
        }

        uint32_t next_sequence = 4;
        for (const auto& exchange : config.exchanges) {
            scratchbird::protocol::ProtocolMessage request;
            status = readMessage(client.get(), request, &ctx);
            if (status != scratchbird::core::Status::OK) {
                error = "read scripted request failed: " + ctx.message;
                return;
            }
            if (request.header.type != exchange.request_type) {
                error = "unexpected request type in scripted exchange";
                return;
            }
            if (exchange.validate && !exchange.validate(request, error)) {
                return;
            }
            for (const auto& response : exchange.responses) {
                status = sendMessage(client.get(), response.type, response.payload, next_sequence++, &ctx);
                if (status != scratchbird::core::Status::OK) {
                    error = "write scripted response failed: " + ctx.message;
                    return;
                }
            }
        }

        if (!config.drain_after_script) {
            return;
        }
        while (true) {
            scratchbird::protocol::ProtocolMessage ignored;
            status = readMessage(client.get(), ignored, &ctx);
            if (status != scratchbird::core::Status::OK) {
                return;
            }
        }
    }
};

void setupIpv4Listener(ServerHarness& harness) {
    harness.listener = scratchbird::network::Socket::create(
        scratchbird::network::AddressFamily::IPV4);
    ASSERT_TRUE(harness.listener);

    scratchbird::network::NetworkAddress addr("127.0.0.1", 0);
    scratchbird::core::ErrorContext ctx;
    auto status = harness.listener->bind(addr, &ctx);
    ASSERT_EQ(status, scratchbird::core::Status::OK) << ctx.message;

    status = harness.listener->listen();
    ASSERT_EQ(status, scratchbird::core::Status::OK);

    auto local = harness.listener->getLocalAddress();
    ASSERT_TRUE(local.has_value());
    harness.port = local->port;
    ASSERT_GT(harness.port, 0u);
}

scratchbird::client::NetworkClientConfig makeLoopbackConfig(uint16_t port) {
    scratchbird::client::NetworkClientConfig cfg;
    cfg.host = "127.0.0.1";
    cfg.port = port;
    cfg.ssl_mode = scratchbird::network::SSLMode::DISABLED;
    cfg.connect_timeout_ms = 2000;
    cfg.read_timeout_ms = 2000;
    cfg.write_timeout_ms = 2000;
    cfg.database = "main";
    return cfg;
}

} // namespace

TEST(DriverConnectivitySmokeTest, ConnectsToLocalListener) {
    scratchbird::network::NetworkInitGuard guard;
    ASSERT_TRUE(guard.isInitialized());

    ServerHarness harness;
    setupIpv4Listener(harness);
    harness.start();

    scratchbird::client::NetworkClient client;
    scratchbird::client::NetworkClientConfig cfg;
    cfg.host = "127.0.0.1";
    cfg.port = harness.port;
    cfg.ssl_mode = scratchbird::network::SSLMode::DISABLED;
    cfg.connect_timeout_ms = 2000;
    cfg.read_timeout_ms = 2000;
    cfg.write_timeout_ms = 2000;
    cfg.database = "default";
    scratchbird::core::ErrorContext ctx;

    auto status = client.connect(cfg, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::OK) << ctx.message;
    client.disconnect();

    harness.stop();
    EXPECT_TRUE(harness.error.empty()) << harness.error;
}

TEST(DriverConnectivitySmokeTest, ConnectsWithPasswordAuthChallengeAndCarriesAuthParams) {
    scratchbird::network::NetworkInitGuard guard;
    ASSERT_TRUE(guard.isInitialized());

    ServerHarness harness(ServerHarnessConfig{
        scratchbird::protocol::AuthMethod::Password,
        "pw-secret"
    });
    setupIpv4Listener(harness);
    harness.start();

    scratchbird::client::NetworkClient client;
    scratchbird::client::NetworkClientConfig cfg;
    cfg.host = "127.0.0.1";
    cfg.port = harness.port;
    cfg.ssl_mode = scratchbird::network::SSLMode::DISABLED;
    cfg.connect_timeout_ms = 2000;
    cfg.read_timeout_ms = 2000;
    cfg.write_timeout_ms = 2000;
    cfg.database = "main";
    cfg.username = "alice";
    cfg.password = "pw-secret";
    cfg.auth_method_id = "scratchbird.auth.proxy_assertion";
    cfg.auth_payload_json = "{\"subject\":\"alice\"}";
    cfg.auth_provider_profile = "corp_primary";
    cfg.auth_require_channel_binding = true;

    scratchbird::core::ErrorContext ctx;
    auto status = client.connect(cfg, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::OK) << ctx.message;
    client.disconnect();

    harness.stop();
    EXPECT_TRUE(harness.error.empty()) << harness.error;
    EXPECT_TRUE(harness.saw_auth_response);
    EXPECT_EQ(harness.startup_params["database"], "main");
    EXPECT_EQ(harness.startup_params["user"], "alice");
    EXPECT_EQ(harness.startup_params["auth_method_id"], "scratchbird.auth.proxy_assertion");
    EXPECT_EQ(harness.startup_params["auth_payload_json"], "{\"subject\":\"alice\"}");
    EXPECT_EQ(harness.startup_params["auth_provider_profile"], "corp_primary");
    EXPECT_EQ(harness.startup_params["auth_require_channel_binding"], "1");
    EXPECT_NE(harness.startup_features & scratchbird::protocol::kFeatureSblr, 0ULL);
    EXPECT_NE(harness.startup_features & scratchbird::protocol::kFeatureNotifications, 0ULL);
    EXPECT_NE(harness.startup_features & scratchbird::protocol::kFeatureQueryPlan, 0ULL);
}

TEST(DriverConnectivitySmokeTest, ConnectsWithLocalIpcPipeFallback) {
    scratchbird::network::NetworkInitGuard guard;
    ASSERT_TRUE(guard.isInitialized());

    ServerHarness harness;
    setupIpv4Listener(harness);
    harness.start();

    scratchbird::client::NetworkClient client;
    scratchbird::client::NetworkClientConfig cfg;
    cfg.transport_mode = "local_ipc";
    cfg.ipc_method = scratchbird::server::IPCMethod::NAMED_PIPE;
    cfg.port = harness.port;
    cfg.ssl_mode = scratchbird::network::SSLMode::DISABLED;
    cfg.connect_timeout_ms = 2000;
    cfg.read_timeout_ms = 2000;
    cfg.write_timeout_ms = 2000;
    cfg.database = "main";

    scratchbird::core::ErrorContext ctx;
    auto status = client.connect(cfg, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::OK) << ctx.message;
    client.disconnect();

    harness.stop();
    EXPECT_TRUE(harness.error.empty()) << harness.error;
}

TEST(DriverConnectivitySmokeTest, RejectsInvalidAuthMethodIdBeforeDial) {
    scratchbird::client::NetworkClient client;
    scratchbird::client::NetworkClientConfig cfg;
    cfg.host = "203.0.113.15";
    cfg.port = 6553;
    cfg.ssl_mode = scratchbird::network::SSLMode::DISABLED;
    cfg.database = "main";
    cfg.auth_method_id = "custom.namespace.token";

    scratchbird::core::ErrorContext ctx;
    auto status = client.connect(cfg, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::INVALID_ARGUMENT);
    EXPECT_NE(ctx.message.find("auth_method_id"), std::string::npos);
}

TEST(DriverConnectivitySmokeTest, RejectsManagerProxyModeWithoutTokenBeforeDial) {
    scratchbird::client::NetworkClient client;
    scratchbird::client::NetworkClientConfig cfg;
    cfg.transport_mode = "managed";
    cfg.host = "203.0.113.15";
    cfg.port = 6553;
    cfg.ssl_mode = scratchbird::network::SSLMode::DISABLED;
    cfg.database = "main";

    scratchbird::core::ErrorContext ctx;
    auto status = client.connect(cfg, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::INVALID_ARGUMENT);
    EXPECT_NE(ctx.message.find("manager_auth_token"), std::string::npos);
}

TEST(DriverTxnExecParityTest, TransactionRoundTripBeginCommitRollback) {
    scratchbird::network::NetworkInitGuard guard;
    ASSERT_TRUE(guard.isInitialized());

    ServerHarnessConfig harness_cfg;
    harness_cfg.exchanges = {
        {scratchbird::protocol::MessageType::TxnBegin,
         {{scratchbird::protocol::MessageType::CommandComplete,
           buildCommandCompletePayload(0, 0, 0, "BEGIN")},
          {scratchbird::protocol::MessageType::Ready, buildReadyPayload(1, 42, 1)}},
         [](const scratchbird::protocol::ProtocolMessage& msg, std::string& error) {
             if (msg.body.size() != 12) {
                 error = "txn begin payload size mismatch";
                 return false;
             }
             return true;
         }},
        {scratchbird::protocol::MessageType::TxnCommit,
         {{scratchbird::protocol::MessageType::CommandComplete,
           buildCommandCompletePayload(0, 0, 0, "COMMIT")},
          {scratchbird::protocol::MessageType::Ready, buildReadyPayload(0, 0, 2)}},
         [](const scratchbird::protocol::ProtocolMessage& msg, std::string& error) {
             if (msg.body.size() != 4) {
                 error = "txn commit payload size mismatch";
                 return false;
             }
             return true;
         }},
        {scratchbird::protocol::MessageType::TxnBegin,
         {{scratchbird::protocol::MessageType::CommandComplete,
           buildCommandCompletePayload(0, 0, 0, "BEGIN")},
          {scratchbird::protocol::MessageType::Ready, buildReadyPayload(1, 43, 3)}}},
        {scratchbird::protocol::MessageType::TxnRollback,
         {{scratchbird::protocol::MessageType::CommandComplete,
           buildCommandCompletePayload(0, 0, 0, "ROLLBACK")},
          {scratchbird::protocol::MessageType::Ready, buildReadyPayload(0, 0, 4)}}}
    };

    ServerHarness harness(std::move(harness_cfg));
    setupIpv4Listener(harness);
    harness.start();

    scratchbird::client::NetworkClient client;
    auto cfg = makeLoopbackConfig(harness.port);
    scratchbird::core::ErrorContext ctx;
    ASSERT_EQ(client.connect(cfg, &ctx), scratchbird::core::Status::OK) << ctx.message;

    EXPECT_EQ(client.beginTransaction(&ctx), scratchbird::core::Status::OK) << ctx.message;
    EXPECT_EQ(client.commit(&ctx), scratchbird::core::Status::OK) << ctx.message;
    EXPECT_EQ(client.beginTransaction(&ctx), scratchbird::core::Status::OK) << ctx.message;
    EXPECT_EQ(client.rollback(&ctx), scratchbird::core::Status::OK) << ctx.message;
    client.disconnect();

    harness.stop();
    EXPECT_TRUE(harness.error.empty()) << harness.error;
}

TEST(DriverTxnExecParityTest, RollbackMapsNoActiveTransactionSqlState) {
    scratchbird::network::NetworkInitGuard guard;
    ASSERT_TRUE(guard.isInitialized());

    ServerHarnessConfig harness_cfg;
    harness_cfg.exchanges = {
        {scratchbird::protocol::MessageType::TxnRollback,
         {{scratchbird::protocol::MessageType::Error,
           buildErrorPayload("ERROR", "25P01", "no active transaction")}}}
    };

    ServerHarness harness(std::move(harness_cfg));
    setupIpv4Listener(harness);
    harness.start();

    scratchbird::client::NetworkClient client;
    auto cfg = makeLoopbackConfig(harness.port);
    scratchbird::core::ErrorContext ctx;
    ASSERT_EQ(client.connect(cfg, &ctx), scratchbird::core::Status::OK) << ctx.message;

    auto status = client.rollback(&ctx);
    EXPECT_EQ(status, scratchbird::core::Status::NO_ACTIVE_TRANSACTION);
    EXPECT_STREQ(ctx.sqlstate, "25P01");
    EXPECT_NE(ctx.message.find("no active transaction"), std::string::npos);
    client.disconnect();

    harness.stop();
    EXPECT_TRUE(harness.error.empty()) << harness.error;
}

TEST(DriverTxnExecParityTest, QueryClearsCancelSequenceAfterReady) {
    scratchbird::network::NetworkInitGuard guard;
    ASSERT_TRUE(guard.isInitialized());

    ServerHarnessConfig harness_cfg;
    harness_cfg.drain_after_script = true;
    harness_cfg.exchanges = {
        {scratchbird::protocol::MessageType::Query,
         {},
         [](const scratchbird::protocol::ProtocolMessage& msg, std::string& error) {
             std::string sql;
             if (!parseQueryPayloadSql(msg.body, sql, error)) {
                 return false;
             }
             if (sql != "UPDATE t SET v = 1") {
                 error = "unexpected query sql";
                 return false;
             }
             return true;
         }},
        {scratchbird::protocol::MessageType::Sync,
         {{scratchbird::protocol::MessageType::CommandComplete,
           buildCommandCompletePayload(0, 3, 0, "UPDATE 3")},
          {scratchbird::protocol::MessageType::Ready, buildReadyPayload(0, 0, 10)}}}
    };

    ServerHarness harness(std::move(harness_cfg));
    setupIpv4Listener(harness);
    harness.start();

    scratchbird::client::NetworkClient client;
    auto cfg = makeLoopbackConfig(harness.port);
    scratchbird::core::ErrorContext ctx;
    ASSERT_EQ(client.connect(cfg, &ctx), scratchbird::core::Status::OK) << ctx.message;

    scratchbird::client::NetworkResultSet results;
    auto status = client.executeQuery("UPDATE t SET v = 1", results, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::OK) << ctx.message;
    EXPECT_EQ(results.rows_affected, 3);
    EXPECT_EQ(results.command_tag, "UPDATE 3");

    scratchbird::core::ErrorContext cancel_ctx;
    auto cancel_status = client.sendQueryCancel(&cancel_ctx);
    EXPECT_EQ(cancel_status, scratchbird::core::Status::INVALID_ARGUMENT);
    EXPECT_NE(cancel_ctx.message.find("No in-flight query to cancel"), std::string::npos);
    client.disconnect();

    harness.stop();
    EXPECT_TRUE(harness.error.empty()) << harness.error;
}

TEST(DriverTxnExecParityTest, PrepareAndExecutePreparedRoundTrip) {
    scratchbird::network::NetworkInitGuard guard;
    ASSERT_TRUE(guard.isInitialized());

    ServerHarnessConfig harness_cfg;
    harness_cfg.exchanges = {
        {scratchbird::protocol::MessageType::Parse, {}},
        {scratchbird::protocol::MessageType::Describe, {}},
        {scratchbird::protocol::MessageType::Sync,
         {{scratchbird::protocol::MessageType::ParameterDescription,
           buildParameterDescriptionPayload({scratchbird::protocol::kOidInt4})},
          {scratchbird::protocol::MessageType::Ready, buildReadyPayload(0, 0, 20)}}},
        {scratchbird::protocol::MessageType::Bind, {}},
        {scratchbird::protocol::MessageType::Execute, {}},
        {scratchbird::protocol::MessageType::Sync,
         {{scratchbird::protocol::MessageType::CommandComplete,
           buildCommandCompletePayload(0, 1, 0, "UPDATE 1")},
          {scratchbird::protocol::MessageType::Ready, buildReadyPayload(0, 0, 21)}}}
    };

    ServerHarness harness(std::move(harness_cfg));
    setupIpv4Listener(harness);
    harness.start();

    scratchbird::client::NetworkClient client;
    auto cfg = makeLoopbackConfig(harness.port);
    scratchbird::core::ErrorContext ctx;
    ASSERT_EQ(client.connect(cfg, &ctx), scratchbird::core::Status::OK) << ctx.message;

    scratchbird::client::NetworkPreparedStatement stmt;
    auto status = client.prepare("UPDATE t SET v = $1", stmt, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::OK) << ctx.message;
    EXPECT_TRUE(stmt.isValid());
    EXPECT_EQ(stmt.getParameterCount(), 1u);
    stmt.setInt32(1, 7);

    scratchbird::client::NetworkResultSet results;
    status = client.executePrepared(stmt, results, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::OK) << ctx.message;
    EXPECT_EQ(results.rows_affected, 1);
    EXPECT_EQ(results.command_tag, "UPDATE 1");
    client.disconnect();

    harness.stop();
    EXPECT_TRUE(harness.error.empty()) << harness.error;
}
