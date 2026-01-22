SB_MAGIC <- as.integer(0x42444253)
SB_VERSION <- as.integer(0x0100)
SB_MAX_MESSAGE_SIZE <- 16 * 1024 * 1024

SB_MSG_CONNECT_REQUEST <- 0x01
SB_MSG_CONNECT_RESPONSE <- 0x02
SB_MSG_DISCONNECT <- 0x03
SB_MSG_AUTH_REQUEST <- 0x10
SB_MSG_AUTH_RESPONSE <- 0x11
SB_MSG_QUERY <- 0x20
SB_MSG_QUERY_RESULT <- 0x21
SB_MSG_QUERY_ERROR <- 0x22
SB_MSG_QUERY_CANCEL <- 0x23
SB_MSG_PREPARE <- 0x30
SB_MSG_PREPARE_RESPONSE <- 0x31
SB_MSG_EXECUTE <- 0x32
SB_MSG_CLOSE_STATEMENT <- 0x33
SB_MSG_DESCRIBE <- 0x34
SB_MSG_DESCRIBE_RESPONSE <- 0x35
SB_MSG_BEGIN <- 0x40
SB_MSG_COMMIT <- 0x41
SB_MSG_ROLLBACK <- 0x42
SB_MSG_ROW_DESCRIPTION <- 0x50
SB_MSG_ROW_DATA <- 0x51
SB_MSG_END_RESULTS <- 0x52
SB_MSG_COMMAND_COMPLETE <- 0x53

SB_AUTH_SCRAM_SHA256 <- 2

pack_u32 <- function(x) writeBin(as.integer(x), raw(), size = 4, endian = "little")
pack_u16 <- function(x) writeBin(as.integer(x), raw(), size = 2, endian = "little")
pack_u8 <- function(x) writeBin(as.integer(x), raw(), size = 1, endian = "little")

read_u32 <- function(data, offset) {
  as.integer(readBin(data[offset:(offset + 3)], integer(), size = 4, endian = "little", signed = FALSE))
}

read_u16 <- function(data, offset) {
  as.integer(readBin(data[offset:(offset + 1)], integer(), size = 2, endian = "little", signed = FALSE))
}

read_u8 <- function(data, offset) {
  as.integer(readBin(data[offset], integer(), size = 1, signed = FALSE))
}

encode_message <- function(type, payload, flags = 0) {
  length <- length(payload)
  header <- c(pack_u32(SB_MAGIC), pack_u16(SB_VERSION), pack_u8(type), pack_u8(flags), pack_u32(length))
  c(header, payload)
}

decode_header <- function(data) {
  if (length(data) != 12) stop("Invalid header length")
  magic <- read_u32(data, 1)
  if (magic != SB_MAGIC) stop("Invalid protocol magic")
  length <- read_u32(data, 9)
  if (length > SB_MAX_MESSAGE_SIZE) stop("Payload too large")
  type <- read_u8(data, 7)
  flags <- read_u8(data, 8)
  list(type = type, flags = flags, length = length)
}

build_connect_request <- function(database, client_name, pid) {
  payload <- c(pack_u16(SB_VERSION), pack_u16(0), pack_u32(pid))
  payload <- c(payload, write_null(database, 256))
  payload <- c(payload, write_null(client_name, 64))
  payload <- c(payload, write_null("1.0.0", 32))
  encode_message(SB_MSG_CONNECT_REQUEST, payload)
}

parse_connect_response <- function(payload) {
  if (length(payload) < 1 + 2 + 2 + 16 + 64 + 32) stop("Connect response truncated")
  status <- payload[1]
  session_id <- payload[6:21]
  server_name <- read_null(payload[22:85])
  server_version <- read_null(payload[86:117])
  error_msg <- ""
  offset <- 118
  if (status != 0 && offset + 1 <= length(payload)) {
    msg_len <- read_u16(payload, offset)
    offset <- offset + 2
    if (offset + msg_len - 1 <= length(payload)) {
      error_msg <- rawToChar(payload[offset:(offset + msg_len - 1)])
    }
  }
  list(success = status == 0, session_id = session_id, server_name = server_name, server_version = server_version, error_msg = error_msg)
}

build_auth_request <- function(session_id, username, method, payload) {
  if (length(session_id) != 16) stop("sessionId must be 16 bytes")
  buffer <- c(session_id, write_null(username, 64), pack_u8(method), pack_u16(length(payload)), payload)
  encode_message(SB_MSG_AUTH_REQUEST, buffer)
}

