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

#[test]
fn parse_manager_proxy_params() {
    let cfg = Config::from_dsn(
        "scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token&manager_client_flags=7",
    )
    .unwrap();
    assert_eq!(cfg.front_door_mode, "manager_proxy");
    assert_eq!(cfg.manager_auth_token, "token");
    assert_eq!(cfg.manager_client_flags, 7);
}

#[test]
fn parse_uri_precedence_latest_override_wins() {
    let cfg = Config::from_dsn(
        "scratchbird://user:pass@localhost:3092/pathdb?database=querydb&user=override&connect_timeout=1&connect_timeout=2",
    )
    .unwrap();
    assert_eq!(cfg.database, "querydb");
    assert_eq!(cfg.user, "override");
    assert_eq!(cfg.connect_timeout_ms, 2000);
}

#[test]
fn parse_key_value_precedence_latest_override_wins() {
    let cfg = Config::from_dsn("Host=first;Host=second;Port=3100;Port=4100;Database=a;Database=b")
        .unwrap();
    assert_eq!(cfg.host, "second");
    assert_eq!(cfg.port, 4100);
    assert_eq!(cfg.database, "b");
}

#[test]
fn parse_auth_plugin_selection_params_into_extra() {
    let cfg = Config::from_dsn(
        "scratchbird://user:pass@localhost:3092/mydb?auth_method_id=scratchbird.auth.password&auth_payload_json=%7B%22tenant%22%3A%22alpha%22%7D&auth_payload_b64=dGVzdA%3D%3D&auth_provider_profile=default",
    )
    .unwrap();
    assert_eq!(
        cfg.extra.get("auth_method_id").map(String::as_str),
        Some("scratchbird.auth.password")
    );
    assert_eq!(
        cfg.extra.get("auth_payload_json").map(String::as_str),
        Some("{\"tenant\":\"alpha\"}")
    );
    assert_eq!(
        cfg.extra.get("auth_payload_b64").map(String::as_str),
        Some("dGVzdA==")
    );
    assert_eq!(
        cfg.extra.get("auth_provider_profile").map(String::as_str),
        Some("default")
    );
}
