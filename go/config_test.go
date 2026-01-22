package scratchbird

import "testing"

func TestParseURI(t *testing.T) {
	cfg, err := ParseConfig("scratchbird://user:pass@localhost:3092/mydb?sslmode=require&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd")
	if err != nil {
		t.Fatalf("parse error: %v", err)
	}
	if cfg.Host != "localhost" || cfg.Port != 3092 {
		t.Fatalf("unexpected host/port: %s:%d", cfg.Host, cfg.Port)
	}
	if cfg.Database != "mydb" || cfg.User != "user" || cfg.Password != "pass" {
		t.Fatalf("unexpected credentials: %s/%s", cfg.User, cfg.Database)
	}
	if cfg.SSLMode != "require" || cfg.Application != "app" {
		t.Fatalf("unexpected ssl/app values")
	}
	if cfg.Compression != "zstd" || cfg.BinaryTransfer {
		t.Fatalf("unexpected compression/binary")
	}
}

func TestParseKeyValue(t *testing.T) {
	cfg, err := ParseConfig("Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;Timeout=5;Socket_Timeout=7")
	if err != nil {
		t.Fatalf("parse error: %v", err)
	}
	if cfg.Host != "server" || cfg.Port != 4000 {
		t.Fatalf("unexpected host/port: %s:%d", cfg.Host, cfg.Port)
	}
	if cfg.Database != "db" || cfg.User != "me" || cfg.Password != "secret" {
		t.Fatalf("unexpected credentials: %s/%s", cfg.User, cfg.Database)
	}
	if cfg.ConnectTimeout.Seconds() != 5 || cfg.SocketTimeout.Seconds() != 7 {
		t.Fatalf("unexpected timeouts: %v/%v", cfg.ConnectTimeout, cfg.SocketTimeout)
	}
}
