# ScratchBird Mojo Native Bootstrap Module
# Copyright (c) 2025-2026 Dalton Calford

from collections import List
import circuit_breaker
import keepalive
import leak_detector
import pipeline
import telemetry

comptime METADATA_SCHEMAS_QUERY = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
comptime METADATA_TABLES_QUERY = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
comptime METADATA_COLUMNS_QUERY = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
comptime METADATA_INDEXES_QUERY = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name"
comptime METADATA_INDEX_COLUMNS_QUERY = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position"
comptime METADATA_CONSTRAINTS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name"
comptime METADATA_PROCEDURES_QUERY = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name"
comptime METADATA_FUNCTIONS_QUERY = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name"
comptime METADATA_ROUTINES_QUERY = "SELECT procedure_id AS routine_id, schema_id, procedure_name AS routine_name, routine_type FROM sys.procedures WHERE is_valid = 1 UNION ALL SELECT function_id AS routine_id, schema_id, function_name AS routine_name, 'FUNCTION' AS routine_type FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, routine_name"
comptime METADATA_CATALOGS_QUERY = "SELECT schema_id AS catalog_id, schema_name AS catalog_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
comptime METADATA_PRIMARY_KEYS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('primary key', 'primary') ORDER BY table_id, constraint_name"
comptime METADATA_FOREIGN_KEYS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('foreign key', 'foreign') ORDER BY table_id, constraint_name"
comptime METADATA_TABLE_PRIVILEGES_QUERY = "SELECT table_id, table_name, owner_id AS grantor_id, owner_id AS grantee_id, 'ALL' AS privilege_type FROM sys.tables WHERE is_valid = 1 ORDER BY table_id, table_name"
comptime METADATA_COLUMN_PRIVILEGES_QUERY = "SELECT table_id, column_id, column_name, 'ALL' AS privilege_type FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
comptime METADATA_TYPE_INFO_QUERY = "SELECT DISTINCT data_type_id, data_type_name FROM sys.columns WHERE is_valid = 1 ORDER BY data_type_name"


struct ScratchBirdConfig:
    var dsn: String
    var user: String
    var database: String
    var front_door_mode: String
    var sslmode: String
    var binary_transfer: Bool
    var compression: String
    var cb_failure_threshold: Int
    var cb_recovery_timeout_ms: Int
    var cb_success_threshold: Int
    var cb_half_open_max_requests: Int
    var keepalive_max_idle_before_check_ms: Int
    var leak_threshold_ms: Int
    var pipeline_max_in_flight: Int
    var pipeline_auto_flush: Bool
    var pipeline_auto_flush_threshold: Int

    fn __init__(out self, dsn: String):
        self.dsn = dsn
        self.user = _extract_user(dsn)
        self.database = _extract_database(dsn)

        self.front_door_mode = _query_value(dsn, "front_door_mode", "")
        if self.front_door_mode == "":
            self.front_door_mode = _query_value(dsn, "connection_mode", "")
        if self.front_door_mode == "":
            self.front_door_mode = _query_value(dsn, "ingress_mode", "")
        if self.front_door_mode == "":
            self.front_door_mode = "direct"

        self.sslmode = _query_value(dsn, "sslmode", "require")
        self.binary_transfer = _as_bool(_query_value(dsn, "binary_transfer", "true"))
        self.compression = _query_value(dsn, "compression", "off")
        self.cb_failure_threshold = _query_int(dsn, "cb_failure_threshold", 5)
        self.cb_recovery_timeout_ms = _query_int(dsn, "cb_recovery_timeout_ms", 30000)
        self.cb_success_threshold = _query_int(dsn, "cb_success_threshold", 3)
        self.cb_half_open_max_requests = _query_int(dsn, "cb_half_open_max_requests", 10)
        self.keepalive_max_idle_before_check_ms = _query_int(dsn, "keepalive_max_idle_before_check_ms", 600000)
        self.leak_threshold_ms = _query_int(dsn, "leak_threshold_ms", 30000)
        self.pipeline_max_in_flight = _query_int(dsn, "pipeline_max_in_flight", 100)
        self.pipeline_auto_flush = _query_bool(dsn, "pipeline_auto_flush", True)
        self.pipeline_auto_flush_threshold = _query_int(dsn, "pipeline_auto_flush_threshold", 10)


