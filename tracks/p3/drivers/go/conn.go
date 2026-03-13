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
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"database/sql"
	"database/sql/driver"
	"encoding/base64"
	"encoding/binary"
	"encoding/hex"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	formatText   uint16 = 0
	formatBinary uint16 = 1
)

const (
	managerProtocolMagic   uint32 = 0x42444253 // SBDB
	managerProtocolVersion uint16 = 0x0101
	managerHeaderSize             = 12
	managerMaxPayloadSize  uint32 = 16 * 1024 * 1024
	mcpProtocolVersion     uint16 = 0x0100

	mcpMsgConnectResponse uint8 = 0x02
	mcpMsgAuthChallenge   uint8 = 0x12
	mcpMsgAuthResponse    uint8 = 0x11
	mcpMsgStatusResponse  uint8 = 0x64
	mcpMsgHello           uint8 = 0x65
	mcpMsgAuthStart       uint8 = 0x66
	mcpMsgAuthContinue    uint8 = 0x67
	mcpMsgDbConnect       uint8 = 0x69
	mcpAuthMethodToken    uint8 = 4
)

type Conn struct {
	config               Config
	raw                  net.Conn
	mu                   sync.Mutex
	closed               bool
	attachmentID         [16]byte
	txnID                uint64
	sequence             uint32
	authed               bool
	pending              []protocolMessage
	params               map[string]string
	notificationHandlers []func(notificationMessage)
	lastPlan             *queryPlan
	lastSblr             *sblrCompiled
	connID               string
	circuitBreaker       *CircuitBreaker
	telemetry            *TelemetryCollector
	keepaliveMgr         *KeepaliveManager
	keepaliveTracker     *KeepaliveTracker
	leakDetector         *LeakDetector
	leakGuard            *LeakDetectionGuard
}

func (c *Conn) connect(ctx context.Context) error {
	if c.raw != nil {
		return nil
	}
	c.initResilience()
	protocol, ok := normalizeNativeProtocol(c.config.Protocol)
	if !ok {
		return &Error{Kind: ErrNotSupported, Message: "only protocol=native is supported; connect to the native parser listener/port", SQLState: "0A000"}
	}
	c.config.Protocol = protocol
	frontDoorMode, ok := normalizeFrontDoorMode(c.config.FrontDoorMode)
	if !ok {
		return &Error{Kind: ErrNotSupported, Message: "front_door_mode must be direct or manager_proxy", SQLState: "0A000"}
	}
	c.config.FrontDoorMode = frontDoorMode
	sslMode, ok := normalizeSSLMode(c.config.SSLMode)
	if !ok {
		return &Error{Kind: ErrNotSupported, Message: "sslmode must be disable, require, verify-ca, or verify-full", SQLState: "0A000"}
	}
	c.config.SSLMode = sslMode
	compressionMode, ok := normalizeCompressionMode(c.config.Compression)
	if !ok {
		return &Error{Kind: ErrNotSupported, Message: "compression must be off or zstd", SQLState: "0A000"}
	}
	c.config.Compression = compressionMode
	if c.config.FrontDoorMode == "manager_proxy" && c.config.ManagerAuthToken == "" {
		return &Error{Kind: ErrConnection, Message: "manager_proxy mode requires manager_auth_token", SQLState: "08001"}
	}
	address := fmt.Sprintf("%s:%d", c.config.Host, c.config.Port)
	dialer := &net.Dialer{Timeout: c.config.ConnectTimeout}
	conn, err := dialer.DialContext(ctx, "tcp", address)
	if err != nil {
		return &Error{Kind: ErrConnection, Message: err.Error(), SQLState: "08001"}
	}
	c.raw = conn
	if err := c.applyTLS(ctx); err != nil {
		_ = c.raw.Close()
		return err
	}
	if c.config.FrontDoorMode == "manager_proxy" {
		if err := c.performManagerConnect(ctx); err != nil {
			_ = c.raw.Close()
			return err
		}
	}
	if err := c.handshake(ctx); err != nil {
		_ = c.raw.Close()
		return err
	}
	if err := c.applySchema(ctx); err != nil {
		_ = c.raw.Close()
		return err
	}
	c.registerKeepalive()
	return nil
}

func (c *Conn) initResilience() {
	if c.connID == "" {
		c.connID = fmt.Sprintf("conn-%p", c)
	}
	if c.circuitBreaker == nil {
		c.circuitBreaker = NewCircuitBreaker(DefaultCircuitBreakerConfig())
	}
	if c.telemetry == nil {
		c.telemetry = NewTelemetryCollector(DefaultTelemetryConfig())
	}
	if c.keepaliveMgr == nil {
		c.keepaliveMgr = NewKeepaliveManager(DefaultKeepaliveConfig())
	}
	if c.leakDetector == nil {
		c.leakDetector = NewLeakDetector(DefaultLeakDetectionConfig())
	}
	if c.leakGuard == nil && c.leakDetector != nil {
		c.leakGuard = NewLeakDetectionGuard(c.connID, c.leakDetector, map[string]string{
			"driver": "go",
		})
	}
}

func (c *Conn) registerKeepalive() {
	if c.keepaliveMgr == nil || c.keepaliveTracker != nil {
		return
	}
	c.keepaliveTracker = c.keepaliveMgr.Register(c.connID, func() error {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		return c.Ping(ctx)
	})
}

func (c *Conn) beginOperation(op string, sql string) (*SpanContext, error) {
	if c.circuitBreaker != nil && !c.circuitBreaker.AllowRequest() {
		return nil, ErrCircuitOpen
	}
	if c.keepaliveTracker != nil {
		c.keepaliveTracker.MarkActive()
	}
	var span *SpanContext
	if c.telemetry != nil {
		span = c.telemetry.StartSpan(op)
		if span != nil && sql != "" {
			span.Attributes["sql"] = SanitizeQuery(sql)
		}
	}
	return span, nil
}

func (c *Conn) endOperation(span *SpanContext, success bool) {
	if c.circuitBreaker != nil {
		if success {
			c.circuitBreaker.RecordSuccess()
		} else {
			c.circuitBreaker.RecordFailure()
		}
	}
	if c.telemetry != nil {
		c.telemetry.EndSpan(span, success)
	}
}

func (c *Conn) applyTLS(ctx context.Context) error {
	mode := strings.ToLower(strings.TrimSpace(c.config.SSLMode))
	if mode == "" {
		mode = "require"
	}
	if mode == "disable" {
		return nil
	}
	tlsConfig, err := c.buildTLSConfig(mode)
	if err != nil {
		return err
	}
	tlsConn := tls.Client(c.raw, tlsConfig)
	if err := tlsConn.HandshakeContext(ctx); err != nil {
		return &Error{Kind: ErrConnection, Message: "TLS handshake failed: " + err.Error(), SQLState: "08001"}
	}
	c.raw = tlsConn
	return nil
}

func (c *Conn) buildTLSConfig(mode string) (*tls.Config, error) {
	cfg := &tls.Config{
		MinVersion: tls.VersionTLS13,
		ServerName: c.config.Host,
	}
	if mode == "require" {
		cfg.InsecureSkipVerify = true
	}
	if c.config.SSLCert != "" {
		cert, err := loadTLSKeyPair(c.config.SSLCert, c.config.SSLKey, c.config.SSLPassword)
		if err != nil {
			return nil, err
		}
		cfg.Certificates = []tls.Certificate{cert}
	}
	if c.config.SSLRootCert != "" {
		caData, err := os.ReadFile(c.config.SSLRootCert)
		if err != nil {
			return nil, err
		}
		pool := x509.NewCertPool()
		if ok := pool.AppendCertsFromPEM(caData); !ok {
			return nil, errors.New("failed to parse sslrootcert PEM")
		}
		cfg.RootCAs = pool
	}
	return cfg, nil
}

