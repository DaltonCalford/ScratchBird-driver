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
	"crypto/tls"
	"crypto/x509"
	"database/sql/driver"
	"encoding/pem"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"sync"
	"time"
)

const (
	queryFlagBinaryResult = 0x04
)

const (
	formatText   uint16 = 0
	formatBinary uint16 = 1
)

type Conn struct {
	config       Config
	raw          net.Conn
	mu           sync.Mutex
	closed       bool
	attachmentID [16]byte
	txnID        uint64
	sequence     uint32
	authed       bool
	pending      []protocolMessage
	params       map[string]string
}

func (c *Conn) connect(ctx context.Context) error {
	if c.raw != nil {
		return nil
	}
	if !c.config.BinaryTransfer {
		return &Error{Kind: ErrNotSupported, Message: "binary_transfer=false is not supported", SQLState: "0A000"}
	}
	if strings.EqualFold(c.config.Compression, "zstd") {
		return &Error{Kind: ErrNotSupported, Message: "compression=zstd is not supported", SQLState: "0A000"}
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
	if err := c.handshake(ctx); err != nil {
		_ = c.raw.Close()
		return err
	}
	if err := c.applySchema(ctx); err != nil {
		_ = c.raw.Close()
		return err
	}
	return nil
}

func (c *Conn) applyTLS(ctx context.Context) error {
	mode := strings.ToLower(c.config.SSLMode)
	if mode == "" {
		mode = "require"
	}
	if mode == "disable" {
		return &Error{Kind: ErrConnection, Message: "TLS is required", SQLState: "08001"}
	}
	tlsConfig, err := c.buildTLSConfig()
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

func (c *Conn) buildTLSConfig() (*tls.Config, error) {
	cfg := &tls.Config{
		MinVersion: tls.VersionTLS13,
		ServerName: c.config.Host,
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
		pool.AppendCertsFromPEM(caData)
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

func (c *Conn) handshake(ctx context.Context) error {
	c.authed = false
	c.params = map[string]string{}
	features := c.requestedFeatures()
	params := map[string]string{
		"database": c.config.Database,
		"user":     c.config.User,
	}
	if c.config.Role != "" {
		params["role"] = c.config.Role
	}
	if c.config.Application != "" {
		params["application_name"] = c.config.Application
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
		case msgParameterStatus:
			name, value, err := parseParameterStatus(msg.body)
			if err != nil {
				return err
			}
			c.params[name] = value
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
	default:
		return scram, &Error{Kind: ErrAuth, Message: "unsupported auth method", SQLState: "28000"}
	}
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
		switch msg.header.typ {
		case msgParameterDescription:
			types, err := parseParameterDescription(msg.body)
			if err != nil {
				return nil, err
			}
			paramCount = len(types)
		case msgParameterStatus:
			name, value, err := parseParameterStatus(msg.body)
			if err != nil {
				return nil, err
			}
			c.params[name] = value
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
	// ScratchBird uses implicit transactions; explicit begin is a no-op for now.
	_ = opts
	return &Tx{conn: c}, nil
}

func (c *Conn) ExecContext(ctx context.Context, query string, args []driver.NamedValue) (driver.Result, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	normalized, err := normalizeQuery(query, args)
	if err != nil {
		return nil, err
	}
	if len(normalized.args) == 0 {
		if err := c.sendSimpleQuery(normalized.sql, ctx); err != nil {
			return nil, err
		}
		tag, rows, lastID, err := c.drainUntilReady(ctx)
		if err != nil {
			return nil, err
		}
		return &Result{tag: tag, rowsAffected: int64(rows), lastInsertID: int64(lastID)}, nil
	}
	if err := c.sendExtendedQuery(normalized.sql, normalized.args, ctx); err != nil {
		return nil, err
	}
	tag, rows, lastID, err := c.drainUntilReady(ctx)
	if err != nil {
		return nil, err
	}
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
	if len(normalized.args) == 0 {
		if err := c.sendSimpleQuery(normalized.sql, ctx); err != nil {
			return nil, err
		}
		return newRows(c, ctx), nil
	}
	if err := c.sendExtendedQuery(normalized.sql, normalized.args, ctx); err != nil {
		return nil, err
	}
	return newRows(c, ctx), nil
}

func (c *Conn) sendSimpleQuery(sql string, ctx context.Context) error {
	flags := uint32(0)
	if c.config.BinaryTransfer {
		flags |= queryFlagBinaryResult
	}
	maxRows := uint32(c.config.FetchSize)
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
		switch msg.header.typ {
		case msgParameterDescription:
			types, err := parseParameterDescription(msg.body)
			if err != nil {
				return err
			}
			paramCount = len(types)
		case msgParameterStatus:
			name, value, err := parseParameterStatus(msg.body)
			if err != nil {
				return err
			}
			c.params[name] = value
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
		return &Error{Kind: ErrProtocol, Message: "parameter count mismatch", SQLState: "07001"}
	}
	resultFormats := []uint16{}
	if c.config.BinaryTransfer {
		resultFormats = []uint16{formatBinary}
	}
	bindPayload := buildBindPayload("", "", paramValues, resultFormats)
	if err := c.sendMessage(msgBind, bindPayload, 0, false); err != nil {
		return err
	}
	maxRows := uint32(c.config.FetchSize)
	execPayload := buildExecutePayload("", maxRows)
	if err := c.sendMessage(msgExecute, execPayload, 0, false); err != nil {
		return err
	}
	return c.sendMessage(msgSync, nil, 0, false)
}

func (c *Conn) Ping(ctx context.Context) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	if err := c.sendSimpleQuery("SELECT 1", ctx); err != nil {
		return err
	}
	_, _, _, err := c.drainUntilReady(ctx)
	return err
}

func (c *Conn) ResetSession(ctx context.Context) error {
	_ = ctx
	return nil
}

func (c *Conn) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.closed {
		return nil
	}
	c.closed = true
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
	defer c.mu.Unlock()
	if c.closed {
		return errors.New("connection is closed")
	}
	if c.raw == nil {
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

func quoteIdentifier(name string) string {
	return `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
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
	if s.paramCount >= 0 && s.paramCount != len(args) {
		return nil, &Error{Kind: ErrProtocol, Message: "parameter count mismatch", SQLState: "07001"}
	}
	paramValues := make([]paramValue, 0, len(args))
	for _, arg := range args {
		value, _, err := encodeParam(arg.Value)
		if err != nil {
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
		return nil, err
	}
	execPayload := buildExecutePayload("", 0)
	if err := s.conn.sendMessage(msgExecute, execPayload, 0, false); err != nil {
		return nil, err
	}
	if err := s.conn.sendMessage(msgSync, nil, 0, false); err != nil {
		return nil, err
	}
	tag, rows, lastID, err := s.conn.drainUntilReady(ctx)
	if err != nil {
		return nil, err
	}
	return &Result{tag: tag, rowsAffected: int64(rows), lastInsertID: int64(lastID)}, nil
}

func (s *Stmt) QueryContext(ctx context.Context, args []driver.NamedValue) (driver.Rows, error) {
	if err := s.conn.ensureOpen(ctx); err != nil {
		return nil, err
	}
	if s.paramCount >= 0 && s.paramCount != len(args) {
		return nil, &Error{Kind: ErrProtocol, Message: "parameter count mismatch", SQLState: "07001"}
	}
	paramValues := make([]paramValue, 0, len(args))
	for _, arg := range args {
		value, _, err := encodeParam(arg.Value)
		if err != nil {
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
		return nil, err
	}
	execPayload := buildExecutePayload("", 0)
	if err := s.conn.sendMessage(msgExecute, execPayload, 0, false); err != nil {
		return nil, err
	}
	if err := s.conn.sendMessage(msgSync, nil, 0, false); err != nil {
		return nil, err
	}
	return newRows(s.conn, ctx), nil
}

type Tx struct {
	conn *Conn
}

func (t *Tx) Commit() error {
	return nil
}

func (t *Tx) Rollback() error {
	return nil
}
