sb_substitute <- function(sql, params = NULL) {
  if (is.null(params) || length(params) == 0) return(sql)
  if (!is.null(names(params)) && any(names(params) != "")) {
    substitute_named(sql, params)
  } else {
    substitute_positional(sql, params)
  }
}

substitute_named <- function(sql, params) {
  out <- ""
  i <- 1
  while (i <= nchar(sql)) {
    ch <- substr(sql, i, i)
    if (ch == "'" && i + 1 <= nchar(sql)) {
      out <- paste0(out, ch)
      i <- i + 1
      while (i <= nchar(sql)) {
        out <- paste0(out, substr(sql, i, i))
        if (substr(sql, i, i) == "'" && (i + 1 > nchar(sql) || substr(sql, i + 1, i + 1) != "'")) {
          i <- i + 1
          break
        }
        if (substr(sql, i, i) == "'" && i + 1 <= nchar(sql) && substr(sql, i + 1, i + 1) == "'") {
          i <- i + 1
        }
        i <- i + 1
      }
      next
    }
    if ((ch == ":" || ch == "@") && i + 1 <= nchar(sql) && grepl("[A-Za-z]", substr(sql, i + 1, i + 1))) {
      j <- i + 1
      while (j <= nchar(sql) && grepl("[A-Za-z0-9_]", substr(sql, j, j))) {
        j <- j + 1
      }
      name <- substr(sql, i + 1, j - 1)
      if (!is.null(params[[name]])) {
        out <- paste0(out, format_param(params[[name]]))
      } else {
        out <- paste0(out, substr(sql, i, j - 1))
      }
      i <- j
      next
    }
    out <- paste0(out, ch)
    i <- i + 1
  }
  out
}

substitute_positional <- function(sql, params) {
  out <- ""
  i <- 1
  next_param <- 1
  while (i <= nchar(sql)) {
    ch <- substr(sql, i, i)
    if (ch == "$" && i + 1 <= nchar(sql) && grepl("[0-9]", substr(sql, i + 1, i + 1))) {
      j <- i + 1
      num <- 0
      while (j <= nchar(sql) && grepl("[0-9]", substr(sql, j, j))) {
        num <- num * 10 + as.integer(substr(sql, j, j))
        j <- j + 1
      }
      if (num > 0 && num <= length(params)) {
        out <- paste0(out, format_param(params[[num]]))
      } else {
        out <- paste0(out, substr(sql, i, j - 1))
      }
      i <- j
      next
    }
    if (ch == "?") {
      if (next_param <= length(params)) {
        out <- paste0(out, format_param(params[[next_param]]))
        next_param <- next_param + 1
      } else {
        out <- paste0(out, ch)
      }
      i <- i + 1
      next
    }
    if (ch == "'" && i + 1 <= nchar(sql)) {
      out <- paste0(out, ch)
      i <- i + 1
      while (i <= nchar(sql)) {
        out <- paste0(out, substr(sql, i, i))
        if (substr(sql, i, i) == "'" && (i + 1 > nchar(sql) || substr(sql, i + 1, i + 1) != "'")) {
          i <- i + 1
          break
        }
        if (substr(sql, i, i) == "'" && i + 1 <= nchar(sql) && substr(sql, i + 1, i + 1) == "'") {
          i <- i + 1
        }
        i <- i + 1
      }
      next
    }
    out <- paste0(out, ch)
    i <- i + 1
  }
  out
}

format_param <- function(value) {
  if (is.null(value) || length(value) == 0 || (is.atomic(value) && all(is.na(value)))) return("NULL")
  if (is.logical(value)) return(ifelse(value, "TRUE", "FALSE"))
  if (inherits(value, "Date")) return(paste0("DATE '", format(value, "%Y-%m-%d"), "'"))
  if (inherits(value, "POSIXct")) return(paste0("TIMESTAMP '", format(value, "%Y-%m-%d %H:%M:%S"), "'"))
  if (is.numeric(value)) return(as.character(value))
  if (is.raw(value)) return(paste0("X'", paste(sprintf("%02X", as.integer(value)), collapse = ""), "'"))
  if (is.list(value)) {
    inner <- vapply(value, format_param, character(1))
    return(paste0("ARRAY[", paste(inner, collapse = ", "), "]"))
  }
  if (is.character(value)) return(paste0("'", escape_string(value), "'"))
  paste0("'", escape_string(as.character(value)), "'")
}

escape_string <- function(value) {
  value <- gsub("\\\\", "\\\\\\\\", value)
  gsub("'", "''", value)
}
