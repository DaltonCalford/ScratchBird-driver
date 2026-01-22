sb_connect <- function(dsn = "", ...) {
  cfg <- sb_config(dsn)
  if (length(list(...)) > 0) {
    overrides <- list(...)
    for (name in names(overrides)) {
      cfg <- apply_param(cfg, name, overrides[[name]])
    }
  }
  if (cfg$user == "" || cfg$database == "") stop("user and database are required")
  con <- sb_open_socket(cfg)
  client <- new.env(parent = emptyenv())
  client$con <- con
  client$cfg <- cfg
  client$session_id <- NULL
  client$server_name <- ""
  client$server_version <- ""
  client$autocommit <- TRUE
  client$in_transaction <- FALSE
  sb_handshake(client)
  sb_authenticate(client)
  client
}

sb_disconnect <- function(client) {
  if (!is.null(client$session_id)) {
    msg <- build_disconnect(client$session_id)
    try(sb_send_message(client, msg), silent = TRUE)
  }
  try(close(client$con), silent = TRUE)
  client$session_id <- NULL
}

sb_set_autocommit <- function(client, value) {
  client$autocommit <- isTRUE(value)
}

sb_is_valid <- function(client) {
  !is.null(client$session_id)
}

sb_query <- function(client, sql, params = NULL) {
  rendered <- sb_substitute(sql, params)
  sb_execute_query(client, rendered)
}

sb_get_query <- function(client, sql, params = NULL) {
  result <- sb_query(client, sql, params)
  sb_result_to_df(result)
}

sb_send_query <- function(client, sql, params = NULL) {
  rendered <- sb_substitute(sql, params)
  sb_begin_if_needed(client)
  msg <- build_query(client$session_id, rendered, 0)
  sb_send_message(client, msg)
  result <- sb_collect_result(client)
  result
}

sb_fetch <- function(result, n = -1) {
  if (is.null(result$rows)) return(data.frame())
  rows <- result$rows
  if (n >= 0 && n < length(rows)) {
    rows <- rows[seq_len(n)]
  }
  sb_rows_to_df(rows, result$columns)
}

sb_clear_result <- function(result) {
  result$rows <- list()
  result
}

sb_open_socket <- function(cfg) {
  sslmode <- tolower(cfg$sslmode)
  if (sslmode == "disable") {
    con <- socketConnection(cfg$host, cfg$port, blocking = TRUE, open = "r+b")
  } else {
    verify <- sslmode %in% c("verify-ca", "verify-full")
    if (!exists("ssl_connect", where = asNamespace("openssl"))) stop("openssl::ssl_connect is required for TLS")
    con <- openssl::ssl_connect(
      cfg$host,
      port = cfg$port,
      verify = verify,
      cert = cfg$sslcert,
      key = cfg$sslkey,
      ca = cfg$sslrootcert
    )
  }
  con
}

sb_handshake <- function(client) {
  msg <- build_connect_request(client$cfg$database, client$cfg$application_name, Sys.getpid())
  sb_send_message(client, msg)
  response <- sb_recv_message(client)
  if (response$type != SB_MSG_CONNECT_RESPONSE) stop("unexpected response to CONNECT_REQUEST")
  parsed <- parse_connect_response(response$payload)
  if (!parsed$success) stop(ifelse(parsed$error_msg == "", "connect failed", parsed$error_msg))
  client$session_id <- parsed$session_id
  client$server_name <- parsed$server_name
  client$server_version <- parsed$server_version
}

sb_authenticate <- function(client) {
  state <- sb_scram_client(client$cfg$user)
  first <- sb_scram_client_first(state)
  state <- first$state
  msg <- build_auth_request(client$session_id, client$cfg$user, SB_AUTH_SCRAM_SHA256, charToRaw(first$message))
  sb_send_message(client, msg)
  resp <- sb_recv_message(client)
  if (resp$type != SB_MSG_AUTH_RESPONSE) stop("unexpected response to AUTH_REQUEST")
  parsed <- parse_auth_response(resp$payload)
  if (parsed$status != 2) stop(ifelse(parsed$error_msg == "", "auth failed", parsed$error_msg))
  server_first <- rawToChar(parsed$extra)
  final <- sb_scram_handle_server_first(state, client$cfg$password, server_first)
  state <- final$state
  msg <- build_auth_request(client$session_id, client$cfg$user, SB_AUTH_SCRAM_SHA256, charToRaw(final$message))
  sb_send_message(client, msg)
  resp <- sb_recv_message(client)
  if (resp$type != SB_MSG_AUTH_RESPONSE) stop("unexpected response to SCRAM final")
  parsed <- parse_auth_response(resp$payload)
  if (parsed$status != 0) stop(ifelse(parsed$error_msg == "", "auth failed", parsed$error_msg))
  if (length(parsed$extra) > 0) {
    sb_scram_verify_server_final(state, rawToChar(parsed$extra))
  }
}

