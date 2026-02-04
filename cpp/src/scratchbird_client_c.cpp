#include "scratchbird/client/scratchbird_client.h"

#include <cctype>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#include "scratchbird/client/driver_config.h"
#include "scratchbird/core/error_context.h"
#include "scratchbird/core/status.h"
#include "scratchbird/core/type_extractor.h"
#include "scratchbird/protocol/sbwp_protocol.h"

struct sb_connection {
    scratchbird::client::NetworkClient client;
    scratchbird::client::NetworkClientConfig config;
};

struct sb_prepared {
    sb_connection* conn{nullptr};
    scratchbird::client::NetworkPreparedStatement stmt;
    std::vector<std::string> param_names;
};

struct sb_result {
    scratchbird::client::NetworkResultSet results;
    size_t row_index{0};
    std::vector<std::string> column_names;
};

namespace {

constexpr int32_t kDaysFrom1970To2000 = 10957;
constexpr int64_t kMicrosPerSecond = 1000000LL;
constexpr int64_t kMicrosPerDay = 86400LL * kMicrosPerSecond;
constexpr int64_t kMicrosFrom1970To2000 = kMicrosPerDay * kDaysFrom1970To2000;

void set_error(sb_error* err, sb_error_code code, const std::string& message) {
    if (!err) {
        return;
    }
    err->code = code;
    std::snprintf(err->message, sizeof(err->message), "%s", message.c_str());
}

sb_error_code map_status(scratchbird::core::Status status) {
    using scratchbird::core::Status;
    switch (status) {
        case Status::OK:
            return SB_OK;
        case Status::CONNECTION_FAILURE:
        case Status::CONNECTION_DOES_NOT_EXIST:
            return SB_ERR_CONNECTION_FAILED;
        case Status::INVALID_PASSWORD:
        case Status::INVALID_AUTHORIZATION:
            return SB_ERR_AUTH_FAILED;
        case Status::PROTOCOL_VIOLATION:
            return SB_ERR_PROTOCOL;
        case Status::SYNTAX_ERROR:
            return SB_ERR_SYNTAX;
        case Status::CONSTRAINT_VIOLATION:
            return SB_ERR_CONSTRAINT;
        case Status::TYPE_MISMATCH:
        case Status::DATATYPE_MISMATCH:
            return SB_ERR_TYPE_MISMATCH;
        case Status::DEADLOCK:
            return SB_ERR_DEADLOCK;
        case Status::SERIALIZATION_FAILURE:
            return SB_ERR_SERIALIZATION;
        case Status::TRANSACTION_ABORTED:
            return SB_ERR_TXN_ABORTED;
        case Status::NO_ACTIVE_TRANSACTION:
            return SB_ERR_NO_ACTIVE_TXN;
        case Status::LOCK_TIMEOUT:
            return SB_ERR_TIMEOUT;
        case Status::OOM:
            return SB_ERR_OUT_OF_MEMORY;
        case Status::DISK_FULL:
            return SB_ERR_DISK_FULL;
        case Status::TOO_MANY_CONNECTIONS:
            return SB_ERR_TOO_MANY_CONNECTIONS;
        case Status::INVALID_ARGUMENT:
            return SB_ERR_INVALID_PARAM;
        case Status::NOT_IMPLEMENTED:
        case Status::NOT_SUPPORTED:
            return SB_ERR_NOT_IMPLEMENTED;
        case Status::OBJECT_IN_USE:
            return SB_ERR_RESOURCE_BUSY;
        default:
            return SB_ERR_UNKNOWN;
    }
}

sb_type map_type_oid(uint32_t type_oid) {
    using namespace scratchbird::protocol;
    switch (type_oid) {
        case kOidBool:
            return SB_TYPE_BOOLEAN;
        case kOidInt2:
            return SB_TYPE_SMALLINT;
        case kOidInt4:
            return SB_TYPE_INTEGER;
        case kOidInt8:
            return SB_TYPE_BIGINT;
        case kOidFloat4:
            return SB_TYPE_REAL;
        case kOidFloat8:
            return SB_TYPE_DOUBLE;
        case kOidNumeric:
            return SB_TYPE_DECIMAL;
        case kOidJsonb:
            return SB_TYPE_JSONB;
        case kOidChar:
        case kOidBpChar:
            return SB_TYPE_CHAR;
        case kOidVarchar:
            return SB_TYPE_VARCHAR;
        case kOidText:
            return SB_TYPE_TEXT;
        case kOidXml:
            return SB_TYPE_XML;
        case kOidTsVector:
            return SB_TYPE_TSVECTOR;
        case kOidTsQuery:
            return SB_TYPE_TSQUERY;
        case kOidBytea:
            return SB_TYPE_BLOB;
        case kOidMoney:
            return SB_TYPE_MONEY;
        case kOidDate:
            return SB_TYPE_DATE;
        case kOidTime:
            return SB_TYPE_TIME;
        case kOidTimestamp:
            return SB_TYPE_TIMESTAMP;
        case kOidTimestamptz:
            return SB_TYPE_TIMESTAMP_TZ;
        case kOidInterval:
            return SB_TYPE_INTERVAL;
        case kOidUuid:
            return SB_TYPE_UUID;
        case kOidJson:
            return SB_TYPE_JSON;
        case kOidPoint:
        case kOidLseg:
        case kOidPath:
        case kOidBox:
        case kOidPolygon:
        case kOidLine:
        case kOidCircle:
            return SB_TYPE_GEOMETRY;
        case kOidInet:
            return SB_TYPE_INET;
        case kOidCidr:
            return SB_TYPE_CIDR;
        case kOidMacaddr:
        case kOidMacaddr8:
            return SB_TYPE_MACADDR;
        case kOidSbVector:
            return SB_TYPE_VECTOR;
        case kOidRecord:
            return SB_TYPE_COMPOSITE;
        case kOidInt4Range:
        case kOidInt8Range:
        case kOidNumRange:
        case kOidTsRange:
        case kOidTstzRange:
        case kOidDateRange:
            return SB_TYPE_RANGE;
        default:
            return SB_TYPE_UNKNOWN;
    }
}

uint32_t map_sb_type_to_oid(sb_type type) {
    using namespace scratchbird::protocol;
    switch (type) {
        case SB_TYPE_BOOLEAN:
            return kOidBool;
        case SB_TYPE_SMALLINT:
            return kOidInt2;
        case SB_TYPE_INTEGER:
            return kOidInt4;
        case SB_TYPE_BIGINT:
            return kOidInt8;
        case SB_TYPE_REAL:
            return kOidFloat4;
        case SB_TYPE_DOUBLE:
            return kOidFloat8;
        case SB_TYPE_DECIMAL:
            return kOidNumeric;
        case SB_TYPE_JSONB:
            return kOidJsonb;
        case SB_TYPE_CHAR:
            return kOidBpChar;
        case SB_TYPE_VARCHAR:
        case SB_TYPE_TEXT:
            return kOidText;
        case SB_TYPE_XML:
            return kOidXml;
        case SB_TYPE_TSVECTOR:
            return kOidTsVector;
        case SB_TYPE_TSQUERY:
            return kOidTsQuery;
        case SB_TYPE_BLOB:
            return kOidBytea;
        case SB_TYPE_MONEY:
            return kOidMoney;
        case SB_TYPE_DATE:
            return kOidDate;
        case SB_TYPE_TIME:
            return kOidTime;
        case SB_TYPE_TIMESTAMP:
            return kOidTimestamp;
        case SB_TYPE_TIMESTAMP_TZ:
            return kOidTimestamptz;
        case SB_TYPE_INTERVAL:
            return kOidInterval;
        case SB_TYPE_UUID:
            return kOidUuid;
        case SB_TYPE_JSON:
            return kOidJson;
        case SB_TYPE_GEOMETRY:
            return kOidPoint;
        case SB_TYPE_ARRAY:
            return 0;
        case SB_TYPE_COMPOSITE:
            return kOidRecord;
        case SB_TYPE_RANGE:
            return 0;
        case SB_TYPE_VECTOR:
            return kOidSbVector;
        case SB_TYPE_INET:
            return kOidInet;
        case SB_TYPE_CIDR:
            return kOidCidr;
        case SB_TYPE_MACADDR:
            return kOidMacaddr;
        default:
            return 0;
    }
}

uint32_t resolve_type_oid(const sb_value* value) {
    if (!value) {
        return 0;
    }
    if (value->type_oid != 0) {
        return value->type_oid;
    }
    return map_sb_type_to_oid(value->type);
}

void decode_date(int32_t days_since_2000, sb_value* value) {
    int64_t days_since_epoch = static_cast<int64_t>(days_since_2000) + kDaysFrom1970To2000;
    value->data.date_val.year = scratchbird::core::TypeExtractor::extractYear(days_since_epoch);
    value->data.date_val.month = scratchbird::core::TypeExtractor::extractMonth(days_since_epoch);
    value->data.date_val.day = scratchbird::core::TypeExtractor::extractDay(days_since_epoch);
}

void decode_time(int64_t micros, sb_value* value) {
    value->data.time_val.hour = scratchbird::core::TypeExtractor::extractHour(micros);
    value->data.time_val.minute = scratchbird::core::TypeExtractor::extractMinute(micros);
    value->data.time_val.second = scratchbird::core::TypeExtractor::extractSecond(micros);
    value->data.time_val.microsecond = scratchbird::core::TypeExtractor::extractMicrosecond(micros);
}

void decode_timestamp(int64_t micros, sb_value* value) {
    value->data.timestamp_val.epoch_microseconds = micros;
    value->data.timestamp_val.tz_offset_seconds = 0;
}

void parse_named_params(const std::string& sql, std::vector<std::string>& names) {
    names.clear();
    bool in_string = false;
    for (size_t i = 0; i + 1 < sql.size(); ++i) {
        char ch = sql[i];
        if (ch == '\'') {
            in_string = !in_string;
            continue;
        }
        if (in_string) {
            continue;
        }
        if ((ch == ':' || ch == '@') && std::isalpha(static_cast<unsigned char>(sql[i + 1]))) {
            size_t j = i + 1;
            while (j < sql.size() && (std::isalnum(static_cast<unsigned char>(sql[j])) || sql[j] == '_')) {
                ++j;
            }
            names.emplace_back(sql.substr(i + 1, j - i - 1));
            i = j;
        }
    }
}

int apply_bind_value(scratchbird::client::NetworkPreparedStatement& stmt, size_t index, const sb_value* value) {
    if (!value) {
        return SB_ERR_NULL_POINTER;
    }
    if (value->is_null) {
        stmt.setNull(index, resolve_type_oid(value));
        return SB_OK;
    }
    switch (value->type) {
        case SB_TYPE_BOOLEAN:
            stmt.setBool(index, value->data.boolean_val != 0);
            return SB_OK;
        case SB_TYPE_SMALLINT:
            stmt.setInt16(index, value->data.smallint_val);
            return SB_OK;
        case SB_TYPE_INTEGER:
            stmt.setInt32(index, value->data.integer_val);
            return SB_OK;
        case SB_TYPE_BIGINT:
            stmt.setInt64(index, value->data.bigint_val);
            return SB_OK;
        case SB_TYPE_REAL:
            stmt.setFloat(index, value->data.real_val);
            return SB_OK;
        case SB_TYPE_DOUBLE:
            stmt.setDouble(index, value->data.double_val);
            return SB_OK;
        case SB_TYPE_CHAR:
        case SB_TYPE_VARCHAR:
        case SB_TYPE_TEXT:
        case SB_TYPE_JSON:
        case SB_TYPE_JSONB:
        case SB_TYPE_XML:
        case SB_TYPE_TSVECTOR:
        case SB_TYPE_TSQUERY:
        case SB_TYPE_ARRAY:
        case SB_TYPE_VECTOR:
        case SB_TYPE_INET:
        case SB_TYPE_CIDR:
        case SB_TYPE_MACADDR:
        case SB_TYPE_DECIMAL:
            stmt.setString(index,
                           std::string(value->data.string_val.data, value->data.string_val.length),
                           resolve_type_oid(value));
            return SB_OK;
        case SB_TYPE_COMPOSITE:
        case SB_TYPE_RANGE:
        case SB_TYPE_UNKNOWN: {
            uint32_t type_oid = resolve_type_oid(value);
            if (value->type == SB_TYPE_RANGE && type_oid == 0) {
                return SB_ERR_INVALID_PARAM;
            }
            stmt.setBinary(index,
                           value->data.binary_val.data,
                           value->data.binary_val.length,
                           type_oid,
                           false);
            return SB_OK;
        }
        case SB_TYPE_GEOMETRY:
            stmt.setBinary(index,
                           value->data.binary_val.data,
                           value->data.binary_val.length,
                           resolve_type_oid(value),
                           true);
            return SB_OK;
        case SB_TYPE_BLOB:
            stmt.setBytes(index,
                          reinterpret_cast<const uint8_t*>(value->data.binary_val.data),
                          value->data.binary_val.length);
            return SB_OK;
        case SB_TYPE_MONEY: {
            int64_t cents = value->data.money_val;
            stmt.setBinary(index,
                           reinterpret_cast<const uint8_t*>(&cents),
                           sizeof(cents),
                           resolve_type_oid(value),
                           false);
            return SB_OK;
        }
        case SB_TYPE_DATE: {
            int32_t days = scratchbird::core::TypeExtractor::ymdToDays(
                value->data.date_val.year,
                value->data.date_val.month,
                value->data.date_val.day);
            int32_t days_since_2000 = days - kDaysFrom1970To2000;
            stmt.setDate(index, days_since_2000);
            return SB_OK;
        }
        case SB_TYPE_TIME: {
            int64_t micros = (static_cast<int64_t>(value->data.time_val.hour) * 3600 +
                              static_cast<int64_t>(value->data.time_val.minute) * 60 +
                              static_cast<int64_t>(value->data.time_val.second)) * 1000000LL +
                             value->data.time_val.microsecond;
            stmt.setTime(index, micros);
            return SB_OK;
        }
        case SB_TYPE_INTERVAL: {
            int64_t micros = value->data.interval_val.micros;
            int32_t days = value->data.interval_val.days;
            int32_t months = value->data.interval_val.months;
            uint8_t buf[16];
            std::memcpy(buf, &micros, sizeof(micros));
            std::memcpy(buf + 8, &days, sizeof(days));
            std::memcpy(buf + 12, &months, sizeof(months));
            stmt.setBinary(index, buf, sizeof(buf), resolve_type_oid(value), false);
            return SB_OK;
        }
        case SB_TYPE_TIMESTAMP:
        case SB_TYPE_TIMESTAMP_TZ:
            stmt.setTimestamp(index, value->data.timestamp_val.epoch_microseconds);
            return SB_OK;
        case SB_TYPE_UUID: {
            std::vector<uint8_t> data(value->data.uuid_val.bytes,
                                      value->data.uuid_val.bytes + 16);
            stmt.setUUID(index, data);
            return SB_OK;
        }
        default:
            return SB_ERR_INVALID_PARAM;
    }
}

std::vector<uint8_t> encode_length_prefixed(const uint8_t* data, size_t length) {
    std::vector<uint8_t> out(4 + length);
    uint32_t len = static_cast<uint32_t>(length);
    out[0] = static_cast<uint8_t>(len & 0xFF);
    out[1] = static_cast<uint8_t>((len >> 8) & 0xFF);
    out[2] = static_cast<uint8_t>((len >> 16) & 0xFF);
    out[3] = static_cast<uint8_t>((len >> 24) & 0xFF);
    if (data && length > 0) {
        std::memcpy(out.data() + 4, data, length);
    }
    return out;
}

int build_param_value(const sb_value* value, scratchbird::protocol::ParamValue& out) {
    if (!value) {
        return SB_ERR_NULL_POINTER;
    }
    out = scratchbird::protocol::ParamValue{};
    out.format = scratchbird::protocol::kFormatBinary;
    out.type_oid = resolve_type_oid(value);
    if (value->is_null || value->type == SB_TYPE_NULL) {
        out.is_null = true;
        return SB_OK;
    }
    if (value->type == SB_TYPE_RANGE && out.type_oid == 0) {
        return SB_ERR_INVALID_PARAM;
    }
    switch (value->type) {
        case SB_TYPE_BOOLEAN:
            out.data = { static_cast<uint8_t>(value->data.boolean_val != 0) };
            return SB_OK;
        case SB_TYPE_SMALLINT: {
            int16_t v = value->data.smallint_val;
            out.data.resize(2);
            out.data[0] = static_cast<uint8_t>(v & 0xFF);
            out.data[1] = static_cast<uint8_t>((v >> 8) & 0xFF);
            return SB_OK;
        }
        case SB_TYPE_INTEGER: {
            int32_t v = value->data.integer_val;
            out.data.resize(4);
            out.data[0] = static_cast<uint8_t>(v & 0xFF);
            out.data[1] = static_cast<uint8_t>((v >> 8) & 0xFF);
            out.data[2] = static_cast<uint8_t>((v >> 16) & 0xFF);
            out.data[3] = static_cast<uint8_t>((v >> 24) & 0xFF);
            return SB_OK;
        }
        case SB_TYPE_BIGINT: {
            int64_t v = value->data.bigint_val;
            out.data.resize(8);
            for (size_t i = 0; i < 8; ++i) {
                out.data[i] = static_cast<uint8_t>((static_cast<uint64_t>(v) >> (8 * i)) & 0xFF);
            }
            return SB_OK;
        }
        case SB_TYPE_REAL: {
            uint32_t bits = 0;
            std::memcpy(&bits, &value->data.real_val, sizeof(bits));
            out.data.resize(4);
            out.data[0] = static_cast<uint8_t>(bits & 0xFF);
            out.data[1] = static_cast<uint8_t>((bits >> 8) & 0xFF);
            out.data[2] = static_cast<uint8_t>((bits >> 16) & 0xFF);
            out.data[3] = static_cast<uint8_t>((bits >> 24) & 0xFF);
            return SB_OK;
        }
        case SB_TYPE_DOUBLE: {
            uint64_t bits = 0;
            std::memcpy(&bits, &value->data.double_val, sizeof(bits));
            out.data.resize(8);
            for (size_t i = 0; i < 8; ++i) {
                out.data[i] = static_cast<uint8_t>((bits >> (8 * i)) & 0xFF);
            }
            return SB_OK;
        }
        case SB_TYPE_CHAR:
        case SB_TYPE_VARCHAR:
        case SB_TYPE_TEXT:
        case SB_TYPE_JSON:
        case SB_TYPE_JSONB:
        case SB_TYPE_XML:
        case SB_TYPE_TSVECTOR:
        case SB_TYPE_TSQUERY:
        case SB_TYPE_ARRAY:
        case SB_TYPE_VECTOR:
        case SB_TYPE_INET:
        case SB_TYPE_CIDR:
        case SB_TYPE_MACADDR:
        case SB_TYPE_DECIMAL: {
            auto bytes = reinterpret_cast<const uint8_t*>(value->data.string_val.data);
            out.data = encode_length_prefixed(bytes, value->data.string_val.length);
            return SB_OK;
        }
        case SB_TYPE_COMPOSITE:
        case SB_TYPE_RANGE:
        case SB_TYPE_UNKNOWN: {
            if (value->data.binary_val.data && value->data.binary_val.length > 0) {
                out.data.assign(value->data.binary_val.data,
                                value->data.binary_val.data + value->data.binary_val.length);
            }
            return SB_OK;
        }
        case SB_TYPE_GEOMETRY: {
            auto bytes = reinterpret_cast<const uint8_t*>(value->data.binary_val.data);
            out.data = encode_length_prefixed(bytes, value->data.binary_val.length);
            return SB_OK;
        }
        case SB_TYPE_BLOB: {
            auto bytes = reinterpret_cast<const uint8_t*>(value->data.binary_val.data);
            out.data = encode_length_prefixed(bytes, value->data.binary_val.length);
            return SB_OK;
        }
        case SB_TYPE_MONEY: {
            int64_t cents = value->data.money_val;
            out.data.resize(8);
            std::memcpy(out.data.data(), &cents, sizeof(cents));
            return SB_OK;
        }
        case SB_TYPE_DATE: {
            int32_t days = scratchbird::core::TypeExtractor::ymdToDays(
                value->data.date_val.year,
                value->data.date_val.month,
                value->data.date_val.day);
            int32_t days_since_2000 = days - kDaysFrom1970To2000;
            out.data.resize(4);
            out.data[0] = static_cast<uint8_t>(days_since_2000 & 0xFF);
            out.data[1] = static_cast<uint8_t>((days_since_2000 >> 8) & 0xFF);
            out.data[2] = static_cast<uint8_t>((days_since_2000 >> 16) & 0xFF);
            out.data[3] = static_cast<uint8_t>((days_since_2000 >> 24) & 0xFF);
            return SB_OK;
        }
        case SB_TYPE_TIME: {
            int64_t micros = (static_cast<int64_t>(value->data.time_val.hour) * 3600 +
                              static_cast<int64_t>(value->data.time_val.minute) * 60 +
                              static_cast<int64_t>(value->data.time_val.second)) * kMicrosPerSecond +
                             value->data.time_val.microsecond;
            out.data.resize(8);
            for (size_t i = 0; i < 8; ++i) {
                out.data[i] = static_cast<uint8_t>((static_cast<uint64_t>(micros) >> (8 * i)) & 0xFF);
            }
            return SB_OK;
        }
        case SB_TYPE_INTERVAL: {
            out.data.resize(16);
            std::memcpy(out.data.data(), &value->data.interval_val.micros, sizeof(int64_t));
            std::memcpy(out.data.data() + 8, &value->data.interval_val.days, sizeof(int32_t));
            std::memcpy(out.data.data() + 12, &value->data.interval_val.months, sizeof(int32_t));
            return SB_OK;
        }
        case SB_TYPE_TIMESTAMP:
        case SB_TYPE_TIMESTAMP_TZ: {
            int64_t micros_since_2000 = value->data.timestamp_val.epoch_microseconds - kMicrosFrom1970To2000;
            out.data.resize(8);
            for (size_t i = 0; i < 8; ++i) {
                out.data[i] = static_cast<uint8_t>((static_cast<uint64_t>(micros_since_2000) >> (8 * i)) & 0xFF);
            }
            return SB_OK;
        }
        case SB_TYPE_UUID:
            out.data.assign(value->data.uuid_val.bytes,
                            value->data.uuid_val.bytes + 16);
            return SB_OK;
        default:
            return SB_ERR_INVALID_PARAM;
    }
}

} // namespace