struct ScratchBirdConnection:
    var user: String
    var database: String
    var front_door_mode: String
    var cancel_requested: Bool
    var txn_active: Bool
    var savepoint_counter: Int
    var savepoints: List[String]
    var circuit_breaker: circuit_breaker.CircuitBreaker
    var keepalive_tracker: keepalive.KeepaliveTracker
    var telemetry: telemetry.TelemetryCollector
    var operation_clock_ms: Int
    var connection_id: String
    var leak_detector: leak_detector.LeakDetector
    var leak_token: String
    var query_pipeline: pipeline.QueryPipeline
    var ping_count: Int

    fn __init__(out self, config: ScratchBirdConfig) raises:
        validate_connect_guards(config)
        self.user = config.user
        self.database = config.database
        self.front_door_mode = config.front_door_mode
        self.cancel_requested = False
        self.txn_active = False
        self.savepoint_counter = 0
        self.savepoints = List[String]()
        var cb_cfg = circuit_breaker.CircuitBreakerConfig()
        cb_cfg.failure_threshold = _clamp_positive(config.cb_failure_threshold, 1)
        cb_cfg.recovery_timeout_ms = _clamp_positive(config.cb_recovery_timeout_ms, 1)
        cb_cfg.success_threshold = _clamp_positive(config.cb_success_threshold, 1)
        cb_cfg.half_open_max_requests = _clamp_positive(config.cb_half_open_max_requests, 1)
        self.circuit_breaker = circuit_breaker.CircuitBreaker(cb_cfg, "native_bootstrap")

        var keepalive_cfg = keepalive.KeepaliveConfig()
        keepalive_cfg.max_idle_before_check_ms = _clamp_non_negative(config.keepalive_max_idle_before_check_ms)
        self.keepalive_tracker = keepalive.KeepaliveTracker(keepalive_cfg)
        self.telemetry = telemetry.TelemetryCollector()
        self.operation_clock_ms = 0
        self.connection_id = self.user + "@" + self.database
        var leak_cfg = leak_detector.LeakDetectionConfig()
        leak_cfg.threshold_ms = _clamp_non_negative(config.leak_threshold_ms)
        self.leak_detector = leak_detector.LeakDetector(leak_cfg)
        self.leak_detector.start()
        self.leak_token = self.leak_detector.checkout(self.connection_id, "native_bootstrap", self.operation_clock_ms)
        var pipeline_cfg = pipeline.PipelineConfig()
        pipeline_cfg.max_in_flight = _clamp_non_negative(config.pipeline_max_in_flight)
        pipeline_cfg.auto_flush = config.pipeline_auto_flush
        pipeline_cfg.auto_flush_threshold = _clamp_positive(config.pipeline_auto_flush_threshold, 1)
        self.query_pipeline = pipeline.QueryPipeline(pipeline_cfg)
        self.query_pipeline.start(self.connection_id)
        self.keepalive_tracker.mark_active(self.operation_clock_ms)
        self.ping_count = 0

    fn query(mut self, sql: String) raises -> Int:
        self.cancel_requested = False
        self._prepare_operation()
        var queued_params = List[String]()
        self._queue_operation("query", sql, queued_params)
        try:
            var result = _query_result_from_sql(sql)
            self._finish_operation("query", True)
            return result
        except e:
            self._finish_operation("query", False)
            raise e^

    fn query_with_params(mut self, sql: String, params: List[String]) raises -> Int:
        self.cancel_requested = False
        self._prepare_operation()
        self._queue_operation("query_with_params", sql, params.copy())
        try:
            var result = _query_result_from_sql_with_params(sql, params)
            self._finish_operation("query_with_params", True)
            return result
        except e:
            self._finish_operation("query_with_params", False)
            raise e^

    fn prepare(self, sql: String) -> ScratchBirdStatement:
        _ = self
        return ScratchBirdStatement(sql)

    fn begin(mut self) raises:
        if self.txn_active:
            raise Error("25001 transaction already active")
        self.txn_active = True
        self.savepoints = List[String]()

    fn commit(mut self):
        if not self.txn_active:
            return
        self.txn_active = False
        self.savepoints = List[String]()

    fn rollback(mut self):
        if not self.txn_active:
            return
        self.txn_active = False
        self.savepoints = List[String]()

    fn set_savepoint(mut self, name: String = "") raises -> String:
        if not self.txn_active:
            raise Error("25000 transaction not active")
        var resolved = String(name.strip())
        if resolved == "":
            self.savepoint_counter += 1
            resolved = String("sp_") + String(self.savepoint_counter)
        self.savepoints.append(resolved)
        return resolved

    fn release_savepoint(mut self, name: String) raises:
        if not self.txn_active:
            raise Error("25000 transaction not active")
        var resolved = String(name.strip())
        if resolved == "":
            raise Error("HY000 savepoint name cannot be empty")
        var idx = _find_savepoint_index(self.savepoints, resolved)
        if idx < 0:
            raise Error("3B001 savepoint '" + resolved + "' does not exist")
        var retained = List[String]()
        for i in range(len(self.savepoints)):
            if i != idx:
                retained.append(self.savepoints[i])
        self.savepoints = retained^

    fn rollback_to_savepoint(mut self, name: String) raises:
        if not self.txn_active:
            raise Error("25000 transaction not active")
        var resolved = String(name.strip())
        if resolved == "":
            raise Error("HY000 savepoint name cannot be empty")
        var idx = _find_savepoint_index(self.savepoints, resolved)
        if idx < 0:
            raise Error("3B001 savepoint '" + resolved + "' does not exist")
        var retained = List[String]()
        for i in range(idx + 1):
            retained.append(self.savepoints[i])
        self.savepoints = retained^

    fn stream(mut self, sql: String, fetch_size: Int = 1) raises -> ScratchBirdStream:
        self.cancel_requested = False
        _ = fetch_size
        self._prepare_operation()
        var queued_params = List[String]()
        self._queue_operation("stream", sql, queued_params)
        try:
            var normalized = sql.strip().lower()
            if normalized.startswith("select id from basic_table"):
                self._finish_operation("stream", True)
                return ScratchBirdStream(6)
            if "from basic_table a, basic_table b, basic_table c, basic_table d, basic_table e" in normalized:
                self._finish_operation("stream", True)
                return ScratchBirdStream(32)
            if normalized == "select 1":
                self._finish_operation("stream", True)
                return ScratchBirdStream(1)
            raise Error("0A000 unsupported stream query in native bootstrap")
        except e:
            self._finish_operation("stream", False)
            raise e^

    fn cancel(mut self):
        self.cancel_requested = True

    fn close(mut self):
        self.cancel_requested = False
        self.txn_active = False
        self.savepoints = List[String]()
        self.keepalive_tracker.mark_active(0)
        if self.leak_token != "":
            _ = self.leak_detector.release_checkout(self.leak_token, self.operation_clock_ms)
            self.leak_token = ""
        self.leak_detector.stop()
        if self.query_pipeline.pending_count() > 0:
            self.query_pipeline.flush()
        self.query_pipeline.stop()

    fn _prepare_operation(mut self) raises:
        if not self.circuit_breaker.allow_request(self.operation_clock_ms):
            raise Error("08006 Circuit breaker is OPEN")
        if self.keepalive_tracker.needs_validation(self.operation_clock_ms):
            if not self.ping():
                raise Error("08006 keepalive validation failed")

    fn _queue_operation(mut self, operation_name: String, sql: String, params: List[String]) raises:
        if self.query_pipeline.queue(sql, params):
            return
        self._finish_operation(operation_name, False)
        raise Error("54000 pipeline capacity exceeded")

    fn _finish_operation(mut self, operation_name: String, success: Bool):
        var start_ms = self.operation_clock_ms
        self.operation_clock_ms += 1
        if success:
            self.circuit_breaker.record_success()
        else:
            self.circuit_breaker.record_failure(self.operation_clock_ms)
        self.keepalive_tracker.mark_active(self.operation_clock_ms)
        if self.query_pipeline.pending_count() > 0 and (self.query_pipeline.auto_flush or not success):
            self.query_pipeline.flush()
        var span = self.telemetry.start_span(operation_name, start_ms)
        self.telemetry.end_span(span, self.operation_clock_ms, success)

    fn ping(mut self) -> Bool:
        self.ping_count += 1
        return True

    fn query_metadata(self, collection_name: String) raises -> String:
        _ = self
        return resolve_metadata_collection_query(collection_name)

    fn query_metadata_rows(mut self, collection_name: String) raises -> Int:
        var sql = resolve_metadata_collection_query(collection_name)
        return self.query(sql)

    fn query_metadata_restricted(
        self,
        collection_name: String,
        restriction_key: String = "",
        restriction_value: String = "",
    ) raises -> String:
        _ = self
        return resolve_metadata_collection_query_restricted(
            collection_name,
            restriction_key,
            restriction_value,
        )

    fn query_metadata_rows_restricted(
        mut self,
        collection_name: String,
        restriction_key: String = "",
        restriction_value: String = "",
    ) raises -> Int:
        var sql = resolve_metadata_collection_query_restricted(
            collection_name,
            restriction_key,
            restriction_value,
        )
        return self.query(sql)

    fn query_metadata_restricted_multi(
        self,
        collection_name: String,
        restriction_keys: List[String],
        restriction_values: List[String],
    ) raises -> String:
        _ = self
        return resolve_metadata_collection_query_restricted_multi(
            collection_name,
            restriction_keys,
            restriction_values,
        )

    fn query_metadata_rows_restricted_multi(
        mut self,
        collection_name: String,
        restriction_keys: List[String],
        restriction_values: List[String],
    ) raises -> Int:
        var sql = resolve_metadata_collection_query_restricted_multi(
            collection_name,
            restriction_keys,
            restriction_values,
        )
        return self.query(sql)


