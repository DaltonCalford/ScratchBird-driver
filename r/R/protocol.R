SB_MAGIC <- as.integer(0x53425750)
SB_VERSION_MAJOR <- 1L
SB_VERSION_MINOR <- 1L
SB_HEADER_SIZE <- 40L
SB_MAX_MESSAGE_SIZE <- 1024L * 1024L * 1024L

SB_MSG_STARTUP <- 0x01
SB_MSG_AUTH_RESPONSE <- 0x02
SB_MSG_QUERY <- 0x03
SB_MSG_PARSE <- 0x04
SB_MSG_BIND <- 0x05
SB_MSG_DESCRIBE <- 0x06
SB_MSG_EXECUTE <- 0x07
SB_MSG_CLOSE <- 0x08
SB_MSG_SYNC <- 0x09
SB_MSG_FLUSH <- 0x0A
SB_MSG_CANCEL <- 0x0B
SB_MSG_COPY_DATA <- 0x0D
SB_MSG_COPY_DONE <- 0x0E
SB_MSG_COPY_FAIL <- 0x0F

SB_MSG_AUTH_REQUEST <- 0x40
SB_MSG_AUTH_OK <- 0x41
SB_MSG_AUTH_CONTINUE <- 0x42
SB_MSG_READY <- 0x43
SB_MSG_ROW_DESCRIPTION <- 0x44
SB_MSG_DATA_ROW <- 0x45
SB_MSG_COMMAND_COMPLETE <- 0x46
SB_MSG_EMPTY_QUERY <- 0x47
SB_MSG_ERROR <- 0x48
SB_MSG_NOTICE <- 0x49
SB_MSG_PARSE_COMPLETE <- 0x4A
SB_MSG_BIND_COMPLETE <- 0x4B
SB_MSG_CLOSE_COMPLETE <- 0x4C
SB_MSG_PORTAL_SUSPENDED <- 0x4D
SB_MSG_NO_DATA <- 0x4E
SB_MSG_PARAMETER_STATUS <- 0x4F
SB_MSG_PARAMETER_DESCRIPTION <- 0x50
SB_MSG_COPY_IN_RESPONSE <- 0x51
SB_MSG_COPY_OUT_RESPONSE <- 0x52
SB_MSG_COPY_BOTH_RESPONSE <- 0x53
SB_MSG_NOTIFICATION <- 0x54
SB_MSG_NEGOTIATE_VERSION <- 0x56
SB_MSG_STREAM_READY <- 0x59
SB_MSG_STREAM_DATA <- 0x5A
SB_MSG_STREAM_END <- 0x5B
SB_MSG_TXN_STATUS <- 0x5C
SB_MSG_PONG <- 0x5D

SB_AUTH_OK <- 0L
SB_AUTH_PASSWORD <- 1L
SB_AUTH_MD5 <- 2L
SB_AUTH_SCRAM_SHA256 <- 3L
SB_AUTH_CERTIFICATE <- 4L
SB_AUTH_GSSAPI <- 5L
SB_AUTH_SSPI <- 6L
SB_AUTH_LDAP <- 7L
SB_AUTH_SAML <- 8L
SB_AUTH_OIDC <- 9L
SB_AUTH_MFA_TOTP <- 10L
SB_AUTH_CLUSTER_PKI <- 11L

SB_MSG_FLAG_COMPRESSED <- 0x01
SB_MSG_FLAG_CONTINUED <- 0x02
SB_MSG_FLAG_FINAL <- 0x04
SB_MSG_FLAG_URGENT <- 0x08
SB_MSG_FLAG_ENCRYPTED <- 0x10
SB_MSG_FLAG_CHECKSUM <- 0x20