func loadTLSKeyPair(certFile, keyFile, password string) (tls.Certificate, error) {
	if password == "" {
		return tls.LoadX509KeyPair(certFile, keyFile)
	}
	certPEM, err := os.ReadFile(certFile)
	if err != nil {
		return tls.Certificate{}, err
	}
	keyPEM, err := os.ReadFile(keyFile)
	if err != nil {
		return tls.Certificate{}, err
	}
	var certs [][]byte
	rest := certPEM
	for {
		var block *pem.Block
		block, rest = pem.Decode(rest)
		if block == nil {
			break
		}
		if block.Type == "CERTIFICATE" {
			certs = append(certs, block.Bytes)
		}
	}
	if len(certs) == 0 {
		return tls.Certificate{}, errors.New("no certificates found in client cert")
	}

	keyBlock, _ := pem.Decode(keyPEM)
	if keyBlock == nil {
		return tls.Certificate{}, errors.New("no private key found in client key")
	}
	keyDER := keyBlock.Bytes
	if x509.IsEncryptedPEMBlock(keyBlock) {
		decrypted, err := x509.DecryptPEMBlock(keyBlock, []byte(password))
		if err != nil {
			return tls.Certificate{}, err
		}
		keyDER = decrypted
	}
	var privateKey any
	if parsed, err := x509.ParsePKCS8PrivateKey(keyDER); err == nil {
		privateKey = parsed
	} else if parsed, err := x509.ParsePKCS1PrivateKey(keyDER); err == nil {
		privateKey = parsed
	} else if parsed, err := x509.ParseECPrivateKey(keyDER); err == nil {
		privateKey = parsed
	} else {
		return tls.Certificate{}, errors.New("unsupported private key format")
	}
	return tls.Certificate{Certificate: certs, PrivateKey: privateKey}, nil
}

func isManagerProxyMode(mode string) bool {
	normalized, ok := normalizeFrontDoorMode(mode)
	return ok && normalized == "manager_proxy"
}

func appendU16(buf []byte, value uint16) []byte {
	return append(buf, byte(value), byte(value>>8))
}

func appendU32(buf []byte, value uint32) []byte {
	return append(buf, byte(value), byte(value>>8), byte(value>>16), byte(value>>24))
}

func appendLengthPrefixedString(buf []byte, value string) []byte {
	buf = appendU32(buf, uint32(len(value)))
	buf = append(buf, []byte(value)...)
	return buf
}

func readU32(data []byte) uint32 {
	return binary.LittleEndian.Uint32(data)
}

func (c *Conn) sendManagerFrame(msgType uint8, payload []byte) error {
	if c.raw == nil {
		return errors.New("connection not open")
	}
	frame := make([]byte, 0, managerHeaderSize+len(payload))
	frame = appendU32(frame, managerProtocolMagic)
	frame = appendU16(frame, managerProtocolVersion)
	frame = append(frame, msgType, 0)
	frame = appendU32(frame, uint32(len(payload)))
	frame = append(frame, payload...)
	if c.config.SocketTimeout > 0 {
		_ = c.raw.SetWriteDeadline(time.Now().Add(c.config.SocketTimeout))
	}
	_, err := c.raw.Write(frame)
	if err != nil {
		return &Error{Kind: ErrConnection, Message: "manager frame write failed: " + err.Error(), SQLState: "08006"}
	}
	return nil
}

func (c *Conn) receiveManagerFrame() (uint8, []byte, error) {
	if c.raw == nil {
		return 0, nil, errors.New("connection not open")
	}
	if c.config.SocketTimeout > 0 {
		_ = c.raw.SetReadDeadline(time.Now().Add(c.config.SocketTimeout))
	}
	header := make([]byte, managerHeaderSize)
	if _, err := io.ReadFull(c.raw, header); err != nil {
		return 0, nil, &Error{Kind: ErrConnection, Message: "manager frame read failed: " + err.Error(), SQLState: "08006"}
	}
	if readU32(header[0:4]) != managerProtocolMagic {
		return 0, nil, &Error{Kind: ErrConnection, Message: "manager frame magic mismatch", SQLState: "08P01"}
	}
	if binary.LittleEndian.Uint16(header[4:6]) != managerProtocolVersion {
		return 0, nil, &Error{Kind: ErrConnection, Message: "manager frame version mismatch", SQLState: "08P01"}
	}
	msgType := header[6]
	payloadLen := readU32(header[8:12])
	if payloadLen > managerMaxPayloadSize {
		return 0, nil, &Error{Kind: ErrConnection, Message: "manager payload too large", SQLState: "08P01"}
	}
	payload := make([]byte, payloadLen)
	if payloadLen > 0 {
		if _, err := io.ReadFull(c.raw, payload); err != nil {
			return 0, nil, &Error{Kind: ErrConnection, Message: "manager payload read failed: " + err.Error(), SQLState: "08006"}
		}
	}
	return msgType, payload, nil
}

func (c *Conn) performManagerConnect(_ context.Context) error {
	if c.config.ManagerAuthToken == "" {
		return &Error{Kind: ErrConnection, Message: "manager_proxy mode requires manager_auth_token", SQLState: "08001"}
	}

	managerUser := c.config.ManagerUsername
	if managerUser == "" {
		if c.config.User != "" {
			managerUser = c.config.User
		} else {
			managerUser = "admin"
		}
	}
	managerDB := c.config.ManagerDatabase
	if managerDB == "" {
		managerDB = c.config.Database
	}
	managerProfile := c.config.ManagerConnectionProfile
	if managerProfile == "" {
		managerProfile = "native_v3"
	}
	managerIntent := c.config.ManagerClientIntent
	if managerIntent == "" {
		managerIntent = "native_v3"
	}

	helloPayload := make([]byte, 0, 4)
	helloPayload = appendU16(helloPayload, mcpProtocolVersion)
	helloPayload = appendU16(helloPayload, c.config.ManagerClientFlags)
	if err := c.sendManagerFrame(mcpMsgHello, helloPayload); err != nil {
		return err
	}
	msgType, _, err := c.receiveManagerFrame()
	if err != nil {
		return err
	}
	if msgType != mcpMsgStatusResponse {
		return &Error{Kind: ErrConnection, Message: "expected MCP hello status response", SQLState: "08P01"}
	}

	authStart := make([]byte, 0, 96+len(c.config.ManagerAuthToken))
	authStart = appendLengthPrefixedString(authStart, managerUser)
	authStart = append(authStart, mcpAuthMethodToken)
	if c.config.ManagerAuthFastPath {
		authStart = appendU32(authStart, uint32(len(c.config.ManagerAuthToken)))
		authStart = append(authStart, []byte(c.config.ManagerAuthToken)...)
	} else {
		authStart = appendU32(authStart, 0)
	}
	if err := c.sendManagerFrame(mcpMsgAuthStart, authStart); err != nil {
		return err
	}

	msgType, payload, err := c.receiveManagerFrame()
	if err != nil {
		return err
	}
	if msgType == mcpMsgAuthChallenge {
		authContinue := make([]byte, 0, 4+len(c.config.ManagerAuthToken))
		authContinue = appendU32(authContinue, uint32(len(c.config.ManagerAuthToken)))
		authContinue = append(authContinue, []byte(c.config.ManagerAuthToken)...)
		if err := c.sendManagerFrame(mcpMsgAuthContinue, authContinue); err != nil {
			return err
		}
		msgType, payload, err = c.receiveManagerFrame()
		if err != nil {
			return err
		}
	}
	if msgType != mcpMsgAuthResponse {
		return &Error{Kind: ErrConnection, Message: "expected MCP auth response", SQLState: "08P01"}
	}
	if len(payload) < 1+4+256 {
		return &Error{Kind: ErrConnection, Message: "truncated MCP auth response", SQLState: "08P01"}
	}
	if payload[0] != 0 {
		errMsg := strings.TrimRight(string(payload[5:261]), "\x00")
		if errMsg == "" {
			errMsg = "MCP authentication failed"
		}
		return &Error{Kind: ErrAuth, Message: errMsg, SQLState: "28000"}
	}

	dbConnect := make([]byte, 0, 160)
	dbConnect = append(dbConnect, 'M', 'C', 'P', '1')
	dbConnect = appendLengthPrefixedString(dbConnect, managerDB)
	dbConnect = appendLengthPrefixedString(dbConnect, managerProfile)
	dbConnect = appendLengthPrefixedString(dbConnect, managerIntent)
	nonce := make([]byte, 16)
	if _, err := rand.Read(nonce); err != nil {
		return &Error{Kind: ErrConnection, Message: "failed to generate MCP nonce", SQLState: "08006"}
	}
	dbConnect = appendU16(dbConnect, uint16(len(nonce)))
	dbConnect = append(dbConnect, nonce...)
	if err := c.sendManagerFrame(mcpMsgDbConnect, dbConnect); err != nil {
		return err
	}

	msgType, payload, err = c.receiveManagerFrame()
	if err != nil {
		return err
	}
	if msgType != mcpMsgConnectResponse {
		return &Error{Kind: ErrConnection, Message: "expected MCP connect response", SQLState: "08P01"}
	}
	if len(payload) < 1+2+2+16+64+32 {
		return &Error{Kind: ErrConnection, Message: "truncated MCP connect response", SQLState: "08P01"}
	}
	if payload[0] != 0 {
		errMsg := "MCP database connect failed"
		errOffset := 1 + 2 + 2 + 16 + 64 + 32
		if len(payload) >= errOffset+4 {
			errLen := int(readU32(payload[errOffset : errOffset+4]))
			if len(payload) >= errOffset+4+errLen {
				errMsg = string(payload[errOffset+4 : errOffset+4+errLen])
			}
		}
		return &Error{Kind: ErrAuth, Message: errMsg, SQLState: "28000"}
	}
	return nil
}