sb_connection* sb_connect(const char* conn_str, sb_error* err) {
    if (!conn_str) {
        set_error(err, SB_ERR_NULL_POINTER, "Connection string is required");
        return nullptr;
    }
    auto* conn = new sb_connection();
    scratchbird::core::ErrorContext ctx;
    scratchbird::client::applyDriverDefaultsFromEnv(conn->config);
    auto status = scratchbird::client::parseDriverConnectionString(conn_str, conn->config, &ctx);
    if (status != scratchbird::core::Status::OK) {
        set_error(err, map_status(status), ctx.message);
        delete conn;
        return nullptr;
    }
    status = conn->client.connect(conn->config, &ctx);
    if (status != scratchbird::core::Status::OK) {
        set_error(err, map_status(status), ctx.message.empty() ? conn->client.lastError() : ctx.message);
        delete conn;
        return nullptr;
    }
    set_error(err, SB_OK, "");
    return conn;
}

void sb_disconnect(sb_connection* conn) {
    if (!conn) {
        return;
    }
    conn->client.disconnect();
    delete conn;
}

sb_result* sb_execute(sb_connection* conn, const char* sql, sb_error* err) {
    if (!conn || !sql) {
        set_error(err, SB_ERR_NULL_POINTER, "Connection and SQL required");
        return nullptr;
    }
    auto* result = new sb_result();
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.executeQuery(sql, result->results, &ctx);
    if (status != scratchbird::core::Status::OK) {
        set_error(err, map_status(status), ctx.message.empty() ? conn->client.lastError() : ctx.message);
        delete result;
        return nullptr;
    }
    result->column_names.reserve(result->results.columns.size());
    for (const auto& col : result->results.columns) {
        result->column_names.push_back(col.name);
    }
    set_error(err, SB_OK, "");
    return result;
}