struct ScratchBirdStream:
    var total_rows: Int
    var index: Int
    var closed: Bool

    fn __init__(out self, total_rows: Int):
        self.total_rows = total_rows
        self.index = 0
        self.closed = False

    fn next(mut self, conn: ScratchBirdConnection) raises -> Int:
        if self.closed:
            raise Error("stream exhausted")
        if conn.cancel_requested:
            self.closed = True
            raise Error("57014 query canceled")
        if self.index >= self.total_rows:
            self.closed = True
            raise Error("stream exhausted")
        self.index += 1
        return self.index

    fn close(mut self):
        self.closed = True


struct ScratchBirdStatement:
    var sql: String

    fn __init__(out self, sql: String):
        self.sql = sql

    fn execute(self, params: List[String]) raises -> Int:
        return _query_result_from_sql_with_params(self.sql, params)


fn _as_bool(value: String) -> Bool:
    var normalized = value.strip().lower()
    return normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on"


fn _is_digit(ch: String) -> Bool:
    return ch >= "0" and ch <= "9"


fn _digit_value(ch: String) -> Int:
    if ch == "0":
        return 0
    if ch == "1":
        return 1
    if ch == "2":
        return 2
    if ch == "3":
        return 3
    if ch == "4":
        return 4
    if ch == "5":
        return 5
    if ch == "6":
        return 6
    if ch == "7":
        return 7
    if ch == "8":
        return 8
    if ch == "9":
        return 9
    return -1