func (c *Conn) handshake(ctx context.Context) error {
	c.authed = false
	c.params = map[string]string{}
	features := c.requestedFeatures()
	params := map[string]string{
		"database":     c.config.Database,
		"user":         c.config.User,
		"client_flags": strconv.FormatUint(uint64(c.config.ConnectClientFlags), 10),
	}
	if c.config.Role != "" {
		params["role"] = c.config.Role
	}
	if c.config.Application != "" {
		params["application_name"] = c.config.Application
	}
	selection := AuthPluginSelection{
		MethodID:                c.config.AuthMethodID,
		MethodPayload:           c.config.AuthMethodPayload,
		PayloadJSON:             c.config.AuthPayloadJSON,
		PayloadB64:              c.config.AuthPayloadB64,
		ProviderProfile:         c.config.AuthProviderProfile,
		RequiredMethods:         c.config.AuthRequiredMethods,
		ForbiddenMethods:        c.config.AuthForbiddenMethods,
		RequireChannelBinding:   c.config.AuthRequireChannelBinding,
		WorkloadIdentityToken:   c.config.WorkloadIdentityToken,
		ProxyPrincipalAssertion: c.config.ProxyPrincipalAssertion,
	}
	if err := ApplyAuthPluginSelection(params, selection); err != nil {
		return &Error{Kind: ErrData, Message: err.Error(), SQLState: "22023"}
	}
	payload := buildStartupPayload(features, params)
	if err := c.sendMessage(msgStartup, payload, 0, true); err != nil {
		return err
	}
	var scram *scramClient
	for {
		msg, err := c.receive()
		if err != nil {
			return err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgNegotiateVersion:
			continue
		case msgAuthRequest:
			method, data, err := parseAuthRequest(msg.body)
			if err != nil {
				return err
			}
			scram, err = c.handleAuthRequest(method, data, scram)
			if err != nil {
				return err
			}
		case msgAuthContinue:
			method, _, data, err := parseAuthContinue(msg.body)
			if err != nil {
				return err
			}
			scram, err = c.handleAuthContinue(method, data, scram)
			if err != nil {
				return err
			}
		case msgAuthOk:
			sessionID, info, err := parseAuthOk(msg.body)
			if err != nil {
				return err
			}
			copy(c.attachmentID[:], msg.header.attachmentID[:])
			c.txnID = msg.header.txnID
			c.authed = true
			if scram != nil && len(info) > 0 && strings.HasPrefix(string(info), "v=") {
				_ = scram.verifyServerFinal(string(info))
			}
			_ = sessionID
		case msgReady:
			_, txnID, _, err := parseReady(msg.body)
			if err != nil {
				return err
			}
			c.txnID = txnID
			return nil
		case msgError:
			return buildProtocolError(msg.body)
		default:
			continue
		}
	}
}

func (c *Conn) handleAuthRequest(method authMethod, data []byte, scram *scramClient) (*scramClient, error) {
	switch method {
	case authOK:
		return scram, nil
	case authPassword:
		if err := c.sendMessage(msgAuthResponse, []byte(c.config.Password), 0, true); err != nil {
			return scram, err
		}
		return scram, nil
	case authScramSha256:
		if scram == nil {
			client, err := newScramClient(c.config.User)
			if err != nil {
				return nil, err
			}
			scram = client
		}
		_ = data
		payload := []byte(scram.clientFirstMessage())
		if err := c.sendMessage(msgAuthResponse, payload, 0, true); err != nil {
			return scram, err
		}
		return scram, nil
	case authMD5, authCertificate, authGSSAPI, authSSPI, authLDAP, authSAML, authOIDC, authMFATOTP, authClusterPKI:
		payload := c.buildGenericAuthPayload(data)
		if err := c.sendMessage(msgAuthResponse, payload, 0, true); err != nil {
			return scram, err
		}
		return scram, nil
	default:
		return scram, &Error{Kind: ErrAuth, Message: "unsupported auth method", SQLState: "28000"}
	}
}

func (c *Conn) handleAuthContinue(method authMethod, data []byte, scram *scramClient) (*scramClient, error) {
	switch method {
	case authScramSha256:
		if scram == nil {
			return nil, &Error{Kind: ErrAuth, Message: "SCRAM state missing", SQLState: "28000"}
		}
		clientFinal, err := scram.handleServerFirst(c.config.Password, string(data))
		if err != nil {
			return nil, err
		}
		if err := c.sendMessage(msgAuthResponse, []byte(clientFinal), 0, true); err != nil {
			return nil, err
		}
		return scram, nil
	case authMD5, authCertificate, authGSSAPI, authSSPI, authLDAP, authSAML, authOIDC, authMFATOTP, authClusterPKI:
		payload := c.buildGenericAuthPayload(data)
		if err := c.sendMessage(msgAuthResponse, payload, 0, true); err != nil {
			return nil, err
		}
		return scram, nil
	default:
		return scram, &Error{Kind: ErrAuth, Message: "unsupported auth method", SQLState: "28000"}
	}
}

func (c *Conn) buildGenericAuthPayload(challenge []byte) []byte {
	if c.config.AuthPayloadB64 != "" {
		decoded, err := base64.StdEncoding.DecodeString(c.config.AuthPayloadB64)
		if err == nil {
			return decoded
		}
	}
	if c.config.AuthPayloadJSON != "" {
		return []byte(c.config.AuthPayloadJSON)
	}
	if c.config.Password != "" {
		return []byte(c.config.Password)
	}
	if len(challenge) > 0 {
		return append([]byte{}, challenge...)
	}
	return nil
}

