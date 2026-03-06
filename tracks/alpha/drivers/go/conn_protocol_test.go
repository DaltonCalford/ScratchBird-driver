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
	"fmt"
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
	if err != nil {
		t.Fatalf("expected disable mode to bypass TLS, got %v", err)
	}
}

func TestBuildTLSConfigRejectsInvalidRootCertPEM(t *testing.T) {
	caPath := filepath.Join(t.TempDir(), "invalid-ca.pem")
	if err := os.WriteFile(caPath, []byte("not-a-pem"), 0o600); err != nil {
		t.Fatalf("write temp CA file: %v", err)
	}

	conn := &Conn{config: defaultConfig()}
	conn.config.SSLRootCert = caPath

	_, err := conn.buildTLSConfig("verify-full")
	if err == nil {
		t.Fatalf("expected invalid PEM error")
	}
	if !strings.Contains(err.Error(), "failed to parse sslrootcert PEM") {
		t.Fatalf("expected parse PEM error, got %v", err)
	}
}

func TestConnectNormalizesProtocolAliasBeforeDial(t *testing.T) {
	conn := &Conn{config: defaultConfig()}
	conn.config.Protocol = "postgresql"
	conn.config.Host = "127.0.0.1"
	conn.config.Port = 1
	conn.config.SSLMode = "disable"

	err := conn.connect(context.Background())
	requireDriverError(t, err, ErrConnection, "08001")
	if conn.config.Protocol != "native" {
		t.Fatalf("expected protocol alias normalization to native, got %q", conn.config.Protocol)
	}
}

func TestConnectAllowsBinaryTransferFalseAndZstd(t *testing.T) {
	conn := &Conn{config: defaultConfig()}
	conn.config.Host = "127.0.0.1"
	conn.config.Port = 1
	conn.config.BinaryTransfer = false
	conn.config.Compression = "zstd"
	conn.config.SSLMode = "disable"

	err := conn.connect(context.Background())
	requireDriverError(t, err, ErrConnection, "08001")
}

func TestConnectRejectsManagerProxyWithoutTokenBeforeDial(t *testing.T) {
	conn := &Conn{config: defaultConfig()}
	conn.config.FrontDoorMode = "manager_proxy"

	err := conn.connect(context.Background())
	requireDriverError(t, err, ErrConnection, "08001")
	if conn.raw != nil {
		t.Fatalf("expected no network dial for missing manager token")
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

func TestHandshakeIncludesAuthPluginSelectionParams(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()

	errCh := make(chan error, 1)
	go func() {
		defer close(errCh)
		defer server.Close()

		msg, err := readMessage(server)
		if err != nil {
			errCh <- fmt.Errorf("read startup message: %w", err)
			return
		}
		if msg.header.typ != msgStartup {
			errCh <- fmt.Errorf("expected startup message, got %v", msg.header.typ)
			return
		}
		if len(msg.body) < 12 {
			errCh <- fmt.Errorf("startup payload too short: %d", len(msg.body))
			return
		}
		params := parseStartupParams(msg.body[12:])
		if params[authParamMethodID] != "scratchbird.auth.oidc" {
			errCh <- fmt.Errorf("unexpected auth method id: %q", params[authParamMethodID])
			return
		}
		if params[authParamPayloadJSON] != `{"aud":"sb"}` {
			errCh <- fmt.Errorf("unexpected auth payload json: %q", params[authParamPayloadJSON])
			return
		}
		if params[authParamPayloadB64] != "YWJj" {
			errCh <- fmt.Errorf("unexpected auth payload b64: %q", params[authParamPayloadB64])
			return
		}
		if params[authParamProviderProfile] != "corp" {
			errCh <- fmt.Errorf("unexpected auth provider profile: %q", params[authParamProviderProfile])
			return
		}

		authPayload := make([]byte, 20)
		attachment := [16]byte{0x11}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgAuthOk, attachmentID: attachment}, authPayload)); err != nil {
			errCh <- fmt.Errorf("write auth ok: %w", err)
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady, attachmentID: attachment}, testReadyPayload(0, 0, 0))); err != nil {
			errCh <- fmt.Errorf("write ready: %w", err)
			return
		}
		errCh <- nil
	}()

	cfg := defaultConfig()
	cfg.User = "alice"
	cfg.Password = "secret"
	cfg.Database = "db1"
	cfg.AuthMethodID = "scratchbird.auth.oidc"
	cfg.AuthPayloadJSON = `{"aud":"sb"}`
	cfg.AuthPayloadB64 = "YWJj"
	cfg.AuthProviderProfile = "corp"
	conn := &Conn{config: cfg, raw: client}
	if err := conn.handshake(context.Background()); err != nil {
		t.Fatalf("handshake failed: %v", err)
	}
	if err := <-errCh; err != nil {
		t.Fatal(err)
	}
}

