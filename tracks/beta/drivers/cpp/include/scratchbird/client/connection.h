#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "scratchbird/core/error_context.h"
#include "scratchbird/core/status.h"

namespace scratchbird {
namespace client {

struct ConnectionConfig {
    std::string database_name;
    std::string username;
    std::string password;
    std::string protocol{"native"};

    // inet_listener | managed
    std::string transport_mode{"inet_listener"};
    std::string host{"127.0.0.1"};
    uint16_t tcp_port{3092};
    std::string front_door_mode{"direct"};

    std::string manager_auth_token;
    std::string manager_username;
    std::string manager_database;
    std::string manager_connection_profile{"native_v3"};
    std::string manager_client_intent{"native_v3"};
    uint16_t manager_client_flags{0};
    bool manager_auth_fast_path{true};

    uint16_t connect_client_flags{0x0100};
    std::string auth_method_id;
    std::string auth_method_payload;
    std::string auth_payload_json;
    std::string auth_payload_b64;
    std::string auth_provider_profile;
    std::vector<std::string> auth_required_methods;
    std::vector<std::string> auth_forbidden_methods;
    bool auth_require_channel_binding{false};
    std::string workload_identity_token;
    std::string proxy_principal_assertion;

    uint32_t connect_timeout_ms{5000};
    uint32_t query_timeout_ms{30000};
    uint32_t read_timeout_ms{30000};
    uint32_t write_timeout_ms{30000};
    uint32_t copy_window_bytes{65536};
    uint32_t copy_chunk_bytes{16384};

    bool auto_commit{true};

    ConnectionConfig() = default;
    explicit ConnectionConfig(const std::string& db_name,
                              const std::string& user = "",
                              const std::string& pass = "")
        : database_name(db_name), username(user), password(pass) {}
};

struct ColumnMeta {
    std::string name;
    uint32_t type_oid{0};
    int32_t type_modifier{0};
    size_t index{0};
};

class ResultSetImpl;

class ResultSet {
public:
    ResultSet();
    ~ResultSet();

    ResultSet(ResultSet&& other) noexcept;
    ResultSet& operator=(ResultSet&& other) noexcept;
    ResultSet(const ResultSet&) = delete;
    ResultSet& operator=(const ResultSet&) = delete;

    size_t getColumnCount() const;
    std::string getColumnName(size_t index) const;
    int getColumnIndex(const std::string& name) const;
    const std::vector<ColumnMeta>& getColumns() const;
    int64_t getRowCount() const;
    int64_t getRowsAffected() const;
    bool isEmpty() const;
    const std::string& getCommandTag() const;

    bool next();
    void reset();
    int64_t getCurrentRow() const;

    bool isNull(size_t column) const;
    bool getBool(size_t column) const;
    int16_t getInt16(size_t column) const;
    int32_t getInt32(size_t column) const;
    int64_t getInt64(size_t column) const;
    float getFloat(size_t column) const;
    double getDouble(size_t column) const;
    std::string getString(size_t column) const;
    std::vector<uint8_t> getBytes(size_t column) const;
    int64_t getTimestamp(size_t column) const;
    int32_t getDate(size_t column) const;
    int64_t getTime(size_t column) const;
    std::string getUUID(size_t column) const;
    const uint8_t* getRaw(size_t column, size_t* length) const;

    bool isNull(const std::string& column) const;
    bool getBool(const std::string& column) const;
    int16_t getInt16(const std::string& column) const;
    int32_t getInt32(const std::string& column) const;
    int64_t getInt64(const std::string& column) const;
    float getFloat(const std::string& column) const;
    double getDouble(const std::string& column) const;
    std::string getString(const std::string& column) const;
    std::vector<uint8_t> getBytes(const std::string& column) const;
    int64_t getTimestamp(const std::string& column) const;
    int32_t getDate(const std::string& column) const;
    int64_t getTime(const std::string& column) const;
    std::string getUUID(const std::string& column) const;

private:
    friend class Connection;
    std::unique_ptr<ResultSetImpl> impl_;
};

enum class ConnectionState : uint8_t {
    DISCONNECTED = 0,
    CONNECTING = 1,
    CONNECTED = 2,
    IN_TRANSACTION = 3,
    ERROR_STATE = 4
};

class ConnectionImpl;

class Connection {
public:
    Connection();
    ~Connection();

    Connection(Connection&& other) noexcept;
    Connection& operator=(Connection&& other) noexcept;
    Connection(const Connection&) = delete;
    Connection& operator=(const Connection&) = delete;

    core::Status connect(const std::string& database,
                         const std::string& username = "",
                         const std::string& password = "",
                         core::ErrorContext* ctx = nullptr);
    core::Status connect(const ConnectionConfig& config,
                         core::ErrorContext* ctx = nullptr);
    void disconnect();
    bool isConnected() const;
    ConnectionState getState() const;
    std::string getLastError() const;

    core::Status executeQuery(const std::string& sql,
                              ResultSet* results,
                              core::ErrorContext* ctx = nullptr);
    core::Status executeQuery(const std::string& sql,
                              ResultSet* results,
                              uint8_t flags,
                              core::ErrorContext* ctx = nullptr);
    core::Status execute(const std::string& sql,
                         int64_t* rows_affected = nullptr,
                         core::ErrorContext* ctx = nullptr);

    core::Status beginTransaction(core::ErrorContext* ctx = nullptr);
    core::Status commit(core::ErrorContext* ctx = nullptr);
    core::Status rollback(core::ErrorContext* ctx = nullptr);
    core::Status savepoint(const std::string& name,
                           core::ErrorContext* ctx = nullptr);
    core::Status releaseSavepoint(const std::string& name,
                                  core::ErrorContext* ctx = nullptr);
    core::Status rollbackTo(const std::string& name,
                            core::ErrorContext* ctx = nullptr);

    void setAutoCommit(bool enabled);
    bool getAutoCommit() const;
    bool inTransaction() const;
    const ConnectionConfig& getConfig() const;

private:
    std::unique_ptr<ConnectionImpl> impl_;
};

} // namespace client
} // namespace scratchbird