func (c *Conn) Prepare(query string) (driver.Stmt, error) {
	return c.PrepareContext(context.Background(), query)
}

func (c *Conn) PrepareContext(ctx context.Context, query string) (driver.Stmt, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	stmtName := fmt.Sprintf("stmt_%d", time.Now().UnixNano())
	normalized, err := normalizeQuery(query, nil)
	if err != nil {
		return nil, err
	}
	payload := buildParsePayload(stmtName, normalized.sql, nil)
	if err := c.sendMessage(msgParse, payload, 0, false); err != nil {
		return nil, err
	}
	describePayload := buildDescribePayload('S', stmtName)
	if err := c.sendMessage(msgDescribe, describePayload, 0, false); err != nil {
		return nil, err
	}
	if err := c.sendMessage(msgSync, nil, 0, false); err != nil {
		return nil, err
	}
	paramCount := -1
	for {
		msg, err := c.receive()
		if err != nil {
			return nil, err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgParameterDescription:
			types, err := parseParameterDescription(msg.body)
			if err != nil {
				return nil, err
			}
			paramCount = len(types)
		case msgError:
			return nil, buildProtocolError(msg.body)
		case msgReady:
			_, txnID, _, err := parseReady(msg.body)
			if err != nil {
				return nil, err
			}
			c.txnID = txnID
			return &Stmt{conn: c, query: normalized.sql, name: stmtName, paramCount: paramCount}, nil
		default:
			continue
		}
	}
}

func (c *Conn) Begin() (driver.Tx, error) {
	return c.BeginTx(context.Background(), driver.TxOptions{})
}

func (c *Conn) BeginTx(ctx context.Context, opts driver.TxOptions) (driver.Tx, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	flags := uint16(0)
	isolation := isolationReadCommitted
	if opts.Isolation != 0 {
		flags |= txnFlagHasIsolation
		switch opts.Isolation {
		case driver.IsolationLevel(sql.LevelReadUncommitted):
			isolation = isolationReadUncommitted
		case driver.IsolationLevel(sql.LevelReadCommitted):
			isolation = isolationReadCommitted
		case driver.IsolationLevel(sql.LevelRepeatableRead):
			isolation = isolationRepeatableRead
		case driver.IsolationLevel(sql.LevelSerializable):
			isolation = isolationSerializable
		default:
			return nil, &Error{
				Kind:     ErrNotSupported,
				Message:  fmt.Sprintf("isolation level %d is not supported", opts.Isolation),
				SQLState: "0A000",
			}
		}
	}
	accessMode := byte(0)
	if opts.ReadOnly {
		flags |= txnFlagHasAccess
		accessMode = 1
	}
	payload := buildTxnBeginPayload(flags, 0, 0, isolation, accessMode, 0, 0, 0)
	if err := c.sendMessage(msgTxnBegin, payload, 0, false); err != nil {
		return nil, err
	}
	if _, _, _, err := c.drainUntilReady(ctx); err != nil {
		return nil, err
	}
	return &Tx{conn: c}, nil
}

func (c *Conn) Savepoint(ctx context.Context, name string) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	savepointName, err := validateSavepointName(name)
	if err != nil {
		return err
	}
	if c.txnID == 0 {
		return &Error{Kind: ErrTransaction, Message: "savepoint requires an active transaction", SQLState: "25000"}
	}
	payload := buildTxnSavepointPayload(savepointName)
	if err := c.sendMessage(msgTxnSavepoint, payload, 0, false); err != nil {
		return err
	}
	_, _, _, err = c.drainUntilReady(ctx)
	return err
}

func (c *Conn) ReleaseSavepoint(ctx context.Context, name string) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	savepointName, err := validateSavepointName(name)
	if err != nil {
		return err
	}
	if c.txnID == 0 {
		return &Error{Kind: ErrTransaction, Message: "release savepoint requires an active transaction", SQLState: "25000"}
	}
	payload := buildTxnReleasePayload(savepointName)
	if err := c.sendMessage(msgTxnRelease, payload, 0, false); err != nil {
		return err
	}
	_, _, _, err = c.drainUntilReady(ctx)
	return err
}

func (c *Conn) RollbackToSavepoint(ctx context.Context, name string) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	savepointName, err := validateSavepointName(name)
	if err != nil {
		return err
	}
	if c.txnID == 0 {
		return &Error{Kind: ErrTransaction, Message: "rollback to savepoint requires an active transaction", SQLState: "25000"}
	}
	payload := buildTxnRollbackToPayload(savepointName)
	if err := c.sendMessage(msgTxnRollbackTo, payload, 0, false); err != nil {
		return err
	}
	_, _, _, err = c.drainUntilReady(ctx)
	return err
}

func (c *Conn) ExecContext(ctx context.Context, query string, args []driver.NamedValue) (driver.Result, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	normalized, err := normalizeQuery(query, args)
	if err != nil {
		return nil, err
	}
	span, err := c.beginOperation("exec", normalized.sql)
	if err != nil {
		return nil, err
	}
	if len(normalized.args) == 0 {
		if err := c.sendSimpleQueryWithMaxRows(normalized.sql, ctx, 0); err != nil {
			c.endOperation(span, false)
			return nil, err
		}
		tag, rows, lastID, err := c.drainUntilReady(ctx)
		if err != nil {
			c.endOperation(span, false)
			return nil, err
		}
		c.endOperation(span, true)
		return &Result{tag: tag, rowsAffected: int64(rows), lastInsertID: int64(lastID)}, nil
	}
	if err := c.sendExtendedQueryWithMaxRows(normalized.sql, normalized.args, ctx, 0); err != nil {
		c.endOperation(span, false)
		return nil, err
	}
	tag, rows, lastID, err := c.drainUntilReady(ctx)
	if err != nil {
		c.endOperation(span, false)
		return nil, err
	}
	c.endOperation(span, true)
	return &Result{tag: tag, rowsAffected: int64(rows), lastInsertID: int64(lastID)}, nil
}

func (c *Conn) QueryContext(ctx context.Context, query string, args []driver.NamedValue) (driver.Rows, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	normalized, err := normalizeQuery(query, args)
	if err != nil {
		return nil, err
	}
	span, err := c.beginOperation("query", normalized.sql)
	if err != nil {
		return nil, err
	}
	if len(normalized.args) == 0 {
		if err := c.sendSimpleQuery(normalized.sql, ctx); err != nil {
			c.endOperation(span, false)
			return nil, err
		}
		c.endOperation(span, true)
		return newRows(c, ctx), nil
	}
	if err := c.sendExtendedQuery(normalized.sql, normalized.args, ctx); err != nil {
		c.endOperation(span, false)
		return nil, err
	}
	c.endOperation(span, true)
	return newRows(c, ctx), nil
}

func (c *Conn) sendSimpleQuery(sql string, ctx context.Context) error {
	return c.sendSimpleQueryWithMaxRows(sql, ctx, c.config.FetchSize)
}

func (c *Conn) sendSimpleQueryWithMaxRows(sql string, ctx context.Context, maxRows uint32) error {
	flags := uint32(0)
	if c.config.BinaryTransfer {
		flags |= queryFlagBinaryResult
	}
	timeoutMs := uint32(0)
	if deadline, ok := ctx.Deadline(); ok {
		remaining := time.Until(deadline)
		if remaining > 0 {
			timeoutMs = uint32(remaining / time.Millisecond)
		}
	}
	payload := buildQueryPayload(sql, flags, maxRows, timeoutMs)
	return c.sendMessage(msgQuery, payload, 0, false)
}