SB_FEATURE_COMPRESSION <- 1L
SB_FEATURE_STREAMING <- 2L
SB_FEATURE_SBLR <- 4L
SB_FEATURE_FEDERATION <- 8L
SB_FEATURE_NOTIFICATIONS <- 16L
SB_FEATURE_QUERY_PLAN <- 32L
SB_FEATURE_BATCH <- 64L
SB_FEATURE_PIPELINE <- 128L
SB_FEATURE_BINARY_COPY <- 256L
SB_FEATURE_SAVEPOINTS <- 512L
SB_FEATURE_2PC <- 1024L
SB_FEATURE_CHECKSUMS <- 2048L

pack_u64 <- function(x) writeBin(as.numeric(x), raw(), size = 8, endian = "little")
pack_u32 <- function(x) writeBin(as.integer(x), raw(), size = 4, endian = "little")
pack_u16 <- function(x) writeBin(as.integer(x), raw(), size = 2, endian = "little")
pack_u8 <- function(x) writeBin(as.integer(x), raw(), size = 1, endian = "little")
pack_i32 <- function(x) writeBin(as.integer(x), raw(), size = 4, endian = "little")

read_u64 <- function(data, offset) {
  readBin(data[offset:(offset + 7)], numeric(), size = 8, endian = "little", signed = FALSE)
}

read_u32 <- function(data, offset) {
  as.integer(readBin(data[offset:(offset + 3)], integer(), size = 4, endian = "little", signed = FALSE))
}

read_u16 <- function(data, offset) {
  as.integer(readBin(data[offset:(offset + 1)], integer(), size = 2, endian = "little", signed = FALSE))
}

read_u8 <- function(data, offset) {
  as.integer(readBin(data[offset], integer(), size = 1, signed = FALSE))
}

read_i32 <- function(data, offset) {
  as.integer(readBin(data[offset:(offset + 3)], integer(), size = 4, endian = "little", signed = TRUE))
}

encode_message <- function(type, payload, flags = 0L, sequence = 0L, attachment_id = raw(16), txn_id = 0) {
  payload <- if (is.null(payload)) raw() else payload
  length <- length(payload)
  header <- c(
    pack_u32(SB_MAGIC),
    pack_u8(SB_VERSION_MAJOR),
    pack_u8(SB_VERSION_MINOR),
    pack_u8(type),
    pack_u8(flags),
    pack_u32(length),
    pack_u32(sequence)
  )
  attachment <- attachment_id
  if (length(attachment) < 16) attachment <- c(attachment, raw(16 - length(attachment)))
  if (length(attachment) > 16) attachment <- attachment[1:16]
  c(header, attachment, pack_u64(txn_id), payload)
}

decode_header <- function(data) {
  if (length(data) != SB_HEADER_SIZE) stop("Invalid header length")
  magic <- read_u32(data, 1)
  if (magic != SB_MAGIC) stop("Invalid protocol magic")
  major <- read_u8(data, 5)
  minor <- read_u8(data, 6)
  if (major != SB_VERSION_MAJOR || minor != SB_VERSION_MINOR) stop("Unsupported protocol version")
  msg_type <- read_u8(data, 7)
  flags <- read_u8(data, 8)
  length <- read_u32(data, 9)
  if (length > SB_MAX_MESSAGE_SIZE) stop("Payload too large")
  sequence <- read_u32(data, 13)
  attachment_id <- data[17:32]
  txn_id <- read_u64(data, 33)
  list(type = msg_type, flags = flags, length = length, sequence = sequence, attachment_id = attachment_id, txn_id = txn_id)
}

build_startup_payload <- function(features, params) {
  buf <- c(pack_u8(SB_VERSION_MAJOR), pack_u8(SB_VERSION_MINOR), pack_u16(0))
  buf <- c(buf, pack_u64(features))
  buf <- c(buf, build_param_list(params))
  buf
}

build_param_list <- function(params) {
  buf <- raw()
  for (name in names(params)) {
    buf <- c(buf, charToRaw(name), as.raw(0x00), charToRaw(as.character(params[[name]])), as.raw(0x00))
  }
  c(buf, as.raw(0x00))
}

