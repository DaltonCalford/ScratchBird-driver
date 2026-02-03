#include <gtest/gtest.h>

#include <string>
#include <thread>
#include <vector>

#include "scratchbird/client/network_client.h"
#include "scratchbird/core/error_context.h"
#include "scratchbird/core/status.h"
#include "scratchbird/network/network.h"
#include "scratchbird/network/socket.h"
#include "scratchbird/protocol/sbwp_protocol.h"

namespace {

struct ServerHarness {
    std::unique_ptr<scratchbird::network::Socket> listener;
    uint16_t port = 0;
    std::thread thread;
    std::string error;

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

        uint8_t header_buf[scratchbird::protocol::kHeaderSize];
        auto status = client->readExact(header_buf, sizeof(header_buf), &ctx);
        if (status != scratchbird::core::Status::OK) {
            error = "read header failed: " + ctx.message;
            return;
        }

        scratchbird::protocol::MessageHeader header;
        std::vector<uint8_t> header_bytes(header_buf, header_buf + sizeof(header_buf));
        status = scratchbird::protocol::decodeHeader(header_bytes, header, &ctx);
        if (status != scratchbird::core::Status::OK) {
            error = "parse header failed: " + ctx.message;
            return;
        }

        if (header.type != scratchbird::protocol::MessageType::Startup) {
            error = "unexpected message type";
            return;
        }

        if (header.length > 0) {
            std::vector<uint8_t> payload(header.length);
            status = client->readExact(payload.data(), payload.size(), &ctx);
            if (status != scratchbird::core::Status::OK) {
                error = "read payload failed: " + ctx.message;
                return;
            }
        }

        std::vector<uint8_t> auth_req_payload(4, 0);
        auth_req_payload[0] = static_cast<uint8_t>(scratchbird::protocol::AuthMethod::Ok);
        scratchbird::protocol::MessageHeader auth_req;
        auth_req.type = scratchbird::protocol::MessageType::AuthRequest;
        auth_req.flags = 0;
        auth_req.length = static_cast<uint32_t>(auth_req_payload.size());
        auth_req.sequence = 1;
        std::vector<uint8_t> auth_req_msg = scratchbird::protocol::encodeMessage(auth_req, auth_req_payload);

        std::vector<uint8_t> auth_ok_payload(20, 0);
        auth_ok_payload[0] = 0x42;
        scratchbird::protocol::MessageHeader auth_ok;
        auth_ok.type = scratchbird::protocol::MessageType::AuthOk;
        auth_ok.flags = 0;
        auth_ok.length = static_cast<uint32_t>(auth_ok_payload.size());
        auth_ok.sequence = 2;
        std::vector<uint8_t> auth_ok_msg = scratchbird::protocol::encodeMessage(auth_ok, auth_ok_payload);

        std::vector<uint8_t> ready_payload(20, 0);
        scratchbird::protocol::MessageHeader ready;
        ready.type = scratchbird::protocol::MessageType::Ready;
        ready.flags = 0;
        ready.length = static_cast<uint32_t>(ready_payload.size());
        ready.sequence = 3;
        std::vector<uint8_t> ready_msg = scratchbird::protocol::encodeMessage(ready, ready_payload);

        std::vector<uint8_t> out;
        out.reserve(auth_req_msg.size() + auth_ok_msg.size() + ready_msg.size());
        out.insert(out.end(), auth_req_msg.begin(), auth_req_msg.end());
        out.insert(out.end(), auth_ok_msg.begin(), auth_ok_msg.end());
        out.insert(out.end(), ready_msg.begin(), ready_msg.end());

        status = client->writeExact(out.data(), out.size(), &ctx);
        if (status != scratchbird::core::Status::OK) {
            error = "write response failed: " + ctx.message;
            return;
        }
    }
};

} // namespace

TEST(DriverConnectivitySmokeTest, ConnectsToLocalListener) {
    GTEST_SKIP() << "SBWP v1.1 TLS handshake harness pending";
    scratchbird::network::NetworkInitGuard guard;
    ASSERT_TRUE(guard.isInitialized());

    ServerHarness harness;
    harness.listener = scratchbird::network::Socket::create(
        scratchbird::network::AddressFamily::IPV4
    );
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

    status = client.connect(cfg, &ctx);
    EXPECT_EQ(status, scratchbird::core::Status::OK) << ctx.message;
    client.disconnect();

    harness.stop();
    EXPECT_TRUE(harness.error.empty()) << harness.error;
}