sb_result* sb_query(sb_connection* conn, const char* sql, sb_error* err) {
    return sb_execute(conn, sql, err);
}

int sb_fetch(sb_result* result, sb_row* row, sb_error* err) {
    if (!result || !row) {
        set_error(err, SB_ERR_NULL_POINTER, "Result and row required");
        return SB_ERR_NULL_POINTER;
    }
    if (result->row_index >= result->results.rows.size()) {
        set_error(err, SB_ERR_RESULT_EXHAUSTED, "No more rows");
        return SB_ERR_RESULT_EXHAUSTED;
    }
    row->result = result;
    row->row_index = result->row_index++;
    set_error(err, SB_OK, "");
    return SB_OK;
}

void sb_result_free(sb_result* result) {
    delete result;
}

int sb_column_count(sb_result* result) {
    if (!result) {
        return 0;
    }
    return static_cast<int>(result->results.columns.size());
}

int sb_get_column_meta(sb_result* result, int index, sb_column_meta* out) {
    if (!result || !out) {
        return SB_ERR_NULL_POINTER;
    }
    if (index < 0 || static_cast<size_t>(index) >= result->results.columns.size()) {
        return SB_ERR_INVALID_PARAM;
    }
    const auto& col = result->results.columns[static_cast<size_t>(index)];
    out->name = result->column_names[static_cast<size_t>(index)].c_str();
    out->type = map_type_oid(col.type_oid);
    out->type_modifier = static_cast<int32_t>(col.type_modifier);
    out->nullable = col.nullable ? 1 : 0;
    return SB_OK;
}