parse_auth_response <- function(payload) {
  if (length(payload) < 1 + 4 + 256) stop("Auth response truncated")
  status <- payload[1]
  user_id <- read_u32(payload, 2)
  error_msg <- read_null(payload[6:261])
  extra <- if (length(payload) > 261) payload[262:length(payload)] else raw()
  list(status = status, user_id = user_id, error_msg = error_msg, extra = extra)
}

build_query <- function(session_id, sql, flags = 0) {
  if (length(session_id) != 16) stop("sessionId must be 16 bytes")
  sql_bytes <- charToRaw(sql)
  payload <- c(session_id, pack_u32(length(sql_bytes)), pack_u8(flags), sql_bytes)
  encode_message(SB_MSG_QUERY, payload)
}

parse_row_description <- function(payload) {
  if (length(payload) < 2) stop("Row description truncated")
  count <- read_u16(payload, 1)
  offset <- 3
  columns <- vector("list", count)
  for (idx in seq_len(count)) {
    name_len <- read_u16(payload, offset)
    offset <- offset + 2
    name <- rawToChar(payload[offset:(offset + name_len - 1)])
    offset <- offset + name_len
    wire_type <- read_u8(payload, offset)
    offset <- offset + 1
    modifier <- read_u32(payload, offset)
    offset <- offset + 4
    format <- read_u16(payload, offset)
    offset <- offset + 2
    columns[[idx]] <- list(name = name, wire_type = wire_type, type_modifier = modifier, format = format)
  }
  columns
}

parse_row_data <- function(payload) {
  if (length(payload) < 2) stop("Row data truncated")
  count <- read_u16(payload, 1)
  offset <- 3
  values <- vector("list", count)
  for (idx in seq_len(count)) {
    len <- read_u32(payload, offset)
    offset <- offset + 4
    if (bitwAnd(len, 0x80000000) != 0) {
      values[[idx]] <- list(data = NULL)
      next
    }
    data <- payload[offset:(offset + len - 1)]
    offset <- offset + len
    values[[idx]] <- list(data = data)
  }
  values
}

parse_command_complete <- function(payload) {
  if (length(payload) < 64 + 8) stop("Command complete truncated")
  tag <- read_null(payload[1:64])
  rows <- readBin(payload[65:72], numeric(), size = 8, endian = "little")
  list(tag = tag, rows = as.numeric(rows))
}

parse_query_result <- function(payload) {
  if (length(payload) < 1 + 4 + 8) stop("Query result truncated")
  status <- payload[1]
  count <- read_u32(payload, 2)
  rows <- readBin(payload[6:13], numeric(), size = 8, endian = "little")
  list(status = status, count = count, rows = as.numeric(rows))
}

parse_query_error <- function(payload) {
  if (length(payload) < 4 + 6 + 2 + 2 + 2) stop("Query error truncated")
  offset <- 1
  code <- read_u32(payload, offset)
  offset <- offset + 4
  sqlstate <- read_null(payload[offset:(offset + 5)])
  offset <- offset + 6
  msg_len <- read_u16(payload, offset)
  offset <- offset + 2
  detail_len <- read_u16(payload, offset)
  offset <- offset + 2
  hint_len <- read_u16(payload, offset)
  offset <- offset + 2
  message <- if (msg_len > 0) rawToChar(payload[offset:(offset + msg_len - 1)]) else ""
  offset <- offset + msg_len
  detail <- if (detail_len > 0) rawToChar(payload[offset:(offset + detail_len - 1)]) else ""
  offset <- offset + detail_len
  hint <- if (hint_len > 0) rawToChar(payload[offset:(offset + hint_len - 1)]) else ""
  list(code = code, sqlstate = sqlstate, message = message, detail = detail, hint = hint)
}

build_begin <- function(session_id, isolation = 0, read_only = FALSE) {
  payload <- c(session_id, pack_u8(isolation), pack_u8(if (read_only) 1 else 0))
  encode_message(SB_MSG_BEGIN, payload)
}

build_commit <- function(session_id) {
  encode_message(SB_MSG_COMMIT, session_id)
}

build_rollback <- function(session_id) {
  encode_message(SB_MSG_ROLLBACK, session_id)
}

build_disconnect <- function(session_id) {
  encode_message(SB_MSG_DISCONNECT, session_id)
}

write_null <- function(value, length) {
  data <- charToRaw(value)
  if (length(data) >= length) {
    data <- data[1:(length - 1)]
  }
  c(data, raw(length - length(data)))
}

read_null <- function(data) {
  idx <- which(data == as.raw(0x00))
  if (length(idx) == 0) idx <- length(data) + 1
  rawToChar(data[1:(idx[1] - 1)])
}
