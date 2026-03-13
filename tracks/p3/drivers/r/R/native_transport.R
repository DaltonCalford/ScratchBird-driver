# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

sb_tls_connect_native <- function(cfg) {
  root_cert <- if (is.null(cfg$sslrootcert)) "" else as.character(cfg$sslrootcert)
  cert_file <- if (is.null(cfg$sslcert)) "" else as.character(cfg$sslcert)
  key_file <- if (is.null(cfg$sslkey)) "" else as.character(cfg$sslkey)
  key_password <- if (is.null(cfg$sslpassword)) "" else as.character(cfg$sslpassword)

  .Call(
    C_sb_tls_connect,
    as.character(cfg$host),
    as.integer(cfg$port),
    tolower(as.character(cfg$sslmode)),
    root_cert,
    cert_file,
    key_file,
    key_password,
    as.integer(cfg$connect_timeout_ms),
    as.integer(cfg$socket_timeout_ms)
  )
}

sb_tls_write_native <- function(handle, data) {
  .Call(C_sb_tls_write, handle, data)
}

sb_tls_read_exact_native <- function(handle, n) {
  .Call(C_sb_tls_read_exact, handle, as.integer(n))
}

sb_tls_close_native <- function(handle) {
  invisible(.Call(C_sb_tls_close, handle))
}