int sb_value_get(sb_row* row, int column, sb_value* out) {
    if (!row || !row->result || !out) {
        return SB_ERR_NULL_POINTER;
    }
    const auto& results = row->result->results;
    if (row->row_index >= results.rows.size()) {
        return SB_ERR_RESULT_EXHAUSTED;
    }
    if (column < 0 || static_cast<size_t>(column) >= results.rows[row->row_index].size()) {
        return SB_ERR_INVALID_PARAM;
    }
    const auto& value = results.rows[row->row_index][static_cast<size_t>(column)];
    uint32_t type_oid = 0;
    if (static_cast<size_t>(column) < results.columns.size()) {
        type_oid = results.columns[static_cast<size_t>(column)].type_oid;
    }
    out->type = map_type_oid(type_oid);
    out->type_oid = type_oid;
    out->is_null = value.is_null ? 1 : 0;
    if (value.is_null) {
        return SB_OK;
    }
    const auto& data = value.data;
    auto stripLengthPrefix = [](const std::vector<uint8_t>& input,
                                const uint8_t** out_ptr,
                                size_t* out_len) {
        const uint8_t* ptr = input.empty() ? nullptr : input.data();
        size_t len = input.size();
        if (input.size() >= 4) {
            uint32_t payload_len = static_cast<uint32_t>(input[0]) |
                (static_cast<uint32_t>(input[1]) << 8) |
                (static_cast<uint32_t>(input[2]) << 16) |
                (static_cast<uint32_t>(input[3]) << 24);
            if (payload_len <= input.size() - 4) {
                ptr = input.data() + 4;
                len = payload_len;
            }
        }
        if (out_ptr) {
            *out_ptr = ptr;
        }
        if (out_len) {
            *out_len = len;
        }
    };
    switch (out->type) {
        case SB_TYPE_BOOLEAN:
            out->data.boolean_val = (!data.empty() && data[0]) ? 1 : 0;
            break;
        case SB_TYPE_SMALLINT: {
            int16_t v = 0;
            if (data.size() >= sizeof(v)) {
                std::memcpy(&v, data.data(), sizeof(v));
            }
            out->data.smallint_val = v;
            break;
        }
        case SB_TYPE_INTEGER: {
            int32_t v = 0;
            if (data.size() >= sizeof(v)) {
                std::memcpy(&v, data.data(), sizeof(v));
            }
            out->data.integer_val = v;
            break;
        }
        case SB_TYPE_BIGINT: {
            int64_t v = 0;
            if (data.size() >= sizeof(v)) {
                std::memcpy(&v, data.data(), sizeof(v));
            }
            out->data.bigint_val = v;
            break;
        }
        case SB_TYPE_REAL: {
            float v = 0;
            if (data.size() >= sizeof(v)) {
                std::memcpy(&v, data.data(), sizeof(v));
            }
            out->data.real_val = v;
            break;
        }
        case SB_TYPE_DOUBLE: {
            double v = 0;
            if (data.size() >= sizeof(v)) {
                std::memcpy(&v, data.data(), sizeof(v));
            }
            out->data.double_val = v;
            break;
        }
        case SB_TYPE_BLOB:
            out->data.binary_val.data = data.data();
            out->data.binary_val.length = data.size();
            break;
        case SB_TYPE_MONEY: {
            int64_t cents = 0;
            if (data.size() >= sizeof(cents)) {
                std::memcpy(&cents, data.data(), sizeof(cents));
            }
            out->data.money_val = cents;
            break;
        }
        case SB_TYPE_DATE: {
            int32_t days = 0;
            if (data.size() >= sizeof(days)) {
                std::memcpy(&days, data.data(), sizeof(days));
            }
            decode_date(days, out);
            break;
        }
        case SB_TYPE_TIME: {
            int64_t micros = 0;
            if (data.size() >= sizeof(micros)) {
                std::memcpy(&micros, data.data(), sizeof(micros));
            }
            decode_time(micros, out);
            break;
        }
        case SB_TYPE_INTERVAL: {
            int64_t micros = 0;
            int32_t days = 0;
            int32_t months = 0;
            if (data.size() >= 16) {
                std::memcpy(&micros, data.data(), sizeof(micros));
                std::memcpy(&days, data.data() + 8, sizeof(days));
                std::memcpy(&months, data.data() + 12, sizeof(months));
            }
            out->data.interval_val.micros = micros;
            out->data.interval_val.days = days;
            out->data.interval_val.months = months;
            break;
        }
        case SB_TYPE_TIMESTAMP:
        case SB_TYPE_TIMESTAMP_TZ: {
            int64_t micros = 0;
            if (data.size() >= sizeof(micros)) {
                std::memcpy(&micros, data.data(), sizeof(micros));
            }
            decode_timestamp(micros + kMicrosFrom1970To2000, out);
            break;
        }
        case SB_TYPE_UUID: {
            std::memset(out->data.uuid_val.bytes, 0, sizeof(out->data.uuid_val.bytes));
            if (data.size() >= 16) {
                std::memcpy(out->data.uuid_val.bytes, data.data(), 16);
            }
            break;
        }
        case SB_TYPE_GEOMETRY: {
            const uint8_t* raw_ptr = nullptr;
            size_t raw_len = 0;
            stripLengthPrefix(data, &raw_ptr, &raw_len);
            out->data.binary_val.data = raw_ptr;
            out->data.binary_val.length = raw_len;
            break;
        }
        case SB_TYPE_COMPOSITE:
        case SB_TYPE_RANGE:
        case SB_TYPE_UNKNOWN:
            out->data.binary_val.data = data.data();
            out->data.binary_val.length = data.size();
            break;
        case SB_TYPE_CHAR:
        case SB_TYPE_VARCHAR:
        case SB_TYPE_TEXT:
        case SB_TYPE_JSON:
        case SB_TYPE_JSONB:
        case SB_TYPE_XML:
        case SB_TYPE_TSVECTOR:
        case SB_TYPE_TSQUERY:
        case SB_TYPE_ARRAY:
        case SB_TYPE_VECTOR:
        case SB_TYPE_INET:
        case SB_TYPE_CIDR:
        case SB_TYPE_MACADDR:
        case SB_TYPE_DECIMAL: {
            const uint8_t* raw_ptr = nullptr;
            size_t raw_len = 0;
            stripLengthPrefix(data, &raw_ptr, &raw_len);
            out->data.string_val.data = raw_ptr ? reinterpret_cast<const char*>(raw_ptr) : "";
            out->data.string_val.length = raw_len;
            break;
        }
        default:
            const uint8_t* raw_ptr = nullptr;
            size_t raw_len = 0;
            stripLengthPrefix(data, &raw_ptr, &raw_len);
            if (out->type == SB_TYPE_BLOB) {
                out->data.binary_val.data = raw_ptr;
                out->data.binary_val.length = raw_len;
            } else {
                out->data.string_val.data = raw_ptr ? reinterpret_cast<const char*>(raw_ptr) : "";
                out->data.string_val.length = raw_len;
            }
            break;
    }
    return SB_OK;
}