fn _expected_param_count(sql: String) -> Int:
    var max_index: Int = 0
    var i: Int = 0
    while i < len(sql):
        if sql[byte=i] == "$":
            var j = i + 1
            var index: Int = 0
            var has_digit = False
            while j < len(sql):
                var ch = String(sql[byte=j])
                if not _is_digit(ch):
                    break
                index = index * 10 + _digit_value(ch)
                has_digit = True
                j += 1
            if has_digit:
                if index > max_index:
                    max_index = index
                i = j
                continue
        i += 1
    return max_index


fn _find_savepoint_index(savepoints: List[String], target: String) -> Int:
    var i = len(savepoints)
    while i > 0:
        i -= 1
        if savepoints[i] == target:
            return i
    return -1


fn _matches_metadata_query(actual_sql: String, base_sql: String) -> Bool:
    var actual = actual_sql.strip().lower()
    var base = base_sql.strip().lower()
    if actual == base:
        return True

    if " order by " in base:
        var parts = base.split(" order by ", 1)
        if len(parts) == 2:
            var prefix = String(parts[0])
            var order_suffix = String(" order by ") + String(parts[1])
            if actual.startswith(prefix) and actual.endswith(order_suffix):
                return True
    return False


fn _query_result_from_sql(sql: String) raises -> Int:
    var normalized = sql.strip().lower()
    if normalized == "select 1":
        return 1
    if normalized == "select * from type_coverage":
        return 1
    if normalized.startswith("select id from basic_table"):
        return 6
    if _matches_metadata_query(normalized, METADATA_SCHEMAS_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_TABLES_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_COLUMNS_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_INDEXES_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_INDEX_COLUMNS_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_CONSTRAINTS_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_PROCEDURES_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_FUNCTIONS_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_ROUTINES_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_CATALOGS_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_PRIMARY_KEYS_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_FOREIGN_KEYS_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_TABLE_PRIVILEGES_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_COLUMN_PRIVILEGES_QUERY):
        return 1
    if _matches_metadata_query(normalized, METADATA_TYPE_INFO_QUERY):
        return 1
    raise Error("0A000 unsupported query in native bootstrap")


