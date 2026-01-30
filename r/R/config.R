# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
sb_config <- function(dsn = "") {
  cfg <- list(
    host = "localhost",
    port = 3092L,
    database = "",
    user = "",
    password = "",
    schema = "",
    role = "",
    sslmode = "require",
    sslrootcert = NULL,
    sslcert = NULL,
    sslkey = NULL,
    sslpassword = NULL,
    connect_timeout_ms = 30000L,
    socket_timeout_ms = 0L,
    application_name = "scratchbird_r",
    fetch_size = 0L,
    binary_transfer = TRUE,
    compression = "off",
    extra = list()
  )
  if (is.null(dsn) || trimws(dsn) == "") {
    return(cfg)
  }
  if (grepl("://", dsn)) {
    cfg <- parse_uri_dsn(cfg, dsn)
  } else {
    cfg <- parse_kv_dsn(cfg, dsn)
  }
  cfg
}

parse_uri_dsn <- function(cfg, dsn) {
  if (!startsWith(dsn, "scratchbird://")) stop("Unsupported DSN scheme")
  trimmed <- sub("^scratchbird://", "", dsn)
  pieces <- strsplit(trimmed, "\\?", fixed = FALSE)[[1]]
  authority_and_path <- pieces[1]
  query <- if (length(pieces) > 1) pieces[2] else ""
  path_split <- strsplit(authority_and_path, "/", fixed = TRUE)[[1]]
  authority <- path_split[1]
  if (length(path_split) > 1) {
    cfg$database <- utils::URLdecode(path_split[2])
  }
  user_host <- strsplit(authority, "@", fixed = TRUE)[[1]]
  host_part <- authority
  if (length(user_host) == 2) {
    userinfo <- user_host[1]
    host_part <- user_host[2]
    creds <- strsplit(userinfo, ":", fixed = TRUE)[[1]]
    cfg$user <- utils::URLdecode(creds[1])
    if (length(creds) > 1) cfg$password <- utils::URLdecode(creds[2])
  }
  host_port <- strsplit(host_part, ":", fixed = TRUE)[[1]]
  cfg$host <- utils::URLdecode(host_port[1])
  if (length(host_port) > 1) cfg$port <- as.integer(host_port[2])
  if (query != "") {
    params <- strsplit(query, "&", fixed = TRUE)[[1]]
    for (param in params) {
      if (param == "") next
      kv <- strsplit(param, "=", fixed = TRUE)[[1]]
      key <- utils::URLdecode(kv[1])
      value <- if (length(kv) > 1) utils::URLdecode(kv[2]) else ""
      cfg <- apply_param(cfg, key, value)
    }
  }
  cfg
}

parse_kv_dsn <- function(cfg, dsn) {
  sep <- if (grepl(";", dsn, fixed = TRUE)) ";" else " "
  tokens <- strsplit(dsn, sep, fixed = TRUE)[[1]]
  for (token in tokens) {
    token <- trimws(token)
    if (token == "") next
    kv <- strsplit(token, "=", fixed = TRUE)[[1]]
    if (length(kv) < 2) next
    key <- trimws(kv[1])
    value <- trimws(gsub("^\"|\"$", "", kv[2]))
    cfg <- apply_param(cfg, key, value)
  }
  cfg
}

apply_param <- function(cfg, key, value) {
  key <- tolower(key)
  if (key %in% c("host", "server", "data source", "datasource")) {
    cfg$host <- value
  } else if (key == "port") {
    cfg$port <- as.integer(value)
  } else if (key %in% c("database", "dbname", "initial catalog")) {
    cfg$database <- value
  } else if (key %in% c("user", "username", "user id", "uid")) {
    cfg$user <- value
  } else if (key %in% c("password", "pwd")) {
    cfg$password <- value
  } else if (key %in% c("schema", "search_path", "searchpath", "currentschema")) {
    cfg$schema <- value
  } else if (key == "role") {
    cfg$role <- value
  } else if (key %in% c("sslmode", "ssl mode")) {
    cfg$sslmode <- value
  } else if (key == "sslrootcert") {
    cfg$sslrootcert <- value
  } else if (key == "sslcert") {
    cfg$sslcert <- value
  } else if (key == "sslkey") {
    cfg$sslkey <- value
  } else if (key == "sslpassword") {
    cfg$sslpassword <- value
  } else if (key %in% c("connect_timeout", "connecttimeout", "timeout")) {
    cfg$connect_timeout_ms <- as.integer(value) * 1000L
  } else if (key %in% c("socket_timeout", "sockettimeout")) {
    cfg$socket_timeout_ms <- as.integer(value) * 1000L
  } else if (key %in% c("application_name", "applicationname")) {
    cfg$application_name <- value
  } else if (key %in% c("fetch_size", "fetchsize", "defaultrowfetchsize")) {
    cfg$fetch_size <- as.integer(value)
  } else if (key %in% c("binary_transfer", "binarytransfer")) {
    cfg$binary_transfer <- value %in% c("1", "true", "TRUE")
  } else if (key == "compression") {
    cfg$compression <- if (tolower(value) == "zstd") "zstd" else "off"
  } else {
    cfg$extra[[key]] <- value
  }
  cfg
}