int sb_get_int64(sb_row* row, int column, int64_t* out) {
    if (!out) {
        return SB_ERR_NULL_POINTER;
    }
    sb_value value{};
    auto status = sb_value_get(row, column, &value);
    if (status != SB_OK) {
        return status;
    }
    if (value.is_null) {
        *out = 0;
        return SB_OK;
    }
    switch (value.type) {
        case SB_TYPE_SMALLINT:
            *out = value.data.smallint_val;
            return SB_OK;
        case SB_TYPE_INTEGER:
            *out = value.data.integer_val;
            return SB_OK;
        case SB_TYPE_BIGINT:
            *out = value.data.bigint_val;
            return SB_OK;
        default:
            return SB_ERR_TYPE_MISMATCH;
    }
}

const char* sb_get_string(sb_row* row, int column, size_t* length) {
    sb_value value{};
    if (sb_value_get(row, column, &value) != SB_OK) {
        if (length) {
            *length = 0;
        }
        return nullptr;
    }
    if (value.is_null) {
        if (length) {
            *length = 0;
        }
        return nullptr;
    }
    if (value.type == SB_TYPE_BLOB) {
        if (length) {
            *length = value.data.binary_val.length;
        }
        return reinterpret_cast<const char*>(value.data.binary_val.data);
    }
    if (length) {
        *length = value.data.string_val.length;
    }
    return value.data.string_val.data;
}