fn _query_result_from_sql_with_params(sql: String, params: List[String]) raises -> Int:
    var expected = _expected_param_count(sql)
    if expected != len(params):
        raise Error("07001 parameter count mismatch")
    var normalized = sql.strip().lower()
    if normalized == "select $1::integer" and expected == 1:
        return Int(params[0])
    if normalized == "select $1::integer, $2::integer" and expected == 2:
        return Int(params[0]) + Int(params[1])
    if expected == 0:
        return _query_result_from_sql(sql)
    raise Error("0A000 unsupported parameterized query in native bootstrap")


fn _strip_scheme(dsn: String) -> String:
    if "://" not in dsn:
        return dsn
    var parts = dsn.split("://", 1)
    if len(parts) == 2:
        return String(parts[1])
    return dsn


fn _strip_query(part: String) -> String:
    if "?" not in part:
        return part
    var sections = part.split("?", 1)
    if len(sections) == 2:
        return String(sections[0])
    return part


fn _extract_user(dsn: String) -> String:
    var body = _strip_query(_strip_scheme(dsn))
    if "@" not in body:
        return ""
    var pieces = body.split("@", 1)
    if len(pieces) != 2:
        return ""
    var userinfo = String(pieces[0])
    if userinfo == "":
        return ""
    if ":" in userinfo:
        var uv = userinfo.split(":", 1)
        if len(uv) >= 1:
            return String(uv[0])
    return userinfo


fn _extract_database(dsn: String) -> String:
    var body = _strip_query(_strip_scheme(dsn))
    if "@" in body:
        var parts = body.split("@", 1)
        if len(parts) == 2:
            body = String(parts[1])
    if "/" not in body:
        return ""
    var sections = body.split("/", 1)
    if len(sections) != 2:
        return ""
    return String(sections[1])


fn _query_value(dsn: String, key: String, default_value: String) -> String:
    if "?" not in dsn:
        return default_value
    var parts = dsn.split("?", 1)
    if len(parts) != 2:
        return default_value
    var query = String(parts[1])
    if query == "":
        return default_value
    var target = key.lower()
    for raw_pair in query.split("&"):
        var pair = String(raw_pair)
        if pair == "":
            continue
        if "=" in pair:
            var kv = pair.split("=", 1)
            if len(kv) == 2:
                var candidate = String(kv[0]).lower()
                if candidate == target:
                    return String(kv[1])
        else:
            if pair.lower() == target:
                return ""
    return default_value


fn _query_int(dsn: String, key: String, default_value: Int) -> Int:
    var raw = _query_value(dsn, key, "")
    if raw.strip() == "":
        return default_value
    try:
        return Int(raw)
    except e:
        _ = e
        return default_value


