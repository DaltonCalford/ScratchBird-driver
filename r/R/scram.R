# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
sb_scram_client <- function(username) {
  nonce <- openssl::base64_encode(openssl::rand_bytes(18))
  list(
    username = username,
    client_nonce = nonce,
    client_first_bare = "",
    server_signature = NULL
  )
}

sb_scram_client_first <- function(state) {
  escaped <- gsub("=", "=3D", gsub(",", "=2C", state$username, fixed = TRUE), fixed = TRUE)
  state$client_first_bare <- paste0("n=", escaped, ",r=", state$client_nonce)
  list(state = state, message = paste0("n,,", state$client_first_bare))
}

sb_scram_handle_server_first <- function(state, password, server_first) {
  attrs <- parse_scram_attrs(server_first)
  nonce <- attrs$r
  if (is.null(nonce) || !startsWith(nonce, state$client_nonce)) stop("SCRAM server nonce mismatch")
  salt_b64 <- attrs$s
  iter_str <- attrs$i
  if (is.null(salt_b64) || is.null(iter_str)) stop("SCRAM server-first missing fields")
  iterations <- as.integer(iter_str)
  salt <- openssl::base64_decode(salt_b64)
  if (!exists("pbkdf2", where = asNamespace("openssl"))) stop("openssl::pbkdf2 is required for SCRAM")
  salted <- openssl::pbkdf2(password, salt, iterations, keylen = 32, algo = "sha256")
  client_key <- openssl::hmac(salted, "Client Key", algo = "sha256")
  stored_key <- openssl::sha256(client_key)
  client_final_without_proof <- paste0("c=biws,r=", nonce)
  auth_message <- paste(state$client_first_bare, server_first, client_final_without_proof, sep = ",")
  client_signature <- openssl::hmac(stored_key, auth_message, algo = "sha256")
  client_proof <- bitwXor(as.integer(client_key), as.integer(client_signature))
  server_key <- openssl::hmac(salted, "Server Key", algo = "sha256")
  state$server_signature <- openssl::hmac(server_key, auth_message, algo = "sha256")
  proof_b64 <- openssl::base64_encode(as.raw(client_proof))
  list(state = state, message = paste0(client_final_without_proof, ",p=", proof_b64))
}

sb_scram_verify_server_final <- function(state, server_final) {
  attrs <- parse_scram_attrs(server_final)
  verifier <- attrs$v
  if (is.null(verifier)) stop("SCRAM server-final missing verifier")
  expected <- openssl::base64_encode(state$server_signature)
  if (verifier != expected) stop("SCRAM server signature mismatch")
  TRUE
}

parse_scram_attrs <- function(message) {
  attrs <- list()
  parts <- strsplit(message, ",", fixed = TRUE)[[1]]
  for (part in parts) {
    if (part == "") next
    kv <- strsplit(part, "=", fixed = TRUE)[[1]]
    if (length(kv) < 2) next
    attrs[[kv[1]]] <- kv[2]
  }
  attrs
}
