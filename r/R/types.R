SB_WIRE_BOOL <- 0x01
SB_WIRE_INT16 <- 0x02
SB_WIRE_INT32 <- 0x03
SB_WIRE_INT64 <- 0x04
SB_WIRE_FLOAT32 <- 0x05
SB_WIRE_FLOAT64 <- 0x06
SB_WIRE_DECIMAL <- 0x07
SB_WIRE_VARCHAR <- 0x08
SB_WIRE_CHAR <- 0x09
SB_WIRE_BYTEA <- 0x0A
SB_WIRE_DATE <- 0x0B
SB_WIRE_TIME <- 0x0C
SB_WIRE_TIMESTAMP <- 0x0D
SB_WIRE_TIMESTAMPTZ <- 0x0E
SB_WIRE_INTERVAL <- 0x0F
SB_WIRE_UUID <- 0x10
SB_WIRE_JSON <- 0x11
SB_WIRE_JSONB <- 0x12
SB_WIRE_ARRAY <- 0x13
SB_WIRE_VECTOR <- 0x16
SB_WIRE_MONEY <- 0x17
SB_WIRE_XML <- 0x18
SB_WIRE_INET <- 0x19
SB_WIRE_CIDR <- 0x1A
SB_WIRE_TSVECTOR <- 0x1C
SB_WIRE_TSQUERY <- 0x1D

decode_value <- function(wire_type, data) {
  if (is.null(data)) return(NA)
  if (length(data) == 0) return(NA)
  if (wire_type == SB_WIRE_BOOL) {
    return(as.logical(as.integer(data[1]) == 1))
  }
  if (wire_type == SB_WIRE_INT16) {
    return(readBin(data, integer(), size = 2, endian = "little"))
  }
  if (wire_type == SB_WIRE_INT32) {
    return(readBin(data, integer(), size = 4, endian = "little"))
  }
  if (wire_type == SB_WIRE_INT64) {
    return(readBin(data, numeric(), size = 8, endian = "little"))
  }
  if (wire_type == SB_WIRE_FLOAT32) {
    return(readBin(data, numeric(), size = 4, endian = "little"))
  }
  if (wire_type == SB_WIRE_FLOAT64) {
    return(readBin(data, numeric(), size = 8, endian = "little"))
  }
  if (wire_type == SB_WIRE_DECIMAL) {
    text <- rawToChar(data)
    num <- suppressWarnings(as.numeric(text))
    return(ifelse(is.na(num), text, num))
  }
  if (wire_type %in% c(SB_WIRE_VARCHAR, SB_WIRE_CHAR, SB_WIRE_JSON, SB_WIRE_JSONB, SB_WIRE_XML, SB_WIRE_TSVECTOR, SB_WIRE_TSQUERY, SB_WIRE_INET, SB_WIRE_CIDR)) {
    return(rawToChar(data))
  }
  if (wire_type == SB_WIRE_BYTEA) {
    return(data)
  }
  if (wire_type == SB_WIRE_DATE) {
    days <- readBin(data, integer(), size = 4, endian = "little")
    return(as.Date("2000-01-01") + days)
  }
  if (wire_type == SB_WIRE_TIME) {
    micros <- readBin(data, numeric(), size = 8, endian = "little")
    seconds <- micros / 1e6
    return(as.POSIXct(seconds, origin = "1970-01-01", tz = "UTC"))
  }
  if (wire_type %in% c(SB_WIRE_TIMESTAMP, SB_WIRE_TIMESTAMPTZ)) {
    micros <- readBin(data, numeric(), size = 8, endian = "little")
    seconds <- micros / 1e6
    return(as.POSIXct(seconds, origin = "1970-01-01", tz = "UTC"))
  }
  if (wire_type == SB_WIRE_INTERVAL) {
    months <- readBin(data[1:4], integer(), size = 4, endian = "little")
    days <- readBin(data[5:8], integer(), size = 4, endian = "little")
    micros <- readBin(data[9:16], numeric(), size = 8, endian = "little")
    return(list(months = months, days = days, micros = micros))
  }
  if (wire_type == SB_WIRE_UUID) {
    hex <- paste(sprintf("%02x", as.integer(data)), collapse = "")
    return(paste0(substr(hex, 1, 8), "-", substr(hex, 9, 12), "-", substr(hex, 13, 16), "-", substr(hex, 17, 20), "-", substr(hex, 21, 32)))
  }
  if (wire_type == SB_WIRE_ARRAY) {
    return(parse_array_literal(rawToChar(data)))
  }
  if (wire_type == SB_WIRE_VECTOR) {
    return(parse_vector_literal(rawToChar(data)))
  }
  if (wire_type == SB_WIRE_MONEY) {
    cents <- readBin(data, numeric(), size = 8, endian = "little")
    return(cents / 100)
  }
  data
}

parse_array_literal <- function(text) {
  trimmed <- trimws(text)
  if (trimmed == "" || trimmed == "{}") return(list())
  if (startsWith(trimmed, "{") && endsWith(trimmed, "}")) {
    trimmed <- substr(trimmed, 2, nchar(trimmed) - 1)
  }
  split_array_items(trimmed)
}

split_array_items <- function(text) {
  items <- list()
  depth <- 0
  buffer <- ""
  for (ch in strsplit(text, "", fixed = TRUE)[[1]]) {
    if (ch == "{") {
      depth <- depth + 1
      buffer <- paste0(buffer, ch)
    } else if (ch == "}") {
      depth <- max(0, depth - 1)
      buffer <- paste0(buffer, ch)
    } else if (ch == "," && depth == 0) {
      items[[length(items) + 1]] <- parse_array_item(buffer)
      buffer <- ""
    } else {
      buffer <- paste0(buffer, ch)
    }
  }
  if (buffer != "" || text != "") {
    items[[length(items) + 1]] <- parse_array_item(buffer)
  }
  items
}

parse_array_item <- function(token) {
  token <- trimws(token)
  if (toupper(token) == "NULL") return(NA)
  if (startsWith(token, "{") && endsWith(token, "}")) return(parse_array_literal(token))
  if (startsWith(token, "[") && endsWith(token, "]")) return(parse_vector_literal(token))
  if (tolower(token) == "true") return(TRUE)
  if (tolower(token) == "false") return(FALSE)
  num <- suppressWarnings(as.numeric(token))
  if (!is.na(num)) return(num)
  token
}

parse_vector_literal <- function(text) {
  trimmed <- trimws(text)
  if (startsWith(trimmed, "[") && endsWith(trimmed, "]")) {
    trimmed <- substr(trimmed, 2, nchar(trimmed) - 1)
  }
  if (trimmed == "") return(numeric())
  as.numeric(strsplit(trimmed, ",", fixed = TRUE)[[1]])
}