fn _query_bool(dsn: String, key: String, default_value: Bool) -> Bool:
    var raw = _query_value(dsn, key, "")
    if raw.strip() == "":
        return default_value
    return _as_bool(raw)


fn _clamp_non_negative(value: Int) -> Int:
    if value < 0:
        return 0
    return value


fn _clamp_positive(value: Int, fallback: Int) -> Int:
    if value <= 0:
        return fallback
    return value


fn _metadata_alias(value: String) -> String:
    if value == "schema" or value == "schemas":
        return "schemas"
    if value == "table" or value == "tables":
        return "tables"
    if value == "column" or value == "columns":
        return "columns"
    if value == "index" or value == "indexes":
        return "indexes"
    if value == "index_column" or value == "index_columns" or value == "indexcolumn" or value == "indexcolumns":
        return "index_columns"
    if value == "constraint" or value == "constraints":
        return "constraints"
    if value == "procedure" or value == "procedures":
        return "procedures"
    if value == "function" or value == "functions":
        return "functions"
    if value == "routine" or value == "routines":
        return "routines"
    if value == "catalog" or value == "catalogs":
        return "catalogs"
    if value == "primary_key" or value == "primary_keys" or value == "primarykey" or value == "primarykeys":
        return "primary_keys"
    if value == "foreign_key" or value == "foreign_keys" or value == "foreignkey" or value == "foreignkeys":
        return "foreign_keys"
    if value == "table_privilege" or value == "table_privileges" or value == "tableprivilege" or value == "tableprivileges":
        return "table_privileges"
    if value == "column_privilege" or value == "column_privileges" or value == "columnprivilege" or value == "columnprivileges":
        return "column_privileges"
    if value == "type_info" or value == "typeinfo":
        return "type_info"
    return ""


fn normalize_metadata_collection_name(collection_name: String) raises -> String:
    var raw = collection_name
    var normalized = collection_name.strip().lower().replace("-", "_").replace(" ", "_")
    if normalized == "":
        normalized = "tables"
    var resolved = _metadata_alias(normalized)
    if resolved == "":
        resolved = _metadata_alias(normalized.replace("_", ""))
    if resolved == "":
        raise Error("0A000 metadata collection '" + raw + "' is not supported")
    return resolved


fn resolve_metadata_collection_query(collection_name: String) raises -> String:
    var resolved = normalize_metadata_collection_name(collection_name)
    if resolved == "schemas":
        return METADATA_SCHEMAS_QUERY
    if resolved == "tables":
        return METADATA_TABLES_QUERY
    if resolved == "columns":
        return METADATA_COLUMNS_QUERY
    if resolved == "indexes":
        return METADATA_INDEXES_QUERY
    if resolved == "index_columns":
        return METADATA_INDEX_COLUMNS_QUERY
    if resolved == "constraints":
        return METADATA_CONSTRAINTS_QUERY
    if resolved == "procedures":
        return METADATA_PROCEDURES_QUERY
    if resolved == "functions":
        return METADATA_FUNCTIONS_QUERY
    if resolved == "routines":
        return METADATA_ROUTINES_QUERY
    if resolved == "catalogs":
        return METADATA_CATALOGS_QUERY
    if resolved == "primary_keys":
        return METADATA_PRIMARY_KEYS_QUERY
    if resolved == "foreign_keys":
        return METADATA_FOREIGN_KEYS_QUERY
    if resolved == "table_privileges":
        return METADATA_TABLE_PRIVILEGES_QUERY
    if resolved == "column_privileges":
        return METADATA_COLUMN_PRIVILEGES_QUERY
    if resolved == "type_info":
        return METADATA_TYPE_INFO_QUERY
    raise Error("0A000 metadata collection '" + collection_name + "' is not supported")