sb_prepared* sb_prepare(sb_connection* conn, const char* sql, sb_error* err) {
    if (!conn || !sql) {
        set_error(err, SB_ERR_NULL_POINTER, "Connection and SQL required");
        return nullptr;
    }
    auto* stmt = new sb_prepared();
    stmt->conn = conn;
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.prepare(sql, stmt->stmt, &ctx);
    if (status != scratchbird::core::Status::OK) {
        set_error(err, map_status(status), ctx.message);
        delete stmt;
        return nullptr;
    }
    parse_named_params(sql, stmt->param_names);
    set_error(err, SB_OK, "");
    return stmt;
}

int sb_bind_index(sb_prepared* stmt, size_t index, const sb_value* value, sb_error* err) {
    if (!stmt) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Statement is null");
        return SB_ERR_INVALID_HANDLE;
    }
    auto code = apply_bind_value(stmt->stmt, index, value);
    if (code != SB_OK) {
        set_error(err, static_cast<sb_error_code>(code), "Failed to bind parameter");
    } else {
        set_error(err, SB_OK, "");
    }
    return code;
}

int sb_bind_name(sb_prepared* stmt, const char* name, const sb_value* value, sb_error* err) {
    if (!stmt || !name) {
        set_error(err, SB_ERR_NULL_POINTER, "Name required");
        return SB_ERR_NULL_POINTER;
    }
    for (size_t i = 0; i < stmt->param_names.size(); ++i) {
        if (stmt->param_names[i] == name) {
            return sb_bind_index(stmt, i + 1, value, err);
        }
    }
    set_error(err, SB_ERR_INVALID_PARAM, "Parameter name not found");
    return SB_ERR_INVALID_PARAM;
}

