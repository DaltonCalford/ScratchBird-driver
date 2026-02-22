#include <gtest/gtest.h>

#include <cstdlib>
#include <string>

#include "scratchbird/client/driver_config.h"
#include "scratchbird/client/network_client.h"

namespace {

class EnvGuard {
public:
    EnvGuard(const char* name, const std::string& value)
        : name_(name) {
        const char* existing = std::getenv(name);
        if (existing) {
            had_value_ = true;
            old_value_ = existing;
        }
#if defined(_WIN32)
        _putenv_s(name, value.c_str());
#else
        setenv(name, value.c_str(), 1);
#endif
    }

    EnvGuard(const char* name)
        : name_(name) {
        const char* existing = std::getenv(name);
        if (existing) {
            had_value_ = true;
            old_value_ = existing;
        }
#if defined(_WIN32)
        _putenv_s(name, "");
#else
        unsetenv(name);
#endif
    }

    ~EnvGuard() {
#if defined(_WIN32)
        if (had_value_) {
            _putenv_s(name_.c_str(), old_value_.c_str());
        } else {
            _putenv_s(name_.c_str(), "");
        }
#else
        if (had_value_) {
            setenv(name_.c_str(), old_value_.c_str(), 1);
        } else {
            unsetenv(name_.c_str());
        }
#endif
    }

private:
    std::string name_;
    bool had_value_ = false;
    std::string old_value_;
};

} // namespace

TEST(DriverDefaultsEnvTest, AppliesDefaultsWhenUnset) {
    EnvGuard host("SCRATCHBIRD_DRIVER_HOST", "db.example.test");
    EnvGuard port("SCRATCHBIRD_DRIVER_PORT", "4123");
    EnvGuard sslmode("SCRATCHBIRD_DRIVER_SSLMODE", "verify_full");
    EnvGuard timeout("SCRATCHBIRD_DRIVER_CONNECT_TIMEOUT_MS", "12000");
    EnvGuard database("SCRATCHBIRD_DRIVER_DATABASE", "alpha");
    EnvGuard app("SCRATCHBIRD_DRIVER_APPLICATION_NAME", "scratchbird_test");
    EnvGuard cert("SCRATCHBIRD_DRIVER_SSL_CERT", "/tmp/client.crt");
    EnvGuard key("SCRATCHBIRD_DRIVER_SSL_KEY", "/tmp/client.key");
    EnvGuard root("SCRATCHBIRD_DRIVER_SSL_ROOT_CERT", "/tmp/ca.pem");

    scratchbird::client::NetworkClientConfig cfg;
    cfg.host = "127.0.0.1";
    cfg.port = scratchbird::network::DEFAULT_NATIVE_PORT;
    cfg.application_name = "scratchbird_odbc";

    scratchbird::client::applyDriverDefaultsFromEnv(cfg);

    EXPECT_EQ(cfg.host, "db.example.test");
    EXPECT_EQ(cfg.port, 4123);
    EXPECT_EQ(cfg.ssl_mode, scratchbird::network::SSLMode::VERIFY_FULL);
    EXPECT_EQ(cfg.connect_timeout_ms, 12000u);
    EXPECT_EQ(cfg.database, "alpha");
    EXPECT_EQ(cfg.application_name, "scratchbird_test");
    EXPECT_EQ(cfg.ssl_cert, "/tmp/client.crt");
    EXPECT_EQ(cfg.ssl_key, "/tmp/client.key");
    EXPECT_EQ(cfg.ssl_root_cert, "/tmp/ca.pem");
}

TEST(DriverDefaultsEnvTest, DoesNotOverrideExplicitConfig) {
    EnvGuard host("SCRATCHBIRD_DRIVER_HOST", "env.example.test");
    EnvGuard port("SCRATCHBIRD_DRIVER_PORT", "5000");
    EnvGuard app("SCRATCHBIRD_DRIVER_APPLICATION_NAME", "env_app");

    scratchbird::client::NetworkClientConfig cfg;
    cfg.host = "override.host";
    cfg.port = 4100;
    cfg.application_name = "override_app";

    scratchbird::client::applyDriverDefaultsFromEnv(cfg);

    EXPECT_EQ(cfg.host, "override.host");
    EXPECT_EQ(cfg.port, 4100);
    EXPECT_EQ(cfg.application_name, "override_app");
}

TEST(DriverDefaultsEnvTest, ParsesManagerProxyConnectionParams) {
    scratchbird::client::NetworkClientConfig cfg;
    scratchbird::core::ErrorContext ctx;
    auto status = scratchbird::client::parseDriverConnectionString(
        "scratchbird://admin:pw@127.0.0.1:3090/main?"
        "front_door_mode=manager_proxy&manager_auth_token=abc123&"
        "manager_username=admin&manager_database=main&"
        "manager_connection_profile=native_v3&manager_client_intent=native_v3&"
        "manager_client_flags=7&manager_auth_fast_path=false",
        cfg,
        &ctx);
    ASSERT_EQ(status, scratchbird::core::Status::OK) << ctx.message;
    EXPECT_EQ(cfg.front_door_mode, "manager_proxy");
    EXPECT_EQ(cfg.manager_auth_token, "abc123");
    EXPECT_EQ(cfg.manager_username, "admin");
    EXPECT_EQ(cfg.manager_database, "main");
    EXPECT_EQ(cfg.manager_connection_profile, "native_v3");
    EXPECT_EQ(cfg.manager_client_intent, "native_v3");
    EXPECT_EQ(cfg.manager_client_flags, 7);
    EXPECT_FALSE(cfg.manager_auth_fast_path);
}
