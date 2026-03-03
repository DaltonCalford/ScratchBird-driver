// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"context"
	"encoding/binary"
	"errors"
	"net"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func requireDriverError(t *testing.T, err error, kind ErrorKind, sqlState string) {
	t.Helper()
	if err == nil {
		t.Fatalf("expected error")
	}
	var sbErr *Error
	if !errors.As(err, &sbErr) {
		t.Fatalf("expected *Error, got %T (%v)", err, err)
	}
	if sbErr.Kind != kind {
		t.Fatalf("expected error kind %q, got %q", kind, sbErr.Kind)
	}
	if sbErr.SQLState != sqlState {
		t.Fatalf("expected SQLSTATE %q, got %q", sqlState, sbErr.SQLState)
	}
}

func TestApplyTLSDisableModeTrimsWhitespace(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()

	conn := &Conn{
		config: defaultConfig(),
		raw:    client,
	}
	conn.config.SSLMode = "  DISABLE  "

	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	err := conn.applyTLS(ctx)
	requireDriverError(t, err, ErrConnection, "08001")
	if !strings.Contains(err.Error(), "TLS is required") {
		t.Fatalf("expected TLS-required error, got %v", err)
	}
}

func TestBuildTLSConfigRejectsInvalidRootCertPEM(t *testing.T) {
	caPath := filepath.Join(t.TempDir(), "invalid-ca.pem")
	if err := os.WriteFile(caPath, []byte("not-a-pem"), 0o600); err != nil {
		t.Fatalf("write temp CA file: %v", err)
	}

	conn := &Conn{config: defaultConfig()}
	conn.config.SSLRootCert = caPath

	_, err := conn.buildTLSConfig()
	if err == nil {
		t.Fatalf("expected invalid PEM error")
	}
	if !strings.Contains(err.Error(), "failed to parse sslrootcert PEM") {
		t.Fatalf("expected parse PEM error, got %v", err)
	}
}

func TestConnectRejectsUnsupportedProtocolBeforeDial(t *testing.T) {
	conn := &Conn{config: defaultConfig()}
	conn.config.Protocol = "postgresql"

	err := conn.connect(context.Background())
	requireDriverError(t, err, ErrNotSupported, "0A000")
	if conn.raw != nil {
		t.Fatalf("expected no network dial for unsupported protocol")
	}
}

func TestConnectRejectsBinaryTransferFalseBeforeDial(t *testing.T) {
	conn := &Conn{config: defaultConfig()}
	conn.config.BinaryTransfer = false

	err := conn.connect(context.Background())
	requireDriverError(t, err, ErrNotSupported, "0A000")
	if conn.raw != nil {
		t.Fatalf("expected no network dial for unsupported binary_transfer setting")
	}
}

func TestDecodeHeaderRejectsPayloadTooLarge(t *testing.T) {
	header := make([]byte, headerSize)
	copy(header[0:4], []byte("SBWP"))
	header[4] = protocolMajor
	header[5] = protocolMinor
	header[6] = byte(msgQuery)
	binary.LittleEndian.PutUint32(header[8:12], uint32(maxMessageSize+1))

	if _, err := decodeHeader(header); err == nil {
		t.Fatalf("expected payload-too-large error")
	}
}

func TestParseAuthContinueRejectsTruncatedPayload(t *testing.T) {
	payload := []byte{
		byte(authScramSha256), 1, 0, 0,
		5, 0, 0, 0, // data length claims 5 bytes
		'a', 'b', // only 2 bytes available
	}
	if _, _, _, err := parseAuthContinue(payload); err == nil {
		t.Fatalf("expected auth continue truncation error")
	}
}

func TestApplyAuthPluginSelectionRejectsInvalidNamespace(t *testing.T) {
	err := ApplyAuthPluginSelection(map[string]string{}, AuthPluginSelection{
		MethodID: "custom.auth.password",
	})
	if err == nil {
		t.Fatalf("expected auth namespace validation error")
	}
}

func TestApplyAuthPluginSelectionSetsParams(t *testing.T) {
	params := map[string]string{}
	err := ApplyAuthPluginSelection(params, AuthPluginSelection{
		MethodID:        "scratchbird.auth.password",
		PayloadJSON:     `{"otp":"123456"}`,
		PayloadB64:      "YWJj",
		ProviderProfile: "native_v3",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if params[authParamMethodID] != "scratchbird.auth.password" {
		t.Fatalf("unexpected method id: %q", params[authParamMethodID])
	}
	if params[authParamPayloadJSON] != `{"otp":"123456"}` {
		t.Fatalf("unexpected payload json: %q", params[authParamPayloadJSON])
	}
	if params[authParamPayloadB64] != "YWJj" {
		t.Fatalf("unexpected payload b64: %q", params[authParamPayloadB64])
	}
	if params[authParamProviderProfile] != "native_v3" {
		t.Fatalf("unexpected provider profile: %q", params[authParamProviderProfile])
	}
}
