# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
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

setMethod("dbCanConnect", "ScratchbirdDriver", function(drv, dsn = "", ...) {
  client <- tryCatch(
    sb_connect(dsn, ...),
    error = function(e) NULL
  )
  if (is.null(client)) {
    return(FALSE)
  }
  try(sb_disconnect(client), silent = TRUE)
  TRUE
})

setMethod("dbDisconnect", "ScratchbirdConnection", function(conn, ...) {
  sb_disconnect(conn@ptr$client)
  TRUE
})

setMethod("dbIsValid", "ScratchbirdConnection", function(dbObj, ...) {
  sb_is_valid(dbObj@ptr$client)
})

setMethod("dbBegin", "ScratchbirdConnection", function(conn, ...) {
  sb_begin(conn@ptr$client, ...)
  sb_set_autocommit(conn@ptr$client, FALSE)
  TRUE
})

setMethod("dbCommit", "ScratchbirdConnection", function(conn, ...) {
  sb_commit(conn@ptr$client, ...)
  sb_set_autocommit(conn@ptr$client, TRUE)
  TRUE
})

setMethod("dbRollback", "ScratchbirdConnection", function(conn, ...) {
  sb_rollback(conn@ptr$client, ...)
  sb_set_autocommit(conn@ptr$client, TRUE)
  TRUE
})

setMethod("dbSendQuery", c("ScratchbirdConnection", "character"), function(conn, statement, ...) {
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

setMethod("dbGetRowsAffected", "ScratchbirdResult", function(res, ...) {
  as.numeric(res@result$rowcount)
})

setMethod("dbGetQuery", c("ScratchbirdConnection", "character"), function(conn, statement, ...) {
  sb_get_query(conn@ptr$client, statement, ...)
})

setMethod("dbExecute", c("ScratchbirdConnection", "character"), function(conn, statement, ...) {
  result <- sb_send_query(conn@ptr$client, statement, ...)
  sb_fetch_rows(result, -1)
  as.integer(result$rowcount)
})
