Scratchbird <- function() {
  new("ScratchbirdDriver")
}

setClass("ScratchbirdDriver", contains = "DBIDriver")
setClass("ScratchbirdConnection", contains = "DBIConnection", slots = list(ptr = "environment"))
setClass("ScratchbirdResult", contains = "DBIResult", slots = list(result = "environment"))

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
  new("ScratchbirdResult", result = result)
})

setMethod("dbFetch", "ScratchbirdResult", function(res, n = -1, ...) {
  sb_fetch(res@result, n)
})

setMethod("dbClearResult", "ScratchbirdResult", function(res, ...) {
  sb_clear_result(res@result)
  TRUE
})

setMethod("dbGetQuery", "ScratchbirdConnection", function(conn, statement, ...) {
  sb_get_query(conn@ptr$client, statement, ...)
})

setMethod("dbExecute", "ScratchbirdConnection", function(conn, statement, ...) {
  result <- sb_send_query(conn@ptr$client, statement, ...)
  sb_fetch_rows(result, -1)
  as.integer(result$rowcount)
})
