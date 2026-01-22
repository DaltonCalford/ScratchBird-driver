Scratchbird <- function() {
  new("ScratchbirdDriver")
}

setClass("ScratchbirdDriver", contains = "DBIDriver")
setClass("ScratchbirdConnection", contains = "DBIConnection", slots = list(ptr = "environment"))
setClass("ScratchbirdResult", contains = "DBIResult", slots = list(rows = "list", columns = "list", rowcount = "numeric", idx = "numeric"))

setMethod("dbConnect", "ScratchbirdDriver", function(drv, dsn = "", ...) {
  client <- sb_connect(dsn, ...)
  env <- new.env(parent = emptyenv())
  env$client <- client
  new("ScratchbirdConnection", ptr = env)
})

setMethod("dbDisconnect", "ScratchbirdConnection", function(conn, ...) {
  sb_disconnect(conn@ptr$client)
  TRUE
})

setMethod("dbIsValid", "ScratchbirdConnection", function(conn, ...) {
  sb_is_valid(conn@ptr$client)
})

setMethod("dbSendQuery", "ScratchbirdConnection", function(conn, statement, ...) {
  result <- sb_send_query(conn@ptr$client, statement, ...)
  new("ScratchbirdResult",
      rows = result$rows,
      columns = result$columns,
      rowcount = result$rowcount,
      idx = 0)
})

setMethod("dbFetch", "ScratchbirdResult", function(res, n = -1, ...) {
  rows <- res@rows
  if (n >= 0 && n < length(rows)) {
    rows <- rows[seq_len(n)]
  }
  sb_rows_to_df(rows, res@columns)
})

setMethod("dbClearResult", "ScratchbirdResult", function(res, ...) {
  res@rows <- list()
  TRUE
})

setMethod("dbGetQuery", "ScratchbirdConnection", function(conn, statement, ...) {
  sb_get_query(conn@ptr$client, statement, ...)
})

setMethod("dbExecute", "ScratchbirdConnection", function(conn, statement, ...) {
  result <- sb_send_query(conn@ptr$client, statement, ...)
  as.integer(result$rowcount)
})
