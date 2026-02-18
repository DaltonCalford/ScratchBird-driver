/**
 * @file statement_cache.cpp
 * @brief Statement caching and batch operations for ScratchBird ODBC Driver
 */

#include "scratchbird/odbc/statement_cache.h"
#include "scratchbird/odbc/odbc_handles.h"

#include <cstring>
#include <unordered_map>
#include <list>
#include <chrono>
#include <thread>

using namespace scratchbird::odbc;

namespace {

struct CacheEntry {
    OdbcStatement* stmt{nullptr};
    std::string sql;
    std::chrono::steady_clock::time_point last_used;
    bool in_use{false};
};

struct CacheState {
    sb_odbc_stmt_cache_config config{sb_odbc_stmt_cache_config_default()};
    std::unordered_map<std::string, CacheEntry> entries;
    std::list<std::string> lru;
    SQLULEN hits{0};
    SQLULEN misses{0};
};

std::mutex g_cache_mutex;
std::unordered_map<SQLHDBC, CacheState> g_caches;

static void touch_lru(CacheState& state, const std::string& key) {
    state.lru.remove(key);
    state.lru.push_front(key);
}

static void evict_if_needed(CacheState& state, OdbcConnection* conn) {
    while (state.entries.size() > state.config.max_size && !state.lru.empty()) {
        const std::string key = state.lru.back();
        state.lru.pop_back();
        auto it = state.entries.find(key);
        if (it != state.entries.end()) {
            if (it->second.stmt) {
                it->second.stmt->freeStmt(SQL_CLOSE);
                conn->removeStatement(it->second.stmt);
            }
            state.entries.erase(it);
        }
    }
}

static void purge_expired(CacheState& state, OdbcConnection* conn) {
    if (state.config.ttl_seconds == 0) {
        return;
    }
    const auto now = std::chrono::steady_clock::now();
    for (auto it = state.entries.begin(); it != state.entries.end();) {
        auto age = std::chrono::duration_cast<std::chrono::seconds>(now - it->second.last_used).count();
        if (age > static_cast<long long>(state.config.ttl_seconds) && !it->second.in_use) {
            state.lru.remove(it->first);
            if (it->second.stmt) {
                it->second.stmt->freeStmt(SQL_CLOSE);
                conn->removeStatement(it->second.stmt);
            }
            it = state.entries.erase(it);
            continue;
        }
        ++it;
    }
}

static CacheState* get_state(SQLHDBC hdbc) {
    std::lock_guard<std::mutex> lock(g_cache_mutex);
    auto it = g_caches.find(hdbc);
    if (it == g_caches.end()) {
        return nullptr;
    }
    return &it->second;
}

} // namespace