func TestHandleAuthRequestSupportsAdditionalMethods(t *testing.T) {
	methods := []authMethod{
		authMD5,
		authCertificate,
		authGSSAPI,
		authSSPI,
		authLDAP,
		authSAML,
		authOIDC,
		authMFATOTP,
		authClusterPKI,
	}
	for _, method := range methods {
		t.Run(fmt.Sprintf("method_%d", method), func(t *testing.T) {
			client, server := net.Pipe()
			defer client.Close()

			errCh := make(chan error, 1)
			go func() {
				defer close(errCh)
				defer server.Close()
				msg, err := readMessage(server)
				if err != nil {
					errCh <- fmt.Errorf("read auth response: %w", err)
					return
				}
				if msg.header.typ != msgAuthResponse {
					errCh <- fmt.Errorf("expected auth response, got %v", msg.header.typ)
					return
				}
				if got := string(msg.body); got != "secret" {
					errCh <- fmt.Errorf("auth payload mismatch: got %q", got)
					return
				}
				errCh <- nil
			}()

			cfg := defaultConfig()
			cfg.Password = "secret"
			conn := &Conn{config: cfg, raw: client}
			if _, err := conn.handleAuthRequest(method, []byte("challenge"), nil); err != nil {
				t.Fatalf("handle auth request failed: %v", err)
			}
			if err := <-errCh; err != nil {
				t.Fatal(err)
			}
		})
	}
}

func TestHandleAuthContinueSupportsAdditionalMethods(t *testing.T) {
	methods := []authMethod{
		authMD5,
		authCertificate,
		authGSSAPI,
		authSSPI,
		authLDAP,
		authSAML,
		authOIDC,
		authMFATOTP,
		authClusterPKI,
	}
	for _, method := range methods {
		t.Run(fmt.Sprintf("method_%d", method), func(t *testing.T) {
			client, server := net.Pipe()
			defer client.Close()

			errCh := make(chan error, 1)
			go func() {
				defer close(errCh)
				defer server.Close()
				msg, err := readMessage(server)
				if err != nil {
					errCh <- fmt.Errorf("read auth response: %w", err)
					return
				}
				if msg.header.typ != msgAuthResponse {
					errCh <- fmt.Errorf("expected auth response, got %v", msg.header.typ)
					return
				}
				if got := string(msg.body); got != "secret" {
					errCh <- fmt.Errorf("auth payload mismatch: got %q", got)
					return
				}
				errCh <- nil
			}()

			cfg := defaultConfig()
			cfg.Password = "secret"
			conn := &Conn{config: cfg, raw: client}
			if _, err := conn.handleAuthContinue(method, []byte("challenge"), nil); err != nil {
				t.Fatalf("handle auth continue failed: %v", err)
			}
			if err := <-errCh; err != nil {
				t.Fatal(err)
			}
		})
	}
}

func parseStartupParams(payload []byte) map[string]string {
	params := map[string]string{}
	parts := strings.Split(string(payload), "\x00")
	for i := 0; i+1 < len(parts); i += 2 {
		key := parts[i]
		value := parts[i+1]
		if key == "" {
			break
		}
		params[key] = value
	}
	return params
}