func (c *Conn) sendExtendedQuery(sql string, args []driver.NamedValue, ctx context.Context) error {
	return c.sendExtendedQueryWithMaxRows(sql, args, ctx, c.config.FetchSize)
}

func (c *Conn) sendExtendedQueryWithMaxRows(sql string, args []driver.NamedValue, ctx context.Context, maxRows uint32) error {
	paramValues := make([]paramValue, 0, len(args))
	paramTypes := make([]uint32, 0, len(args))
	for _, arg := range args {
		value, oid, err := encodeParam(arg.Value)
		if err != nil {
			return err
		}
		value.format = formatBinary
		paramValues = append(paramValues, value)
		paramTypes = append(paramTypes, oid)
	}
	parsePayload := buildParsePayload("", sql, paramTypes)
	if err := c.sendMessage(msgParse, parsePayload, 0, false); err != nil {
		return err
	}
	describePayload := buildDescribePayload('S', "")
	if err := c.sendMessage(msgDescribe, describePayload, 0, false); err != nil {
		return err
	}
	if err := c.sendMessage(msgSync, nil, 0, false); err != nil {
		return err
	}
	paramCount := -1
	for {
		msg, err := c.receive()
		if err != nil {
			return err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgParameterDescription:
			types, err := parseParameterDescription(msg.body)
			if err != nil {
				return err
			}
			paramCount = len(types)
		case msgError:
			return buildProtocolError(msg.body)
		case msgReady:
			_, txnID, _, err := parseReady(msg.body)
			if err != nil {
				return err
			}
			c.txnID = txnID
			goto described
		default:
			continue
		}
	}
described:
	if paramCount >= 0 && paramCount != len(args) {
		return &Error{Kind: ErrSyntax, Message: "parameter count mismatch", SQLState: "07001"}
	}
	resultFormats := []uint16{}
	if c.config.BinaryTransfer {
		resultFormats = []uint16{formatBinary}
	}
	bindPayload := buildBindPayload("", "", paramValues, resultFormats)
	if err := c.sendMessage(msgBind, bindPayload, 0, false); err != nil {
		return err
	}
	execPayload := buildExecutePayload("", maxRows)
	if err := c.sendMessage(msgExecute, execPayload, 0, false); err != nil {
		return err
	}
	if maxRows > 0 {
		return nil
	}
	return c.sendMessage(msgSync, nil, 0, false)
}

func (c *Conn) Ping(ctx context.Context) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	if err := c.sendMessage(msgPing, nil, 0, false); err != nil {
		return err
	}
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}
		msg, err := c.receive()
		if err != nil {
			return err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgPong:
			return nil
		case msgReady:
			_, txnID, _, err := parseReady(msg.body)
			if err == nil {
				c.txnID = txnID
			}
			return nil
		case msgError:
			return buildProtocolError(msg.body)
		default:
			continue
		}
	}
}

func (c *Conn) ResetSession(ctx context.Context) error {
	_ = ctx
	return nil
}

func (c *Conn) SetOption(ctx context.Context, name, value string) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	payload := buildSetOptionPayload(name, value)
	if err := c.sendMessage(msgSetOption, payload, 0, false); err != nil {
		return err
	}
	_, _, _, err := c.drainUntilReady(ctx)
	return err
}

func (c *Conn) QueryMetadata(ctx context.Context, collection string) (driver.Rows, error) {
	return c.QueryMetadataWithRestrictions(ctx, collection, nil)
}

func (c *Conn) QueryMetadataWithRestrictions(ctx context.Context, collection string, restrictions map[string]any) (driver.Rows, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	query, err := ResolveMetadataCollectionQuery(collection)
	if err != nil {
		return nil, &Error{
			Kind:     ErrNotSupported,
			Message:  err.Error(),
			SQLState: "0A000",
		}
	}
	if len(restrictions) == 0 {
		return c.QueryContext(ctx, query, nil)
	}
	rowsIface, err := c.QueryContext(ctx, query, nil)
	if err != nil {
		return nil, err
	}
	rows, ok := rowsIface.(*Rows)
	if !ok {
		_ = rowsIface.Close()
		return nil, &Error{
			Kind:     ErrInternal,
			Message:  "unexpected metadata rows implementation",
			SQLState: "XX000",
		}
	}
	defer func() { _ = rows.Close() }()

	allRows := make([][]driver.Value, 0, 16)
	columnNames := []string(nil)
	colInfo := []columnInfo(nil)
	captureColumns := func() {
		if len(columnNames) > 0 || len(rows.columns) == 0 {
			return
		}
		columnNames = make([]string, len(rows.columns))
		for idx, col := range rows.columns {
			columnName := col.name
			if columnName == "" {
				columnName = fmt.Sprintf("column_%d", idx+1)
			}
			columnNames[idx] = columnName
		}
		colInfo = append([]columnInfo(nil), rows.columns...)
	}

	for {
		row, err := rows.nextRow()
		if err == nil {
			captureColumns()
			allRows = append(allRows, append([]driver.Value(nil), row...))
			continue
		}
		if errors.Is(err, io.EOF) {
			captureColumns()
			if rows.hasNextSet {
				if nextErr := rows.NextResultSet(); nextErr != nil && !errors.Is(nextErr, io.EOF) {
					return nil, nextErr
				}
				continue
			}
			break
		}
		return nil, err
	}

	filteredRows := filterMetadataRowsByRestrictions(allRows, columnNames, restrictions, collection)
	return newMetadataRows(columnNames, colInfo, filteredRows), nil
}

func (c *Conn) Subscribe(ctx context.Context, subType byte, channel, filter string) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	payload := buildSubscribePayload(subType, channel, filter)
	if err := c.sendMessage(msgSubscribe, payload, 0, false); err != nil {
		return err
	}
	_, _, _, err := c.drainUntilReady(ctx)
	return err
}

func (c *Conn) Unsubscribe(ctx context.Context, channel string) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	payload := buildUnsubscribePayload(channel)
	if err := c.sendMessage(msgUnsubscribe, payload, 0, false); err != nil {
		return err
	}
	_, _, _, err := c.drainUntilReady(ctx)
	return err
}

func (c *Conn) OnNotification(handler func(notificationMessage)) {
	if handler == nil {
		return
	}
	c.notificationHandlers = append(c.notificationHandlers, handler)
}

func (c *Conn) LastPlan() *queryPlan {
	return c.lastPlan
}

func (c *Conn) LastSblr() *sblrCompiled {
	return c.lastSblr
}

func (c *Conn) QuerySblr(ctx context.Context, hash uint64, bytecode []byte, params []driver.NamedValue) (driver.Rows, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	span, err := c.beginOperation("query_sblr", "")
	if err != nil {
		return nil, err
	}
	paramValues := make([]paramValue, 0, len(params))
	for _, arg := range params {
		value, _, err := encodeParam(arg.Value)
		if err != nil {
			c.endOperation(span, false)
			return nil, err
		}
		value.format = formatBinary
		paramValues = append(paramValues, value)
	}
	payload := buildSblrExecutePayload(hash, bytecode, paramValues)
	if err := c.sendMessage(msgSblrExecute, payload, 0, false); err != nil {
		c.endOperation(span, false)
		return nil, err
	}
	if err := c.sendMessage(msgSync, nil, 0, false); err != nil {
		c.endOperation(span, false)
		return nil, err
	}
	c.endOperation(span, true)
	return newRows(c, ctx), nil
}