parse_auth_request <- function(payload) {
  if (length(payload) < 4) stop("Auth request truncated")
  method <- payload[1]
  data <- if (length(payload) > 4) payload[5:length(payload)] else raw()
  list(method = as.integer(method), data = data)
}

parse_auth_continue <- function(payload) {
  if (length(payload) < 8) stop("Auth continue truncated")
  method <- payload[1]
  stage <- payload[2]
  data_len <- read_u32(payload, 5)
  if (8 + data_len > length(payload)) stop("Auth continue truncated")
  data <- if (data_len > 0) payload[9:(8 + data_len)] else raw()
  list(method = as.integer(method), stage = as.integer(stage), data = data)
}

parse_auth_ok <- function(payload) {
  if (length(payload) < 20) stop("Auth ok truncated")
  session_id <- payload[1:16]
  info_len <- read_u32(payload, 17)
  if (20 + info_len > length(payload)) stop("Auth ok truncated")
  info <- if (info_len > 0) payload[21:(20 + info_len)] else raw()
  list(session_id = session_id, server_info = info)
}

build_query_payload <- function(sql, flags = 0L, max_rows = 0L, timeout_ms = 0L) {
  c(pack_u32(flags), pack_u32(max_rows), pack_u32(timeout_ms), charToRaw(sql), as.raw(0x00))
}

build_parse_payload <- function(statement_name, sql, param_types) {
  name_bytes <- charToRaw(statement_name)
  sql_bytes <- charToRaw(sql)
  payload <- c(pack_u32(length(name_bytes)), name_bytes, pack_u32(length(sql_bytes)), sql_bytes)
  payload <- c(payload, pack_u16(length(param_types)), pack_u16(0))
  if (length(param_types) > 0) {
    for (oid in param_types) {
      payload <- c(payload, pack_u32(oid))
    }
  }
  payload
}

build_bind_payload <- function(portal_name, statement_name, params, result_formats) {
  portal_bytes <- charToRaw(portal_name)
  stmt_bytes <- charToRaw(statement_name)
  payload <- c(pack_u32(length(portal_bytes)), portal_bytes, pack_u32(length(stmt_bytes)), stmt_bytes)
  payload <- c(payload, pack_u16(length(params)))
  if (length(params) > 0) {
    for (param in params) {
      payload <- c(payload, pack_u16(param$format))
    }
  }
  payload <- c(payload, pack_u16(length(params)), pack_u16(0))
  if (length(params) > 0) {
    for (param in params) {
      if (isTRUE(param$is_null)) {
        payload <- c(payload, pack_i32(-1L))
      } else {
        data <- param$data
        payload <- c(payload, pack_i32(length(data)), data)
      }
    }
  }
  payload <- c(payload, pack_u16(length(result_formats)))
  if (length(result_formats) > 0) {
    for (fmt in result_formats) {
      payload <- c(payload, pack_u16(fmt))
    }
  }
  payload
}

build_execute_payload <- function(portal_name, max_rows = 0L) {
  portal_bytes <- charToRaw(portal_name)
  c(pack_u32(length(portal_bytes)), portal_bytes, pack_u32(max_rows))
}

build_cancel_payload <- function(cancel_type, target_sequence) {
  c(pack_u32(cancel_type), pack_u32(target_sequence))
}

parse_ready <- function(payload) {
  if (length(payload) < 20) stop("Ready truncated")
  status <- payload[1]
  txn_id <- read_u64(payload, 5)
  visibility <- read_u64(payload, 13)
  list(status = as.integer(status), txn_id = txn_id, visibility = visibility)
}

parse_parameter_status <- function(payload) {
  if (length(payload) < 8) stop("Parameter status truncated")
  offset <- 1
  name_len <- read_u32(payload, offset)
  offset <- offset + 4
  name <- rawToChar(payload[offset:(offset + name_len - 1)])
  offset <- offset + name_len
  value_len <- read_u32(payload, offset)
  offset <- offset + 4
  value <- rawToChar(payload[offset:(offset + value_len - 1)])
  list(name = name, value = value)
}