sb_result* sb_execute_prepared(sb_prepared* stmt, sb_error* err) {
    if (!stmt || !stmt->conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Statement is null");
        return nullptr;
    }
    auto* result = new sb_result();
    scratchbird::core::ErrorContext ctx;
    auto status = stmt->conn->client.executePrepared(stmt->stmt, result->results, &ctx);
    if (status != scratchbird::core::Status::OK) {
        set_error(err, map_status(status), ctx.message);
        delete result;
        return nullptr;
    }
    result->column_names.reserve(result->results.columns.size());
    for (const auto& col : result->results.columns) {
        result->column_names.push_back(col.name);
    }
    set_error(err, SB_OK, "");
    return result;
}

void sb_prepared_free(sb_prepared* stmt) {
    delete stmt;
}

int sb_tx_begin(sb_connection* conn, sb_error* err) {
    if (!conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Connection is null");
        return SB_ERR_INVALID_HANDLE;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.beginTransaction(&ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

int sb_tx_commit(sb_connection* conn, sb_error* err) {
    if (!conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Connection is null");
        return SB_ERR_INVALID_HANDLE;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.commit(&ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

int sb_tx_rollback(sb_connection* conn, sb_error* err) {
    if (!conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Connection is null");
        return SB_ERR_INVALID_HANDLE;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.rollback(&ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

int sb_cancel(sb_connection* conn, sb_error* err) {
    if (!conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Connection is null");
        return SB_ERR_INVALID_HANDLE;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.sendQueryCancel(&ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

int sb_subscribe(sb_connection* conn, uint8_t subscribe_type,
                 const char* channel, const char* filter, sb_error* err) {
    if (!conn || !channel) {
        set_error(err, SB_ERR_NULL_POINTER, "Connection and channel required");
        return SB_ERR_NULL_POINTER;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.subscribeNotifications(
        subscribe_type,
        channel,
        filter ? filter : "",
        &ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

int sb_unsubscribe(sb_connection* conn, const char* channel, sb_error* err) {
    if (!conn || !channel) {
        set_error(err, SB_ERR_NULL_POINTER, "Connection and channel required");
        return SB_ERR_NULL_POINTER;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.unsubscribeNotifications(channel, &ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

int sb_stream_control(sb_connection* conn, uint8_t control_type,
                      uint32_t window_size, uint32_t timeout_ms, sb_error* err) {
    if (!conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Connection is null");
        return SB_ERR_INVALID_HANDLE;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.streamControl(control_type, window_size, timeout_ms, &ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

int sb_attach_create(sb_connection* conn, const char* mode, const char* db_name, sb_error* err) {
    if (!conn || !mode || !db_name) {
        set_error(err, SB_ERR_NULL_POINTER, "Connection, mode, and database required");
        return SB_ERR_NULL_POINTER;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.attachCreate(mode, db_name, &ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

int sb_attach_detach(sb_connection* conn, sb_error* err) {
    if (!conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Connection is null");
        return SB_ERR_INVALID_HANDLE;
    }
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.attachDetach(&ctx);
    set_error(err, map_status(status), ctx.message);
    return status == scratchbird::core::Status::OK ? SB_OK : map_status(status);
}

sb_result* sb_attach_list(sb_connection* conn, sb_error* err) {
    if (!conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Connection is null");
        return nullptr;
    }
    auto* result = new sb_result();
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.attachList(result->results, &ctx);
    if (status != scratchbird::core::Status::OK) {
        set_error(err, map_status(status), ctx.message.empty() ? conn->client.lastError() : ctx.message);
        delete result;
        return nullptr;
    }
    result->column_names.reserve(result->results.columns.size());
    for (const auto& col : result->results.columns) {
        result->column_names.push_back(col.name);
    }
    set_error(err, SB_OK, "");
    return result;
}

sb_result* sb_execute_sblr(sb_connection* conn,
                           uint64_t sblr_hash,
                           const uint8_t* bytecode,
                           size_t bytecode_len,
                           const sb_value* params,
                           size_t param_count,
                           sb_error* err) {
    if (!conn) {
        set_error(err, SB_ERR_INVALID_HANDLE, "Connection is null");
        return nullptr;
    }
    if (!bytecode && bytecode_len > 0) {
        set_error(err, SB_ERR_NULL_POINTER, "Bytecode required");
        return nullptr;
    }
    if (param_count > 0 && !params) {
        set_error(err, SB_ERR_NULL_POINTER, "Parameters required");
        return nullptr;
    }
    std::vector<uint8_t> bytecode_vec;
    if (bytecode && bytecode_len > 0) {
        bytecode_vec.assign(bytecode, bytecode + bytecode_len);
    }
    std::vector<scratchbird::protocol::ParamValue> param_values;
    param_values.reserve(param_count);
    for (size_t i = 0; i < param_count; ++i) {
        scratchbird::protocol::ParamValue param;
        int code = build_param_value(&params[i], param);
        if (code != SB_OK) {
            set_error(err, static_cast<sb_error_code>(code), "Failed to bind parameter");
            return nullptr;
        }
        param_values.push_back(std::move(param));
    }
    auto* result = new sb_result();
    scratchbird::core::ErrorContext ctx;
    auto status = conn->client.executeSblr(sblr_hash, bytecode_vec, param_values, result->results, &ctx);
    if (status != scratchbird::core::Status::OK) {
        set_error(err, map_status(status), ctx.message.empty() ? conn->client.lastError() : ctx.message);
        delete result;
        return nullptr;
    }
    result->column_names.reserve(result->results.columns.size());
    for (const auto& col : result->results.columns) {
        result->column_names.push_back(col.name);
    }
    set_error(err, SB_OK, "");
    return result;
}
