# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
sb_connect <- function(dsn = "", ...) {
  cfg <- sb_config(dsn)
  if (length(list(...)) > 0) {
    overrides <- list(...)
    for (name in names(overrides)) {
      cfg <- apply_param(cfg, name, overrides[[name]])
    }
  }
  cfg$protocol <- normalize_native_protocol(cfg$protocol)
  if (cfg$user == "" || cfg$database == "") stop("user and database are required")
  if (!isTRUE(cfg$binary_transfer)) stop("binary_transfer=false is not supported")
  if (tolower(cfg$compression) == "zstd") stop("compression=zstd is not supported")
  con <- sb_open_socket(cfg)
  client <- new.env(parent = emptyenv())
  client$con <- con
  client$cfg <- cfg
  client$attachment_id <- raw(16)
  client$txn_id <- 0
  client$sequence <- 0
  client$last_query_sequence <- 0
  client$parameters <- list()
  client$notification_handlers <- list()
  client$last_plan <- NULL
  client$last_sblr <- NULL
  client$prepared <- new.env(parent = emptyenv())
  client$autocommit <- TRUE
  sb_startup_and_auth(client)
  sb_apply_schema(client)
  client
}

sb_disconnect <- function(client) {
  try(close(client$con), silent = TRUE)
  client$con <- NULL
}

sb_set_autocommit <- function(client, value) {
  client$autocommit <- isTRUE(value)
}

sb_is_valid <- function(client) {
  !is.null(client$con)
}

sb_query <- function(client, sql, params = NULL) {
  normalized <- sb_normalize(sql, params)
  sb_execute_query(client, normalized$sql, normalized$params)
}

sb_get_query <- function(client, sql, params = NULL) {
  result <- sb_query(client, sql, params)
  sb_result_to_df(result)
}

sb_send_query <- function(client, sql, params = NULL) {
  normalized <- sb_normalize(sql, params)
  sb_execute_query(client, normalized$sql, normalized$params)
}

sb_fetch <- function(result, n = -1) {
  rows <- sb_fetch_rows(result, n)
  sb_rows_to_df(rows, result$columns)
}

sb_clear_result <- function(result) {
  result$done <- TRUE
  result
}

sb_cancel <- function(client) {
  payload <- build_cancel_payload(0L, client$last_query_sequence)
  sb_send_message(client, SB_MSG_CANCEL, payload, SB_MSG_FLAG_URGENT, FALSE)
}