func (c *Conn) ExecSblr(ctx context.Context, hash uint64, bytecode []byte, params []driver.NamedValue) (driver.Result, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	span, err := c.beginOperation("exec_sblr", "")
	if err != nil {
		return nil, err
	}
	paramValues := make([]paramValue, 0, len(params))
	for _, arg := range params {
		value, _, err := encodeParam(arg.Value)
		if err != nil {
			c.endOperation(span, false)
			return nil, err
		}
		value.format = formatBinary
		paramValues = append(paramValues, value)
	}
	payload := buildSblrExecutePayload(hash, bytecode, paramValues)
	if err := c.sendMessage(msgSblrExecute, payload, 0, false); err != nil {
		c.endOperation(span, false)
		return nil, err
	}
	if err := c.sendMessage(msgSync, nil, 0, false); err != nil {
		c.endOperation(span, false)
		return nil, err
	}
	tag, affected, lastID, err := c.drainUntilReady(ctx)
	if err != nil {
		c.endOperation(span, false)
		return nil, err
	}
	c.endOperation(span, true)
	return &Result{tag: tag, rowsAffected: int64(affected), lastInsertID: int64(lastID)}, nil
}

func (c *Conn) StreamControl(ctx context.Context, controlType byte, windowSize, timeoutMs uint32) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	payload := buildStreamControlPayload(controlType, windowSize, timeoutMs)
	return c.sendMessage(msgStreamControl, payload, 0, false)
}

func (c *Conn) AttachCreate(ctx context.Context, emulationMode, dbName string) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	payload := buildAttachCreatePayload(emulationMode, dbName)
	if err := c.sendMessage(msgAttachCreate, payload, 0, false); err != nil {
		return err
	}
	_, _, _, err := c.drainUntilReady(ctx)
	return err
}

func (c *Conn) AttachDetach(ctx context.Context) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	if err := c.sendMessage(msgAttachDetach, nil, 0, false); err != nil {
		return err
	}
	_, _, _, err := c.drainUntilReady(ctx)
	return err
}

func (c *Conn) AttachList(ctx context.Context) (driver.Rows, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	if err := c.sendMessage(msgAttachList, nil, 0, false); err != nil {
		return nil, err
	}
	if err := c.sendMessage(msgSync, nil, 0, false); err != nil {
		return nil, err
	}
	return newRows(c, ctx), nil
}

// CopyIn executes a COPY FROM operation, sending data to the server.
// Returns the number of rows copied.
func (c *Conn) CopyIn(ctx context.Context, sql string, data []byte, format int) (int64, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return 0, err
	}
	span, err := c.beginOperation("copy_in", sql)
	if err != nil {
		return 0, err
	}

	// Send COPY SQL as a query
	if err := c.sendSimpleQuery(sql, ctx); err != nil {
		c.endOperation(span, false)
		return 0, err
	}

	// Wait for CopyInResponse
	for {
		select {
		case <-ctx.Done():
			return 0, ctx.Err()
		default:
		}
		msg, err := c.receive()
		if err != nil {
			c.endOperation(span, false)
			return 0, err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgError:
			c.endOperation(span, false)
			return 0, buildProtocolError(msg.body)
		case msgCopyInResponse:
			_, err := parseCopyInResponse(msg.body)
			if err != nil {
				c.endOperation(span, false)
				return 0, err
			}
			goto sendData
		case msgReady:
			c.endOperation(span, false)
			return 0, &Error{Kind: ErrConnection, Message: "expected COPY IN response", SQLState: "08P01"}
		}
	}

sendData:
	// Send data in chunks
	const chunkSize = 65536 // 64KB chunks
	for offset := 0; offset < len(data); offset += chunkSize {
		end := offset + chunkSize
		if end > len(data) {
			end = len(data)
		}
		chunk := data[offset:end]
		payload := buildCopyDataPayload(chunk)
		if err := c.sendMessage(msgCopyData, payload, 0, false); err != nil {
			c.endOperation(span, false)
			return 0, err
		}
	}

	// Send CopyDone
	if err := c.sendMessage(msgCopyDone, buildCopyDonePayload(), 0, false); err != nil {
		c.endOperation(span, false)
		return 0, err
	}

	// Wait for CommandComplete and Ready
	tag, rows, _, err := c.drainUntilReady(ctx)
	_ = tag
	_ = format
	c.endOperation(span, err == nil)
	return int64(rows), err
}

// CopyOut executes a COPY TO operation, receiving data from the server.
// Returns the copied data.
func (c *Conn) CopyOut(ctx context.Context, sql string, format int) ([]byte, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	span, err := c.beginOperation("copy_out", sql)
	if err != nil {
		return nil, err
	}

	// Send COPY SQL as a query
	if err := c.sendSimpleQuery(sql, ctx); err != nil {
		c.endOperation(span, false)
		return nil, err
	}

	// Wait for CopyOutResponse
	for {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}
		msg, err := c.receive()
		if err != nil {
			c.endOperation(span, false)
			return nil, err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgError:
			c.endOperation(span, false)
			return nil, buildProtocolError(msg.body)
		case msgCopyOutResponse:
			_, err := parseCopyOutResponse(msg.body)
			if err != nil {
				c.endOperation(span, false)
				return nil, err
			}
			goto receiveData
		case msgReady:
			c.endOperation(span, false)
			return nil, &Error{Kind: ErrConnection, Message: "expected COPY OUT response", SQLState: "08P01"}
		}
	}

receiveData:
	// Collect data until CopyDone
	var chunks []byte
	for {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}
		msg, err := c.receive()
		if err != nil {
			c.endOperation(span, false)
			return nil, err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgError:
			c.endOperation(span, false)
			return nil, buildProtocolError(msg.body)
		case msgCopyData:
			chunks = append(chunks, msg.body...)
		case msgCopyDone:
			goto done
		case msgCopyFail:
			c.endOperation(span, false)
			return nil, &Error{Kind: ErrOperator, Message: "COPY failed on server side", SQLState: "57014"}
		case msgReady:
			c.endOperation(span, false)
			return nil, &Error{Kind: ErrConnection, Message: "unexpected READY during COPY", SQLState: "08P01"}
		}
	}

done:
	// Wait for CommandComplete and Ready
	_, _, _, err = c.drainUntilReady(ctx)
	_ = format
	c.endOperation(span, err == nil)
	return chunks, err
}

func (c *Conn) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.closed {
		return nil
	}
	c.closed = true
	if c.keepaliveMgr != nil {
		if c.keepaliveTracker != nil {
			c.keepaliveMgr.Unregister(c.connID)
			c.keepaliveTracker = nil
		}
		c.keepaliveMgr.Stop()
		c.keepaliveMgr = nil
	}
	if c.leakGuard != nil {
		c.leakGuard.Release()
		c.leakGuard = nil
	}
	if c.leakDetector != nil {
		c.leakDetector.Stop()
		c.leakDetector = nil
	}
	if c.raw == nil {
		return nil
	}
	return c.raw.Close()
}

func (c *Conn) CheckNamedValue(nv *driver.NamedValue) error {
	if nv == nil {
		return nil
	}
	return nil
}

func (c *Conn) ensureOpen(ctx context.Context) error {
	c.mu.Lock()
	if c.closed {
		c.mu.Unlock()
		return errors.New("connection is closed")
	}
	alreadyOpen := c.raw != nil
	c.mu.Unlock()
	if !alreadyOpen {
		return c.connect(ctx)
	}
	return nil
}

func (c *Conn) sendMessage(typ messageType, payload []byte, flags byte, forceZero bool) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.raw == nil {
		return errors.New("connection not open")
	}
	seq := c.sequence
	c.sequence++
	var attachment [16]byte
	var txnID uint64
	if c.authed && !forceZero {
		attachment = c.attachmentID
		txnID = c.txnID
	}
	header := messageHeader{
		typ:          typ,
		flags:        flags,
		sequence:     seq,
		attachmentID: attachment,
		txnID:        txnID,
	}
	encoded := encodeMessage(header, payload)
	if c.config.SocketTimeout > 0 {
		_ = c.raw.SetWriteDeadline(time.Now().Add(c.config.SocketTimeout))
	}
	_, err := c.raw.Write(encoded)
	return err
}