parse_row_description <- function(payload) {
  if (length(payload) < 4) stop("Row description truncated")
  offset <- 1
  count <- read_u16(payload, offset)
  offset <- offset + 4
  columns <- vector("list", count)
  for (idx in seq_len(count)) {
    name_len <- read_u32(payload, offset)
    offset <- offset + 4
    name <- rawToChar(payload[offset:(offset + name_len - 1)])
    offset <- offset + name_len
    table_oid <- read_u32(payload, offset)
    offset <- offset + 4
    column_index <- read_u16(payload, offset)
    offset <- offset + 2
    type_oid <- read_u32(payload, offset)
    offset <- offset + 4
    type_size <- readBin(payload[offset:(offset + 1)], integer(), size = 2, endian = "little", signed = TRUE)
    offset <- offset + 2
    type_modifier <- readBin(payload[offset:(offset + 3)], integer(), size = 4, endian = "little", signed = TRUE)
    offset <- offset + 4
    format <- read_u8(payload, offset)
    offset <- offset + 1
    nullable <- read_u8(payload, offset) == 1
    offset <- offset + 1
    offset <- offset + 2
    columns[[idx]] <- list(
      name = name,
      table_oid = table_oid,
      column_index = column_index,
      type_oid = type_oid,
      type_size = type_size,
      type_modifier = type_modifier,
      format = format,
      nullable = nullable
    )
  }
  columns
}

parse_data_row <- function(payload) {
  if (length(payload) < 4) stop("Row data truncated")
  offset <- 1
  count <- read_u16(payload, offset)
  offset <- offset + 2
  null_bytes <- read_u16(payload, offset)
  offset <- offset + 2
  null_bitmap <- if (null_bytes > 0) payload[offset:(offset + null_bytes - 1)] else raw()
  offset <- offset + null_bytes
  values <- vector("list", count)
  for (idx in seq_len(count)) {
    byte_index <- as.integer((idx - 1) / 8)
    bit_index <- (idx - 1) %% 8
    is_null <- byte_index < null_bytes && bitwAnd(as.integer(null_bitmap[byte_index + 1]), bitwShiftL(1, bit_index)) != 0
    if (is_null) {
      values[[idx]] <- list(data = NULL)
      next
    }
    len <- read_i32(payload, offset)
    offset <- offset + 4
    if (len < 0) {
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
  if (length(payload) < 20) stop("Command complete truncated")
  command_type <- payload[1]
  rows <- read_u64(payload, 5)
  last_id <- read_u64(payload, 13)
  tag_bytes <- if (length(payload) > 20) payload[21:length(payload)] else raw()
  tag <- if (length(tag_bytes) > 0) strsplit(rawToChar(tag_bytes), "\0", fixed = TRUE)[[1]][1] else ""
  list(command_type = as.integer(command_type), rows = rows, last_id = last_id, tag = tag)
}

parse_error_message <- function(payload) {
  offset <- 1
  severity <- ""
  sqlstate <- ""
  message <- ""
  detail <- ""
  hint <- ""
  while (offset <= length(payload)) {
    field <- as.integer(payload[offset])
    offset <- offset + 1
    if (field == 0) break
    start <- offset
    while (offset <= length(payload) && payload[offset] != as.raw(0x00)) {
      offset <- offset + 1
    }
    if (offset > length(payload)) break
    value <- rawToChar(payload[start:(offset - 1)])
    offset <- offset + 1
    if (field == as.integer(charToRaw("S"))) severity <- value
    if (field == as.integer(charToRaw("C"))) sqlstate <- value
    if (field == as.integer(charToRaw("M"))) message <- value
    if (field == as.integer(charToRaw("D"))) detail <- value
    if (field == as.integer(charToRaw("H"))) hint <- value
  }
  list(severity = severity, sqlstate = sqlstate, message = message, detail = detail, hint = hint)
}