SQLRETURN sb_odbc_stmt_cache_init(SQLHDBC hdbc, const sb_odbc_stmt_cache_config* config) {
    if (!hdbc) {
        return SQL_INVALID_HANDLE;
    }
    std::lock_guard<std::mutex> lock(g_cache_mutex);
    CacheState& state = g_caches[hdbc];
    if (config) {
        state.config = *config;
    } else {
        state.config = sb_odbc_stmt_cache_config_default();
    }
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_stmt_cache_get(
    SQLHDBC hdbc,
    SQLCHAR* sql_text,
    SQLINTEGER sql_len,
    SQLHSTMT* hstmt,
    SQLSMALLINT* cache_hit
) {
    if (!hdbc || !sql_text || !hstmt) {
        return SQL_INVALID_HANDLE;
    }
    OdbcConnection* conn = static_cast<OdbcConnection*>(hdbc);
    const std::string sql(reinterpret_cast<const char*>(sql_text), sql_len > 0 ? sql_len : std::strlen(reinterpret_cast<const char*>(sql_text)));

    CacheState* state = get_state(hdbc);
    if (!state || !state->config.enable_caching) {
        OdbcStatement* stmt = conn->createStatement();
        if (!stmt) {
            return SQL_ERROR;
        }
        SQLRETURN rc = stmt->prepare(reinterpret_cast<const SQLCHAR*>(sql.c_str()), static_cast<SQLINTEGER>(sql.size()));
        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
            conn->removeStatement(stmt);
            return rc;
        }
        *hstmt = static_cast<SQLHSTMT>(stmt);
        if (cache_hit) {
            *cache_hit = SQL_FALSE;
        }
        return SQL_SUCCESS;
    }

    purge_expired(*state, conn);

    auto it = state->entries.find(sql);
    if (it != state->entries.end() && !it->second.in_use && it->second.stmt) {
        it->second.in_use = true;
        it->second.last_used = std::chrono::steady_clock::now();
        touch_lru(*state, sql);
        state->hits++;
        *hstmt = static_cast<SQLHSTMT>(it->second.stmt);
        if (cache_hit) {
            *cache_hit = SQL_TRUE;
        }
        return SQL_SUCCESS;
    }

    // Cache miss
    state->misses++;
    OdbcStatement* stmt = conn->createStatement();
    if (!stmt) {
        return SQL_ERROR;
    }
    SQLRETURN rc = stmt->prepare(reinterpret_cast<const SQLCHAR*>(sql.c_str()), static_cast<SQLINTEGER>(sql.size()));
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
        conn->removeStatement(stmt);
        return rc;
    }
    *hstmt = static_cast<SQLHSTMT>(stmt);
    if (cache_hit) {
        *cache_hit = SQL_FALSE;
    }
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_stmt_cache_put(SQLHDBC hdbc, SQLHSTMT hstmt, SQLCHAR* sql_text, SQLINTEGER sql_len) {
    if (!hdbc || !hstmt || !sql_text) {
        return SQL_INVALID_HANDLE;
    }
    OdbcConnection* conn = static_cast<OdbcConnection*>(hdbc);
    CacheState* state = get_state(hdbc);
    const std::string sql(reinterpret_cast<const char*>(sql_text), sql_len > 0 ? sql_len : std::strlen(reinterpret_cast<const char*>(sql_text)));

    if (!state || !state->config.enable_caching) {
        return SQL_SUCCESS;
    }

    CacheEntry entry;
    entry.stmt = static_cast<OdbcStatement*>(hstmt);
    entry.sql = sql;
    entry.last_used = std::chrono::steady_clock::now();
    entry.in_use = false;

    state->entries[sql] = entry;
    touch_lru(*state, sql);
    evict_if_needed(*state, conn);
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_stmt_cache_invalidate(SQLHDBC hdbc, SQLCHAR* sql_text, SQLINTEGER sql_len) {
    if (!hdbc || !sql_text) {
        return SQL_INVALID_HANDLE;
    }
    OdbcConnection* conn = static_cast<OdbcConnection*>(hdbc);
    CacheState* state = get_state(hdbc);
    if (!state) {
        return SQL_SUCCESS;
    }
    const std::string sql(reinterpret_cast<const char*>(sql_text), sql_len > 0 ? sql_len : std::strlen(reinterpret_cast<const char*>(sql_text)));
    auto it = state->entries.find(sql);
    if (it != state->entries.end()) {
        if (it->second.stmt) {
            it->second.stmt->freeStmt(SQL_CLOSE);
            conn->removeStatement(it->second.stmt);
        }
        state->lru.remove(sql);
        state->entries.erase(it);
    }
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_stmt_cache_clear(SQLHDBC hdbc) {
    if (!hdbc) {
        return SQL_INVALID_HANDLE;
    }
    OdbcConnection* conn = static_cast<OdbcConnection*>(hdbc);
    CacheState* state = get_state(hdbc);
    if (!state) {
        return SQL_SUCCESS;
    }
    for (auto& kv : state->entries) {
        if (kv.second.stmt) {
            kv.second.stmt->freeStmt(SQL_CLOSE);
            conn->removeStatement(kv.second.stmt);
        }
    }
    state->entries.clear();
    state->lru.clear();
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_stmt_cache_stats(SQLHDBC hdbc, SQLULEN* cached_count, SQLULEN* hit_count, SQLULEN* miss_count) {
    if (!hdbc) {
        return SQL_INVALID_HANDLE;
    }
    CacheState* state = get_state(hdbc);
    if (!state) {
        if (cached_count) {
            *cached_count = 0;
        }
        if (hit_count) {
            *hit_count = 0;
        }
        if (miss_count) {
            *miss_count = 0;
        }
        return SQL_SUCCESS;
    }
    if (cached_count) {
        *cached_count = static_cast<SQLULEN>(state->entries.size());
    }
    if (hit_count) {
        *hit_count = state->hits;
    }
    if (miss_count) {
        *miss_count = state->misses;
    }
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_stmt_cache_destroy(SQLHDBC hdbc) {
    if (!hdbc) {
        return SQL_INVALID_HANDLE;
    }
    sb_odbc_stmt_cache_clear(hdbc);
    std::lock_guard<std::mutex> lock(g_cache_mutex);
    g_caches.erase(hdbc);
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_batch_execute(
    SQLHSTMT hstmt,
    const sb_odbc_batch_op* operations,
    SQLULEN operation_count,
    SQLULEN* rows_affected,
    SQLULEN* error_index
) {
    if (!hstmt || !operations || operation_count == 0) {
        return SQL_INVALID_HANDLE;
    }
    auto* stmt = static_cast<OdbcStatement*>(hstmt);
    SQLULEN total_rows = 0;
    for (SQLULEN i = 0; i < operation_count; ++i) {
        if (operations[i].param_count > 0) {
            if (error_index) {
                *error_index = i;
            }
            return SQL_ERROR; // Parameterized batch not implemented
        }
        SQLRETURN rc = stmt->execDirect(operations[i].sql, operations[i].sql_len);
        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
            if (error_index) {
                *error_index = i;
            }
            return rc;
        }
        total_rows += 1;
    }
    if (rows_affected) {
        *rows_affected = total_rows;
    }
    if (error_index) {
        *error_index = 0;
    }
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_bulk_insert(
    SQLHSTMT hstmt,
    SQLCHAR* table_name,
    SQLCHAR** columns,
    SQLSMALLINT column_count,
    SQLPOINTER* data,
    SQLLEN* data_lens,
    SQLULEN row_count,
    SQLULEN* rows_inserted
) {
    (void)columns;
    (void)column_count;
    (void)data;
    (void)data_lens;
    if (!hstmt || !table_name || row_count == 0) {
        return SQL_INVALID_HANDLE;
    }
    // Array binding not implemented; return error to avoid false success.
    if (rows_inserted) {
        *rows_inserted = 0;
    }
    return SQL_ERROR;
}

SQLRETURN sb_odbc_with_retry(
    SQLHDBC hdbc,
    const sb_odbc_retry_config* config,
    SQLRETURN (*operation)(void* user_data),
    void* user_data,
    SQLULEN* attempt_count
) {
    if (!hdbc || !operation) {
        return SQL_INVALID_HANDLE;
    }
    sb_odbc_retry_config cfg = config ? *config : sb_odbc_retry_config_default();
    SQLULEN attempts = 0;
    SQLRETURN rc = SQL_ERROR;
    DWORD delay = static_cast<DWORD>(cfg.base_delay_ms);

    for (; attempts <= cfg.max_retries; ++attempts) {
        rc = operation(user_data);
        if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO) {
            break;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(delay));
        delay = std::min<DWORD>(delay * 2, static_cast<DWORD>(cfg.max_delay_ms));
    }

    if (attempt_count) {
        *attempt_count = attempts;
    }
    return rc;
}

SQLRETURN sb_odbc_connection_is_healthy(SQLHDBC hdbc, SQLSMALLINT* is_healthy) {
    if (!hdbc || !is_healthy) {
        return SQL_INVALID_HANDLE;
    }
    auto* conn = static_cast<OdbcConnection*>(hdbc);
    *is_healthy = conn->isConnected() ? SQL_TRUE : SQL_FALSE;
    return SQL_SUCCESS;
}

SQLRETURN sb_odbc_connection_validate(SQLHDBC hdbc, SQLULEN timeout_ms, SQLSMALLINT* is_valid) {
    (void)timeout_ms;
    if (!hdbc || !is_valid) {
        return SQL_INVALID_HANDLE;
    }
    auto* conn = static_cast<OdbcConnection*>(hdbc);
    if (!conn->isConnected()) {
        *is_valid = SQL_FALSE;
        return SQL_SUCCESS;
    }
    std::vector<std::vector<std::string>> rows;
    std::vector<ColumnMetadata> columns;
    SQLLEN rows_affected = 0;
    SQLRETURN rc = conn->executeSQL("SELECT 1", rows, columns, rows_affected);
    *is_valid = (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO) ? SQL_TRUE : SQL_FALSE;
    return SQL_SUCCESS;
}
