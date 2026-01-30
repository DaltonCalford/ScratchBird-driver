// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
use scratchbird::Config;

#[test]
fn parse_uri() {
    let cfg = Config::from_dsn(
        "scratchbird://user:pass@localhost:3092/mydb?sslmode=require&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd",
    )
    .unwrap();
    assert_eq!(cfg.host, "localhost");
    assert_eq!(cfg.port, 3092);
    assert_eq!(cfg.database, "mydb");
    assert_eq!(cfg.user, "user");
    assert_eq!(cfg.password, "pass");
    assert_eq!(cfg.sslmode, "require");
    assert_eq!(cfg.connect_timeout_ms, 3000);
    assert_eq!(cfg.application_name, "app");
    assert_eq!(cfg.binary_transfer, false);
    assert_eq!(cfg.compression, "zstd");
}

#[test]
fn parse_key_value() {
    let cfg = Config::from_dsn("Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;Timeout=5;Socket_Timeout=7").unwrap();
    assert_eq!(cfg.host, "server");
    assert_eq!(cfg.port, 4000);
    assert_eq!(cfg.database, "db");
    assert_eq!(cfg.user, "me");
    assert_eq!(cfg.password, "secret");
    assert_eq!(cfg.connect_timeout_ms, 5000);
    assert_eq!(cfg.socket_timeout_ms, 7000);
}