func (c *Conn) receive() (protocolMessage, error) {
	c.mu.Lock()
	if len(c.pending) > 0 {
		msg := c.pending[0]
		c.pending = c.pending[1:]
		c.mu.Unlock()
		return msg, nil
	}
	if c.raw == nil {
		c.mu.Unlock()
		return protocolMessage{}, errors.New("connection not open")
	}
	if c.config.SocketTimeout > 0 {
		_ = c.raw.SetReadDeadline(time.Now().Add(c.config.SocketTimeout))
	}
	raw := c.raw
	c.mu.Unlock()
	return readMessage(raw)
}

func (c *Conn) queue(msg protocolMessage) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.pending = append(c.pending, msg)
}

func (c *Conn) requestedFeatures() uint64 {
	features := uint64(0)
	if strings.EqualFold(c.config.Compression, "zstd") {
		features |= featureCompression
	}
	if c.config.BinaryTransfer {
		features |= featureStreaming
	}
	return features
}

func (c *Conn) applySchema(ctx context.Context) error {
	schema := strings.TrimSpace(c.config.Schema)
	if schema == "" || strings.EqualFold(schema, "public") {
		return nil
	}
	stmt := buildSchemaStatement(schema)
	if stmt == "" {
		return nil
	}
	if err := c.sendSimpleQuery(stmt, ctx); err != nil {
		return err
	}
	_, _, _, err := c.drainUntilReady(ctx)
	return err
}

func (c *Conn) handleAsyncMessage(msg protocolMessage) bool {
	switch msg.header.typ {
	case msgParameterStatus:
		name, value, err := parseParameterStatus(msg.body)
		if err == nil {
			c.params[name] = value
			switch name {
			case "attachment_id":
				if parsed, ok := parseUUIDHex(value); ok {
					c.attachmentID = parsed
				}
			case "current_txn_id":
				if parsed, err := parseUint64String(value); err == nil {
					c.txnID = parsed
				}
			}
		}
		return true
	case msgNotification:
		notice, err := parseNotification(msg.body)
		if err == nil {
			for _, handler := range c.notificationHandlers {
				handler(notice)
			}
		}
		return true
	case msgQueryPlan:
		plan, err := parseQueryPlan(msg.body)
		if err == nil {
			c.lastPlan = &plan
		}
		return true
	case msgSblrCompiled:
		compiled, err := parseSblrCompiled(msg.body)
		if err == nil {
			c.lastSblr = &compiled
		}
		return true
	default:
		return false
	}
}

func buildSchemaStatement(schema string) string {
	schema = strings.TrimSpace(schema)
	if schema == "" {
		return ""
	}
	if strings.Contains(schema, ",") {
		parts := strings.Split(schema, ",")
		quoted := make([]string, 0, len(parts))
		for _, part := range parts {
			part = strings.TrimSpace(part)
			if part == "" {
				continue
			}
			quoted = append(quoted, quoteIdentifier(part))
		}
		if len(quoted) == 0 {
			return ""
		}
		return "SET SEARCH_PATH TO " + strings.Join(quoted, ", ")
	}
	return "SET SCHEMA " + quoteIdentifier(schema)
}

func validateSavepointName(name string) (string, error) {
	trimmed := strings.TrimSpace(name)
	if trimmed == "" {
		return "", &Error{Kind: ErrSyntax, Message: "savepoint name is required", SQLState: "42601"}
	}
	return trimmed, nil
}