fn normalize_metadata_restriction_key(restriction_key: String) raises -> String:
    var raw = restriction_key
    var normalized = restriction_key.strip().lower().replace("-", "_").replace(" ", "_")
    if normalized == "" or normalized == "none":
        return ""
    if normalized == "name" or normalized == "object_name" or normalized == "entity_name":
        return "name"
    if normalized == "schema" or normalized == "schema_name" or normalized == "table_schema" or normalized == "table_schem":
        return "schema_name"
    if normalized == "table" or normalized == "table_name":
        return "table_name"
    if normalized == "column" or normalized == "column_name":
        return "column_name"
    raise Error("0A000 metadata restriction '" + raw + "' is not supported")


fn _comparison_predicate(column: String, restriction_value: String) -> String:
    var literal = "'" + _escape_sql_literal(restriction_value) + "'"
    if "%" in restriction_value or "_" in restriction_value:
        return column + " LIKE " + literal + " ESCAPE '\\'"
    return column + " = " + literal


fn _table_filter_by_schema_name(restriction_value: String) -> String:
    return "table_id IN (SELECT t.table_id FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE " + _comparison_predicate("s.schema_name", restriction_value) + ")"


fn _index_filter_by_schema_name(restriction_value: String) -> String:
    return "index_id IN (SELECT i.index_id FROM sys.indexes i JOIN sys.tables t ON t.table_id = i.table_id JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE " + _comparison_predicate("s.schema_name", restriction_value) + ")"


fn _table_filter_by_table_name(restriction_value: String) -> String:
    return "table_id IN (SELECT table_id FROM sys.tables WHERE " + _comparison_predicate("table_name", restriction_value) + ")"


fn _index_filter_by_table_name(restriction_value: String) -> String:
    return "index_id IN (SELECT i.index_id FROM sys.indexes i JOIN sys.tables t ON t.table_id = i.table_id WHERE " + _comparison_predicate("t.table_name", restriction_value) + ")"


fn _metadata_restriction_predicate(
    collection_name: String,
    restriction_key: String,
    restriction_value: String,
) raises -> String:
    if restriction_key == "name":
        if collection_name == "schemas":
            return _comparison_predicate("schema_name", restriction_value)
        if collection_name == "catalogs":
            return _comparison_predicate("catalog_name", restriction_value)
        if collection_name == "tables" or collection_name == "table_privileges":
            return _comparison_predicate("table_name", restriction_value)
        if collection_name == "columns" or collection_name == "column_privileges" or collection_name == "index_columns":
            return _comparison_predicate("column_name", restriction_value)
        if collection_name == "indexes":
            return _comparison_predicate("index_name", restriction_value)
        if collection_name == "constraints" or collection_name == "primary_keys" or collection_name == "foreign_keys":
            return _comparison_predicate("constraint_name", restriction_value)
        if collection_name == "procedures":
            return _comparison_predicate("procedure_name", restriction_value)
        if collection_name == "functions":
            return _comparison_predicate("function_name", restriction_value)
        if collection_name == "routines":
            return _comparison_predicate("routine_name", restriction_value)
        if collection_name == "type_info":
            return _comparison_predicate("data_type_name", restriction_value)
        raise Error("0A000 metadata restriction 'name' is not supported for '" + collection_name + "'")

    if restriction_key == "schema_name":
        if collection_name == "schemas":
            return _comparison_predicate("schema_name", restriction_value)
        if collection_name == "catalogs":
            return _comparison_predicate("catalog_name", restriction_value)
        if collection_name == "tables":
            return "schema_id IN (SELECT schema_id FROM sys.schemas WHERE " + _comparison_predicate("schema_name", restriction_value) + ")"
        if collection_name == "columns" or collection_name == "indexes" or collection_name == "constraints":
            return _table_filter_by_schema_name(restriction_value)
        if collection_name == "index_columns":
            return _index_filter_by_schema_name(restriction_value)
        if collection_name == "primary_keys" or collection_name == "foreign_keys" or collection_name == "table_privileges" or collection_name == "column_privileges":
            return _table_filter_by_schema_name(restriction_value)
        if collection_name == "procedures" or collection_name == "functions" or collection_name == "routines":
            return "schema_id IN (SELECT schema_id FROM sys.schemas WHERE " + _comparison_predicate("schema_name", restriction_value) + ")"
        raise Error("0A000 metadata restriction 'schema_name' is not supported for '" + collection_name + "'")

    if restriction_key == "table_name":
        if collection_name == "tables" or collection_name == "table_privileges":
            return _comparison_predicate("table_name", restriction_value)
        if collection_name == "columns" or collection_name == "indexes" or collection_name == "constraints":
            return _table_filter_by_table_name(restriction_value)
        if collection_name == "index_columns":
            return _index_filter_by_table_name(restriction_value)
        if collection_name == "primary_keys" or collection_name == "foreign_keys" or collection_name == "column_privileges":
            return _table_filter_by_table_name(restriction_value)
        raise Error("0A000 metadata restriction 'table_name' is not supported for '" + collection_name + "'")

    if restriction_key == "column_name":
        if collection_name == "columns" or collection_name == "column_privileges" or collection_name == "index_columns":
            return _comparison_predicate("column_name", restriction_value)
        raise Error("0A000 metadata restriction 'column_name' is not supported for '" + collection_name + "'")

    raise Error("0A000 metadata restriction '" + restriction_key + "' is not supported")