sb_begin_if_needed <- function(client) {
  if (!client$autocommit && !client$in_transaction) {
    msg <- build_begin(client$session_id, 0, FALSE)
    sb_send_message(client, msg)
    sb_drain_until_complete(client)
    client$in_transaction <- TRUE
  }
}

sb_execute_query <- function(client, sql) {
  sb_begin_if_needed(client)
  msg <- build_query(client$session_id, sql, 0)
  sb_send_message(client, msg)
  sb_collect_result(client)
}

sb_collect_result <- function(client) {
  columns <- list()
  rows <- list()
  rowcount <- -1
  rowcount_hint <- -1
  command_tag <- ""
  repeat {
    response <- sb_recv_message(client)
    type <- response$type
    payload <- response$payload
    if (type == SB_MSG_QUERY_ERROR) {
      sb_raise_query_error(payload)
    } else if (type == SB_MSG_QUERY_RESULT) {
      parsed <- parse_query_result(payload)
      rowcount_hint <- parsed$rows
    } else if (type == SB_MSG_ROW_DESCRIPTION) {
      columns <- parse_row_description(payload)
    } else if (type == SB_MSG_ROW_DATA) {
      values <- parse_row_data(payload)
      rows[[length(rows) + 1]] <- sb_decode_row(columns, values)
    } else if (type == SB_MSG_COMMAND_COMPLETE) {
      parsed <- parse_command_complete(payload)
      command_tag <- parsed$tag
      rowcount <- parsed$rows
    } else if (type == SB_MSG_END_RESULTS) {
      break
    }
  }
  if (rowcount < 0 && rowcount_hint >= 0) rowcount <- rowcount_hint
  if (rowcount < 0) rowcount <- length(rows)
  list(columns = columns, rows = rows, rowcount = rowcount, command_tag = command_tag)
}

sb_decode_row <- function(columns, values) {
  row <- vector("list", length(values))
  for (idx in seq_along(values)) {
    wire_type <- if (length(columns) >= idx) columns[[idx]]$wire_type else 0
    row[[idx]] <- decode_value(wire_type, values[[idx]]$data)
  }
  row
}

sb_raise_query_error <- function(payload) {
  parsed <- parse_query_error(payload)
  parts <- c()
  if (parsed$message != "") parts <- c(parts, parsed$message)
  if (parsed$detail != "") parts <- c(parts, paste0("DETAIL: ", parsed$detail))
  if (parsed$hint != "") parts <- c(parts, paste0("HINT: ", parsed$hint))
  message <- if (length(parts) == 0) "query failed" else paste(parts, collapse = "\n")
  if (parsed$sqlstate != "") message <- paste0("[", parsed$sqlstate, "] ", message)
  stop(message)
}

sb_send_message <- function(client, data) {
  writeBin(data, client$con)
}

sb_recv_message <- function(client) {
  header <- readBin(client$con, raw(), n = 12)
  if (length(header) != 12) stop("connection closed")
  parsed <- decode_header(header)
  payload <- if (parsed$length > 0) readBin(client$con, raw(), n = parsed$length) else raw()
  list(type = parsed$type, payload = payload)
}

sb_drain_until_complete <- function(client) {
  repeat {
    resp <- sb_recv_message(client)
    if (resp$type == SB_MSG_QUERY_ERROR) sb_raise_query_error(resp$payload)
    if (resp$type %in% c(SB_MSG_COMMAND_COMPLETE, SB_MSG_END_RESULTS)) break
  }
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
  sb_rows_to_df(result$rows, result$columns)
}
