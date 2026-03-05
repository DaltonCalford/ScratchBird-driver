# ScratchBird Mojo Native Bootstrap Module
# Copyright (c) 2025-2026 Dalton Calford

comptime METADATA_SCHEMAS_QUERY = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
comptime METADATA_TABLES_QUERY = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
comptime METADATA_COLUMNS_QUERY = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"


struct ScratchBirdConfig:
    var dsn: String
    var user: String
    var database: String
    var front_door_mode: String
    var sslmode: String
    var binary_transfer: Bool
    var compression: String

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


struct ScratchBirdConnection:
    var user: String
    var database: String
    var front_door_mode: String

    fn __init__(out self, config: ScratchBirdConfig) raises:
        validate_connect_guards(config)
        self.user = config.user
        self.database = config.database
        self.front_door_mode = config.front_door_mode

    fn query(self, sql: String) raises -> Int:
        var normalized = sql.strip().lower()
        if normalized == "select 1":
            return 1
        if normalized == "select * from type_coverage":
            return 1
        raise Error("unsupported query in native bootstrap")

    fn close(self):
        _ = self

    fn query_metadata(self, collection_name: String) raises -> String:
        _ = self
        return resolve_metadata_collection_query(collection_name)


fn _as_bool(value: String) -> Bool:
    var normalized = value.strip().lower()
    return normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on"


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


fn _metadata_alias(value: String) -> String:
    if value == "schema" or value == "schemas":
        return "schemas"
    if value == "table" or value == "tables":
        return "tables"
    if value == "column" or value == "columns":
        return "columns"
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
        raise Error("metadata collection '" + raw + "' is not supported")
    return resolved


fn resolve_metadata_collection_query(collection_name: String) raises -> String:
    var resolved = normalize_metadata_collection_name(collection_name)
    if resolved == "schemas":
        return METADATA_SCHEMAS_QUERY
    if resolved == "tables":
        return METADATA_TABLES_QUERY
    if resolved == "columns":
        return METADATA_COLUMNS_QUERY
    raise Error("metadata collection '" + collection_name + "' is not supported")


fn validate_connect_guards(config: ScratchBirdConfig) raises:
    var mode = config.front_door_mode.strip().lower()
    if mode != "" and mode != "direct" and mode != "manager_proxy" and mode != "manager-proxy" and mode != "managed":
        raise Error("front_door_mode must be direct or manager_proxy.")

    if config.user.strip() == "" or config.database.strip() == "":
        raise Error("user and database are required")

    if config.sslmode.strip().lower() == "disable":
        raise Error("TLS is required for ScratchBird connections")

    if not config.binary_transfer:
        raise Error("binary_transfer=false is not supported")

    if config.compression.strip().lower() == "zstd":
        raise Error("compression=zstd is not supported")


fn connect(config: ScratchBirdConfig) raises -> ScratchBirdConnection:
    return ScratchBirdConnection(config)