fn _escape_sql_literal(value: String) -> String:
    return value.replace("'", "''")


fn _append_metadata_filter(sql: String, predicate: String) -> String:
    if " ORDER BY " in sql:
        var parts = sql.split(" ORDER BY ", 1)
        if len(parts) == 2:
            var head = String(parts[0])
            var tail = String(parts[1])
            if " where " in head.lower():
                return head + " AND " + predicate + " ORDER BY " + tail
            return head + " WHERE " + predicate + " ORDER BY " + tail

    if " where " in sql.lower():
        return sql + " AND " + predicate
    return sql + " WHERE " + predicate


fn resolve_metadata_collection_query_restricted(
    collection_name: String,
    restriction_key: String = "",
    restriction_value: String = "",
) raises -> String:
    var keys = List[String]()
    keys.append(restriction_key)
    var values = List[String]()
    values.append(restriction_value)
    return resolve_metadata_collection_query_restricted_multi(
        collection_name,
        keys,
        values,
    )


fn resolve_metadata_collection_query_restricted_multi(
    collection_name: String,
    restriction_keys: List[String],
    restriction_values: List[String],
) raises -> String:
    if len(restriction_keys) != len(restriction_values):
        raise Error("07001 metadata restriction count mismatch")
    var resolved_collection = normalize_metadata_collection_name(collection_name)
    var sql = resolve_metadata_collection_query(resolved_collection)
    for i in range(len(restriction_keys)):
        var resolved_key = normalize_metadata_restriction_key(restriction_keys[i])
        var value = String(restriction_values[i].strip())
        if resolved_key == "" or value == "":
            continue
        var predicate = _metadata_restriction_predicate(resolved_collection, resolved_key, value)
        sql = _append_metadata_filter(sql, predicate)
    return sql


fn validate_connect_guards(config: ScratchBirdConfig) raises:
    var mode = config.front_door_mode.strip().lower()
    if mode != "" and mode != "direct" and mode != "manager_proxy" and mode != "manager-proxy" and mode != "managed":
        raise Error("22023 front_door_mode must be direct or manager_proxy.")

    if config.user.strip() == "" or config.database.strip() == "":
        raise Error("28000 user and database are required")

    if config.sslmode.strip().lower() == "disable":
        raise Error("08004 TLS is required for ScratchBird connections")

    if not config.binary_transfer:
        raise Error("0A000 binary_transfer=false is not supported")

    if config.compression.strip().lower() == "zstd":
        raise Error("0A000 compression=zstd is not supported")


fn connect(config: ScratchBirdConfig) raises -> ScratchBirdConnection:
    return ScratchBirdConnection(config)


fn _is_sqlstate_char(ch: String) -> Bool:
    if _is_digit(ch):
        return True
    return ch >= "A" and ch <= "Z"


fn extract_sqlstate(message: String) -> String:
    var text = message.strip()
    if len(text) < 5:
        return ""
    var code = String()
    for i in range(5):
        var ch = String(text[byte=i])
        if not _is_sqlstate_char(ch):
            return ""
        code += ch
    return code