sb_begin <- function(client, ...) {
  args <- list(...)
  flags <- 0L
  isolation <- SB_ISOLATION_READ_COMMITTED
  if ("isolation_level" %in% names(args)) {
    isolation <- args$isolation_level
    flags <- bitwOr(flags, SB_TXN_FLAG_HAS_ISOLATION)
  }
  if ("access_mode" %in% names(args)) flags <- bitwOr(flags, SB_TXN_FLAG_HAS_ACCESS)
  if ("deferrable" %in% names(args)) flags <- bitwOr(flags, SB_TXN_FLAG_HAS_DEFERRABLE)
  if ("wait" %in% names(args)) flags <- bitwOr(flags, SB_TXN_FLAG_HAS_WAIT)
  if ("timeout_ms" %in% names(args)) flags <- bitwOr(flags, SB_TXN_FLAG_HAS_TIMEOUT)
  if ("autocommit_mode" %in% names(args)) flags <- bitwOr(flags, SB_TXN_FLAG_HAS_AUTOCOMMIT)
  payload <- build_txn_begin_payload(
    flags,
    if (!is.null(args$conflict_action)) args$conflict_action else 0L,
    if (!is.null(args$autocommit_mode)) args$autocommit_mode else 0L,
    isolation,
    if (!is.null(args$access_mode)) args$access_mode else 0L,
    if (isTRUE(args$deferrable)) 1L else 0L,
    if (isTRUE(args$wait)) 1L else 0L,
    if (!is.null(args$timeout_ms)) args$timeout_ms else 0L
  )
  sb_send_message(client, SB_MSG_TXN_BEGIN, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_commit <- function(client, flags = 0L) {
  payload <- build_txn_commit_payload(flags)
  sb_send_message(client, SB_MSG_TXN_COMMIT, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_rollback <- function(client, flags = 0L) {
  payload <- build_txn_rollback_payload(flags)
  sb_send_message(client, SB_MSG_TXN_ROLLBACK, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_savepoint <- function(client, name) {
  payload <- build_txn_savepoint_payload(name)
  sb_send_message(client, SB_MSG_TXN_SAVEPOINT, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_release_savepoint <- function(client, name) {
  payload <- build_txn_release_payload(name)
  sb_send_message(client, SB_MSG_TXN_RELEASE, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_rollback_to_savepoint <- function(client, name) {
  payload <- build_txn_rollback_to_payload(name)
  sb_send_message(client, SB_MSG_TXN_ROLLBACK_TO, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_set_option <- function(client, name, value) {
  payload <- build_set_option_payload(name, value)
  sb_send_message(client, SB_MSG_SET_OPTION, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_ping <- function(client) {
  sb_send_message(client, SB_MSG_PING, raw(), 0L, FALSE)
  repeat {
    response <- sb_recv_message(client)
    if (sb_handle_async(client, response$type, response$payload)) next
    if (response$type == SB_MSG_PONG) return(invisible(NULL))
    if (response$type == SB_MSG_READY) {
      parsed <- parse_ready(response$payload)
      client$txn_id <- parsed$txn_id
      return(invisible(NULL))
    }
    if (response$type == SB_MSG_ERROR) sb_raise_query_error(response$payload)
  }
}

sb_terminate <- function(client) {
  if (is.null(client$con)) return(invisible(NULL))
  sb_send_message(client, SB_MSG_TERMINATE, raw(), 0L, FALSE)
  sb_disconnect(client)
}

sb_subscribe <- function(client, channel, subscribe_type = SB_SUB_TYPE_CHANNEL, filter_expr = "") {
  payload <- build_subscribe_payload(subscribe_type, channel, filter_expr)
  sb_send_message(client, SB_MSG_SUBSCRIBE, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_unsubscribe <- function(client, channel) {
  payload <- build_unsubscribe_payload(channel)
  sb_send_message(client, SB_MSG_UNSUBSCRIBE, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_execute_sblr <- function(client, sblr_hash, sblr_bytecode, params = list()) {
  encoded <- lapply(params, function(param) encode_param(param)$param)
  payload <- build_sblr_execute_payload(sblr_hash, sblr_bytecode, encoded)
  client$last_plan <- NULL
  client$last_sblr <- NULL
  client$last_query_sequence <- sb_send_message(client, SB_MSG_SBLR_EXECUTE, payload, 0L, FALSE)
  sb_send_message(client, SB_MSG_SYNC, raw(), 0L, FALSE)
  result <- new.env(parent = emptyenv())
  result$client <- client
  result$columns <- list()
  result$rowcount <- -1
  result$command_tag <- ""
  result$done <- FALSE
  result$page_size <- 0L
  result
}

sb_stream_control <- function(client, control_type, window_size = 0L, timeout_ms = 0L) {
  payload <- build_stream_control_payload(control_type, window_size, timeout_ms)
  sb_send_message(client, SB_MSG_STREAM_CONTROL, payload, 0L, FALSE)
}

sb_attach_create <- function(client, emulation_mode, db_name) {
  payload <- build_attach_create_payload(emulation_mode, db_name)
  sb_send_message(client, SB_MSG_ATTACH_CREATE, payload, 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_attach_detach <- function(client) {
  sb_send_message(client, SB_MSG_ATTACH_DETACH, raw(), 0L, FALSE)
  sb_drain_until_ready(client)
}

sb_attach_list <- function(client) {
  sb_send_message(client, SB_MSG_ATTACH_LIST, raw(), 0L, FALSE)
  sb_send_message(client, SB_MSG_SYNC, raw(), 0L, FALSE)
  result <- new.env(parent = emptyenv())
  result$client <- client
  result$columns <- list()
  result$rowcount <- -1
  result$command_tag <- ""
  result$done <- FALSE
  result$page_size <- 0L
  result
}

sb_on_notification <- function(client, handler) {
  client$notification_handlers[[length(client$notification_handlers) + 1]] <- handler
  invisible(NULL)
}

sb_get_last_plan <- function(client) {
  client$last_plan
}

sb_get_last_sblr <- function(client) {
  client$last_sblr
}

sb_open_socket <- function(cfg) {
  sslmode <- tolower(cfg$sslmode)
  if (sslmode == "disable") stop("TLS is required for ScratchBird connections")
  stop("TLS transport is not implemented in the R driver (missing TLS socket support). Use an external TLS wrapper.")
}

sb_startup_and_auth <- function(client) {
  features <- 0L
  if (tolower(client$cfg$compression) == "zstd") features <- bitwOr(features, SB_FEATURE_COMPRESSION)
  if (isTRUE(client$cfg$binary_transfer)) features <- bitwOr(features, SB_FEATURE_STREAMING)
  params <- list(database = client$cfg$database, user = client$cfg$user)
  if (client$cfg$role != "") params$role <- client$cfg$role
  if (client$cfg$application_name != "") params$application_name <- client$cfg$application_name
  startup <- build_startup_payload(features, params)
  sb_send_message(client, SB_MSG_STARTUP, startup, 0L, TRUE)

  scram <- NULL

  repeat {
    response <- sb_recv_message(client)
    type <- response$type
    payload <- response$payload
    if (type == SB_MSG_NEGOTIATE_VERSION) {
      next
    } else if (type == SB_MSG_AUTH_REQUEST) {
      parsed <- parse_auth_request(payload)
      if (parsed$method == SB_AUTH_OK) {
        next
      }
      if (parsed$method == SB_AUTH_PASSWORD) {
        sb_send_message(client, SB_MSG_AUTH_RESPONSE, charToRaw(client$cfg$password), 0L, TRUE)
        next
      }
      if (parsed$method == SB_AUTH_SCRAM_SHA256) {
        if (is.null(scram)) scram <- sb_scram_client(client$cfg$user)
        first <- sb_scram_client_first(scram)
        scram <- first$state
        sb_send_message(client, SB_MSG_AUTH_RESPONSE, charToRaw(first$message), 0L, TRUE)
        next
      }
      stop("Unsupported auth method")
    } else if (type == SB_MSG_AUTH_CONTINUE) {
      parsed <- parse_auth_continue(payload)
      if (parsed$method != SB_AUTH_SCRAM_SHA256 || is.null(scram)) stop("Unsupported auth continue")
      server_first <- rawToChar(parsed$data)
      final <- sb_scram_handle_server_first(scram, client$cfg$password, server_first)
      scram <- final$state
      sb_send_message(client, SB_MSG_AUTH_RESPONSE, charToRaw(final$message), 0L, TRUE)
      next
    } else if (type == SB_MSG_AUTH_OK) {
      parsed <- parse_auth_ok(payload)
      client$attachment_id <- response$attachment_id
      client$txn_id <- response$txn_id
      if (!is.null(scram) && length(parsed$server_info) > 0) {
        server_info <- rawToChar(parsed$server_info)
        if (startsWith(server_info, "v=")) sb_scram_verify_server_final(scram, server_info)
      }
      next
    } else if (type == SB_MSG_PARAMETER_STATUS) {
      parsed <- parse_parameter_status(payload)
      sb_handle_parameter_status(client, parsed$name, parsed$value)
      next
    } else if (type == SB_MSG_READY) {
      parsed <- parse_ready(payload)
      client$txn_id <- parsed$txn_id
      break
    } else if (type == SB_MSG_ERROR) {
      sb_raise_query_error(payload)
    }
  }
}

sb_apply_schema <- function(client) {
  schema <- trimws(client$cfg$schema)
  if (schema == "" || tolower(schema) == "public") return(invisible(NULL))
  statement <- build_schema_statement(schema)
  if (statement == "") return(invisible(NULL))
  sb_execute_query(client, statement)
  invisible(NULL)
}

build_schema_statement <- function(schema) {
  trimmed <- trimws(schema)
  if (trimmed == "") return("")
  if (grepl(",", trimmed, fixed = TRUE)) {
    parts <- trimws(strsplit(trimmed, ",", fixed = TRUE)[[1]])
    parts <- parts[parts != ""]
    if (length(parts) == 0) return("")
    quoted <- vapply(parts, quote_identifier, character(1))
    return(paste("SET SEARCH_PATH TO", paste(quoted, collapse = ", ")))
  }
  paste("SET SCHEMA", quote_identifier(trimmed))
}

quote_identifier <- function(name) {
  paste0('"', gsub('"', '""', name, fixed = TRUE), '"')
}

sb_execute_query <- function(client, sql, params = list()) {
  page_size <- if (!is.null(client$cfg$fetch_size) && client$cfg$fetch_size > 0) client$cfg$fetch_size else 0L
  if (length(params) == 0) {
    sb_send_simple_query(client, sql, page_size)
  } else {
    sb_send_extended_query(client, sql, params, page_size)
  }
  result <- new.env(parent = emptyenv())
  result$client <- client
  result$columns <- list()
  result$rowcount <- -1
  result$command_tag <- ""
  result$done <- FALSE
  result$page_size <- page_size
  result
}

sb_result_next_row <- function(result) {
  if (isTRUE(result$done)) return(NULL)
  client <- result$client
  repeat {
    response <- sb_recv_message(client)
    type <- response$type
    payload <- response$payload
    if (sb_handle_async(client, type, payload)) next
    if (type == SB_MSG_ERROR) {
      sb_raise_query_error(payload)
    } else if (type == SB_MSG_ROW_DESCRIPTION) {
      result$columns <- parse_row_description(payload)
    } else if (type == SB_MSG_DATA_ROW) {
      values <- parse_data_row(payload)
      return(sb_decode_row(result$columns, values))
    } else if (type == SB_MSG_COMMAND_COMPLETE) {
      parsed <- parse_command_complete(payload)
      result$command_tag <- parsed$tag
      result$rowcount <- parsed$rows
    } else if (type == SB_MSG_PARAMETER_STATUS) {
      parsed <- parse_parameter_status(payload)
      client$parameters[[parsed$name]] <- parsed$value
    } else if (type == SB_MSG_PORTAL_SUSPENDED) {
      exec_payload <- build_execute_payload("", result$page_size)
      client$last_query_sequence <- sb_send_message(client, SB_MSG_EXECUTE, exec_payload, 0L, FALSE)
    } else if (type == SB_MSG_READY) {
      parsed <- parse_ready(payload)
      client$txn_id <- parsed$txn_id
      result$done <- TRUE
      return(NULL)
    }
  }
}

sb_fetch_rows <- function(result, n = -1) {
  rows <- list()
  if (n == 0) return(rows)
  repeat {
    if (n > 0 && length(rows) >= n) break
    row <- sb_result_next_row(result)
    if (is.null(row)) break
    rows[[length(rows) + 1]] <- row
  }
  rows
}

sb_decode_row <- function(columns, values) {
  row <- vector("list", length(values))
  for (idx in seq_along(values)) {
    col <- if (length(columns) >= idx) columns[[idx]] else list(type_oid = 0L, format = SB_FORMAT_BINARY)
    row[[idx]] <- decode_value(col$type_oid, values[[idx]]$data, col$format)
  }
  row
}

sb_raise_query_error <- function(payload) {
  parsed <- parse_error_message(payload)
  parts <- c()
  if (parsed$message != "") parts <- c(parts, parsed$message)
  if (parsed$detail != "") parts <- c(parts, paste0("DETAIL: ", parsed$detail))
  if (parsed$hint != "") parts <- c(parts, paste0("HINT: ", parsed$hint))
  message <- if (length(parts) == 0) "query failed" else paste(parts, collapse = "\n")
  if (parsed$sqlstate != "") message <- paste0("[", parsed$sqlstate, "] ", message)
  stop(message)
}

parse_uuid_bytes <- function(value) {
  hex <- gsub("-", "", trimws(value), fixed = TRUE)
  if (nchar(hex) != 32 || !grepl("^[0-9A-Fa-f]+$", hex)) return(NULL)
  bytes <- raw(16)
  for (i in 0:15) {
    part <- substr(hex, i * 2 + 1, i * 2 + 2)
    bytes[i + 1] <- as.raw(strtoi(part, 16L))
  }
  bytes
}

sb_handle_parameter_status <- function(client, name, value) {
  if (name == "attachment_id") {
    parsed <- parse_uuid_bytes(value)
    if (!is.null(parsed)) client$attachment_id <- parsed
  }
  if (name == "current_txn_id") {
    parsed <- suppressWarnings(as.numeric(value))
    if (!is.na(parsed)) client$txn_id <- parsed
  }
  client$parameters[[name]] <- value
}

sb_handle_async <- function(client, type, payload) {
  if (type == SB_MSG_PARAMETER_STATUS) {
    parsed <- parse_parameter_status(payload)
    sb_handle_parameter_status(client, parsed$name, parsed$value)
    return(TRUE)
  }
  if (type == SB_MSG_NOTIFICATION) {
    notice <- parse_notification(payload)
    for (handler in client$notification_handlers) handler(notice)
    return(TRUE)
  }
  if (type == SB_MSG_QUERY_PLAN) {
    client$last_plan <- parse_query_plan(payload)
    return(TRUE)
  }
  if (type == SB_MSG_SBLR_COMPILED) {
    client$last_sblr <- parse_sblr_compiled(payload)
    return(TRUE)
  }
  FALSE
}

sb_drain_until_ready <- function(client) {
  repeat {
    response <- sb_recv_message(client)
    if (sb_handle_async(client, response$type, response$payload)) next
    if (response$type == SB_MSG_READY) {
      parsed <- parse_ready(response$payload)
      client$txn_id <- parsed$txn_id
      break
    }
    if (response$type == SB_MSG_ERROR) sb_raise_query_error(response$payload)
  }
}

sb_send_simple_query <- function(client, sql, max_rows = 0L) {
  flags <- if (isTRUE(client$cfg$binary_transfer)) 0x04L else 0L
  payload <- build_query_payload(sql, flags, max_rows, 0L)
  client$last_plan <- NULL
  client$last_sblr <- NULL
  client$last_query_sequence <- sb_send_message(client, SB_MSG_QUERY, payload, 0L, FALSE)
}

sb_send_extended_query <- function(client, sql, params, max_rows = 0L) {
  param_values <- list()
  param_types <- c()
  for (param in params) {
    encoded <- encode_param(param)
    param_values[[length(param_values) + 1]] <- encoded$param
    param_types <- c(param_types, encoded$oid)
  }
  parse_payload <- build_parse_payload("", sql, param_types)
  sb_send_message(client, SB_MSG_PARSE, parse_payload, 0L, FALSE)
  described <- sb_describe_statement(client, "")
  if (described >= 0 && described != length(param_types)) {
    stop("parameter count mismatch (07001)")
  }

  result_formats <- if (isTRUE(client$cfg$binary_transfer)) c(SB_FORMAT_BINARY) else c()
  bind_payload <- build_bind_payload("", "", param_values, result_formats)
  sb_send_message(client, SB_MSG_BIND, bind_payload, 0L, FALSE)

  exec_payload <- build_execute_payload("", max_rows)
  client$last_plan <- NULL
  client$last_sblr <- NULL
  client$last_query_sequence <- sb_send_message(client, SB_MSG_EXECUTE, exec_payload, 0L, FALSE)
  if (max_rows == 0L) {
    sb_send_message(client, SB_MSG_SYNC, raw(), 0L, FALSE)
  }
}

sb_describe_statement <- function(client, statement_name) {
  payload <- build_describe_payload(as.integer(charToRaw("S")), statement_name)
  sb_send_message(client, SB_MSG_DESCRIBE, payload, 0L, FALSE)
  sb_send_message(client, SB_MSG_SYNC, raw(), 0L, FALSE)
  param_count <- -1L
  repeat {
    response <- sb_recv_message(client)
    if (sb_handle_async(client, response$type, response$payload)) next
    type <- response$type
    payload <- response$payload
    if (type == SB_MSG_ERROR) {
      sb_raise_query_error(payload)
    } else if (type == SB_MSG_PARAMETER_DESCRIPTION) {
      param_count <- length(parse_parameter_description(payload))
    } else if (type == SB_MSG_READY) {
      parsed <- parse_ready(payload)
      client$txn_id <- parsed$txn_id
      break
    }
  }
  param_count
}

sb_send_message <- function(client, type, payload, flags = 0L, force_zero = FALSE) {
  sequence <- client$sequence
  client$sequence <- client$sequence + 1
  attachment <- if (force_zero) raw(16) else client$attachment_id
  txn_id <- if (force_zero) 0 else client$txn_id
  data <- encode_message(type, payload, flags, sequence, attachment, txn_id)
  writeBin(data, client$con)
  sequence
}

sb_recv_message <- function(client) {
  header <- readBin(client$con, raw(), n = SB_HEADER_SIZE)
  if (length(header) != SB_HEADER_SIZE) stop("connection closed")
  parsed <- decode_header(header)
  payload <- if (parsed$length > 0) readBin(client$con, raw(), n = parsed$length) else raw()
  list(
    type = parsed$type,
    flags = parsed$flags,
    payload = payload,
    sequence = parsed$sequence,
    attachment_id = parsed$attachment_id,
    txn_id = parsed$txn_id
  )
}

sb_rows_to_df <- function(rows, columns) {
  if (length(rows) == 0) return(data.frame())
  names <- vapply(columns, function(col) col$name, character(1))
  cols <- vector("list", length(columns))
  for (i in seq_along(columns)) {
    cols[[i]] <- vapply(rows, function(row) row[[i]], FUN.VALUE = NA)
  }
  names(cols) <- names
  as.data.frame(cols, stringsAsFactors = FALSE)
}

sb_result_to_df <- function(result) {
  rows <- sb_fetch_rows(result, -1)
  sb_rows_to_df(rows, result$columns)
}