func quoteIdentifier(name string) string {
	return `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
}

func parseUUIDHex(value string) ([16]byte, bool) {
	var out [16]byte
	trimmed := strings.TrimSpace(strings.ReplaceAll(value, "-", ""))
	if len(trimmed) != 32 {
		return out, false
	}
	bytes, err := hex.DecodeString(trimmed)
	if err != nil || len(bytes) != 16 {
		return out, false
	}
	copy(out[:], bytes)
	return out, true
}

func parseUint64String(value string) (uint64, error) {
	trimmed := strings.TrimSpace(value)
	return strconv.ParseUint(trimmed, 10, 64)
}

func (c *Conn) drainUntilReady(ctx context.Context) (string, uint64, uint64, error) {
	var tag string
	var rows uint64
	var lastID uint64
	for {
		select {
		case <-ctx.Done():
			_ = c.sendMessage(msgCancel, buildCancelPayload(0, 0), msgFlagUrgent, false)
			return "", 0, 0, ctx.Err()
		default:
		}
		msg, err := c.receive()
		if err != nil {
			return "", 0, 0, err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgError:
			return "", 0, 0, buildProtocolError(msg.body)
		case msgCommandComplete:
			_, rows, lastID, tag, err = parseCommandComplete(msg.body)
			if err != nil {
				return "", 0, 0, err
			}
		case msgReady:
			_, txnID, _, err := parseReady(msg.body)
			if err == nil {
				c.txnID = txnID
			}
			return tag, rows, lastID, nil
		default:
			continue
		}
	}
}

// BatchInsert performs an efficient bulk insert using PARSE/BIND/EXECUTE cycles.
// It reuses the prepared statement for all parameter sets.
func (c *Conn) BatchInsert(ctx context.Context, sql string, paramsSlice [][]driver.Value) (int64, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return 0, err
	}
	span, err := c.beginOperation("batch_insert", sql)
	if err != nil {
		return 0, err
	}
	if len(paramsSlice) == 0 {
		c.endOperation(span, true)
		return 0, nil
	}

	// Parse the statement once
	paramTypes := make([]uint32, 0, len(paramsSlice[0]))
	for _, param := range paramsSlice[0] {
		_, oid, err := encodeParam(param)
		if err != nil {
			c.endOperation(span, false)
			return 0, err
		}
		paramTypes = append(paramTypes, oid)
	}

	parsePayload := buildParsePayload("", sql, paramTypes)
	if err := c.sendMessage(msgParse, parsePayload, 0, false); err != nil {
		c.endOperation(span, false)
		return 0, err
	}
	if err := c.sendMessage(msgSync, nil, 0, false); err != nil {
		c.endOperation(span, false)
		return 0, err
	}

	// Wait for ParseComplete
	for {
		msg, err := c.receive()
		if err != nil {
			c.endOperation(span, false)
			return 0, err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgError:
			c.endOperation(span, false)
			return 0, buildProtocolError(msg.body)
		case msgParseComplete:
			// Continue to bind/execute loop
			goto executeBatch
		case msgReady:
			c.endOperation(span, false)
			return 0, &Error{Kind: ErrSyntax, Message: "expected ParseComplete", SQLState: "08P01"}
		}
	}

executeBatch:
	var totalRows int64

	// Execute BIND/EXECUTE for each parameter set
	for _, params := range paramsSlice {
		paramValues := make([]paramValue, 0, len(params))
		for _, param := range params {
			value, _, err := encodeParam(param)
			if err != nil {
				c.endOperation(span, false)
				return totalRows, err
			}
			value.format = formatBinary
			paramValues = append(paramValues, value)
		}

		resultFormats := []uint16{}
		if c.config.BinaryTransfer {
			resultFormats = []uint16{formatBinary}
		}

		bindPayload := buildBindPayload("", "", paramValues, resultFormats)
		if err := c.sendMessage(msgBind, bindPayload, 0, false); err != nil {
			c.endOperation(span, false)
			return totalRows, err
		}

		execPayload := buildExecutePayload("", 0)
		if err := c.sendMessage(msgExecute, execPayload, 0, false); err != nil {
			c.endOperation(span, false)
			return totalRows, err
		}

		// Wait for CommandComplete for this batch item
		for {
			msg, err := c.receive()
			if err != nil {
				c.endOperation(span, false)
				return totalRows, err
			}
			if c.handleAsyncMessage(msg) {
				continue
			}
			switch msg.header.typ {
			case msgError:
				c.endOperation(span, false)
				return totalRows, buildProtocolError(msg.body)
			case msgCommandComplete:
				_, rows, _, _, err := parseCommandComplete(msg.body)
				if err != nil {
					c.endOperation(span, false)
					return totalRows, err
				}
				totalRows += int64(rows)
				goto nextBatch
			}
		}
	nextBatch:
	}

	// Send SYNC to complete the batch
	if err := c.sendMessage(msgSync, nil, 0, false); err != nil {
		c.endOperation(span, false)
		return totalRows, err
	}

	// Wait for Ready
	for {
		msg, err := c.receive()
		if err != nil {
			c.endOperation(span, false)
			return totalRows, err
		}
		if c.handleAsyncMessage(msg) {
			continue
		}
		switch msg.header.typ {
		case msgError:
			c.endOperation(span, false)
			return totalRows, buildProtocolError(msg.body)
		case msgReady:
			_, txnID, _, err := parseReady(msg.body)
			if err == nil {
				c.txnID = txnID
			}
			c.endOperation(span, true)
			return totalRows, nil
		}
	}
}

// IsHealthy returns true if the connection is healthy.
func (c *Conn) IsHealthy(ctx context.Context) bool {
	return c.Ping(ctx) == nil
}

func buildProtocolError(payload []byte) error {
	_, sqlState, msg, detail, hint, err := parseErrorMessage(payload)
	if err != nil {
		return err
	}
	return &Error{
		Kind:     mapSQLState(sqlState),
		SQLState: sqlState,
		Message:  msg,
		Detail:   detail,
		Hint:     hint,
	}
}

type Stmt struct {
	conn       *Conn
	query      string
	name       string
	paramCount int
}

func (s *Stmt) Close() error {
	if s.conn == nil {
		return nil
	}
	payload := buildClosePayload('S', s.name)
	if err := s.conn.sendMessage(msgClose, payload, 0, false); err != nil {
		return err
	}
	if err := s.conn.sendMessage(msgSync, nil, 0, false); err != nil {
		return err
	}
	_, _, _, err := s.conn.drainUntilReady(context.Background())
	return err
}

func (s *Stmt) NumInput() int {
	return -1
}

func (s *Stmt) Exec(args []driver.Value) (driver.Result, error) {
	return s.ExecContext(context.Background(), namedValues(args))
}

func (s *Stmt) Query(args []driver.Value) (driver.Rows, error) {
	return s.QueryContext(context.Background(), namedValues(args))
}

func (s *Stmt) ExecContext(ctx context.Context, args []driver.NamedValue) (driver.Result, error) {
	if err := s.conn.ensureOpen(ctx); err != nil {
		return nil, err
	}
	span, err := s.conn.beginOperation("stmt_exec", s.query)
	if err != nil {
		return nil, err
	}
	if s.paramCount >= 0 && s.paramCount != len(args) {
		s.conn.endOperation(span, false)
		return nil, &Error{Kind: ErrSyntax, Message: "parameter count mismatch", SQLState: "07001"}
	}
	paramValues := make([]paramValue, 0, len(args))
	for _, arg := range args {
		value, _, err := encodeParam(arg.Value)
		if err != nil {
			s.conn.endOperation(span, false)
			return nil, err
		}
		value.format = formatBinary
		paramValues = append(paramValues, value)
	}
	resultFormats := []uint16{}
	if s.conn.config.BinaryTransfer {
		resultFormats = []uint16{formatBinary}
	}
	bindPayload := buildBindPayload("", s.name, paramValues, resultFormats)
	if err := s.conn.sendMessage(msgBind, bindPayload, 0, false); err != nil {
		s.conn.endOperation(span, false)
		return nil, err
	}
	execPayload := buildExecutePayload("", 0)
	if err := s.conn.sendMessage(msgExecute, execPayload, 0, false); err != nil {
		s.conn.endOperation(span, false)
		return nil, err
	}
	if err := s.conn.sendMessage(msgSync, nil, 0, false); err != nil {
		s.conn.endOperation(span, false)
		return nil, err
	}
	tag, rows, lastID, err := s.conn.drainUntilReady(ctx)
	if err != nil {
		s.conn.endOperation(span, false)
		return nil, err
	}
	s.conn.endOperation(span, true)
	return &Result{tag: tag, rowsAffected: int64(rows), lastInsertID: int64(lastID)}, nil
}

func (s *Stmt) QueryContext(ctx context.Context, args []driver.NamedValue) (driver.Rows, error) {
	if err := s.conn.ensureOpen(ctx); err != nil {
		return nil, err
	}
	span, err := s.conn.beginOperation("stmt_query", s.query)
	if err != nil {
		return nil, err
	}
	if s.paramCount >= 0 && s.paramCount != len(args) {
		s.conn.endOperation(span, false)
		return nil, &Error{Kind: ErrSyntax, Message: "parameter count mismatch", SQLState: "07001"}
	}
	paramValues := make([]paramValue, 0, len(args))
	for _, arg := range args {
		value, _, err := encodeParam(arg.Value)
		if err != nil {
			s.conn.endOperation(span, false)
			return nil, err
		}
		value.format = formatBinary
		paramValues = append(paramValues, value)
	}
	resultFormats := []uint16{}
	if s.conn.config.BinaryTransfer {
		resultFormats = []uint16{formatBinary}
	}
	bindPayload := buildBindPayload("", s.name, paramValues, resultFormats)
	if err := s.conn.sendMessage(msgBind, bindPayload, 0, false); err != nil {
		s.conn.endOperation(span, false)
		return nil, err
	}
	execPayload := buildExecutePayload("", 0)
	if err := s.conn.sendMessage(msgExecute, execPayload, 0, false); err != nil {
		s.conn.endOperation(span, false)
		return nil, err
	}
	if err := s.conn.sendMessage(msgSync, nil, 0, false); err != nil {
		s.conn.endOperation(span, false)
		return nil, err
	}
	s.conn.endOperation(span, true)
	return newRows(s.conn, ctx), nil
}

type Tx struct {
	conn *Conn
}

func (t *Tx) Commit() error {
	if t.conn == nil {
		return nil
	}
	if err := t.conn.sendMessage(msgTxnCommit, buildTxnCommitPayload(0), 0, false); err != nil {
		return err
	}
	_, _, _, err := t.conn.drainUntilReady(context.Background())
	return err
}

func (t *Tx) Rollback() error {
	if t.conn == nil {
		return nil
	}
	if err := t.conn.sendMessage(msgTxnRollback, buildTxnRollbackPayload(0), 0, false); err != nil {
		return err
	}
	_, _, _, err := t.conn.drainUntilReady(context.Background())
	return err
}

func (t *Tx) Savepoint(name string) error {
	if t.conn == nil {
		return nil
	}
	return t.conn.Savepoint(context.Background(), name)
}

func (t *Tx) ReleaseSavepoint(name string) error {
	if t.conn == nil {
		return nil
	}
	return t.conn.ReleaseSavepoint(context.Background(), name)
}

func (t *Tx) RollbackToSavepoint(name string) error {
	if t.conn == nil {
		return nil
	}
	return t.conn.RollbackToSavepoint(context.Background(), name)
}
