package scratchbird

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"database/sql"
	"database/sql/driver"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"sync"
	"time"
)

type Conn struct {
	config    Config
	raw       net.Conn
	sessionID []byte
	mu        sync.Mutex
	closed    bool
}

func (c *Conn) connect(ctx context.Context) error {
	if c.raw != nil {
		return nil
	}
	address := fmt.Sprintf("%s:%d", c.config.Host, c.config.Port)
	dialer := &net.Dialer{Timeout: c.config.ConnectTimeout}
	conn, err := dialer.DialContext(ctx, "tcp", address)
	if err != nil {
		return &Error{Kind: ErrConnection, Message: err.Error(), SQLState: "08001"}
	}
	c.raw = conn
	if err := c.applyTLS(ctx, address); err != nil {
		c.raw.Close()
		return err
	}
	if err := c.handshake(ctx); err != nil {
		c.raw.Close()
		return err
	}
	return nil
}

func (c *Conn) applyTLS(ctx context.Context, address string) error {
	mode := strings.ToLower(c.config.SSLMode)
	if mode == "" {
		mode = "prefer"
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
		if mode == "allow" || mode == "prefer" {
			_ = c.raw.Close()
			dialer := &net.Dialer{Timeout: c.config.ConnectTimeout}
			conn, dialErr := dialer.DialContext(ctx, "tcp", address)
			if dialErr != nil {
				return &Error{Kind: ErrConnection, Message: dialErr.Error(), SQLState: "08001"}
			}
			c.raw = conn
			return nil
		}
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
	if c.config.SSLCert != "" {
		cert, err := tls.LoadX509KeyPair(c.config.SSLCert, c.config.SSLKey)
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
	if mode == "verify-ca" {
		cfg.InsecureSkipVerify = true
		cfg.VerifyPeerCertificate = func(rawCerts [][]byte, verifiedChains [][]*x509.Certificate) error {
			opts := x509.VerifyOptions{
				Roots:         cfg.RootCAs,
				Intermediates: x509.NewCertPool(),
			}
			for i := 1; i < len(rawCerts); i++ {
				cert, err := x509.ParseCertificate(rawCerts[i])
				if err != nil {
					continue
				}
				opts.Intermediates.AddCert(cert)
			}
			leaf, err := x509.ParseCertificate(rawCerts[0])
			if err != nil {
				return err
			}
			_, err = leaf.Verify(opts)
			return err
		}
	}
	if mode == "require" || mode == "verify-full" {
		cfg.InsecureSkipVerify = false
	}
	if mode == "allow" || mode == "prefer" {
		cfg.InsecureSkipVerify = true
	}
	return cfg, nil
}

func (c *Conn) handshake(ctx context.Context) error {
	connectMsg := buildConnectRequest(c.config.Database, c.config.Application, uint32(os.Getpid()))
	if err := c.send(connectMsg); err != nil {
		return err
	}
	msg, err := c.receive()
	if err != nil {
		return err
	}
	if msg.typ != msgConnectResponse {
		return &Error{Kind: ErrConnection, Message: "unexpected connect response", SQLState: "08001"}
	}
	ok, sessionID, _, _, _, errMsg, err := parseConnectResponse(msg.body)
	if err != nil {
		return err
	}
	if !ok {
		return &Error{Kind: ErrConnection, Message: errMsg, SQLState: "08001"}
	}
	c.sessionID = sessionID
	if c.config.User != "" {
		if err := c.authenticate(ctx); err != nil {
			return err
		}
	}
	return nil
}

func (c *Conn) authenticate(ctx context.Context) error {
	scram, err := newScramClient(c.config.User)
	if err != nil {
		return err
	}
	first := []byte(scram.clientFirstMessage())
	msg, err := buildAuthRequest(c.sessionID, c.config.User, authScramSha256, first)
	if err != nil {
		return err
	}
	if err := c.send(msg); err != nil {
		return err
	}
	reply, err := c.receive()
	if err != nil {
		return err
	}
	if reply.typ != msgAuthResponse {
		return &Error{Kind: ErrAuth, Message: "unexpected auth response", SQLState: "28000"}
	}
	status, _, errMsg, extra, err := parseAuthResponse(reply.body)
	if err != nil {
		return err
	}
	if status != authContinue {
		return &Error{Kind: ErrAuth, Message: errMsg, SQLState: "28000"}
	}
	clientFinal, err := scram.handleServerFirst(c.config.Password, string(extra))
	if err != nil {
		return err
	}
	msg, err = buildAuthRequest(c.sessionID, c.config.User, authScramSha256, []byte(clientFinal))
	if err != nil {
		return err
	}
	if err := c.send(msg); err != nil {
		return err
	}
	reply, err = c.receive()
	if err != nil {
		return err
	}
	status, _, errMsg, extra, err = parseAuthResponse(reply.body)
	if err != nil {
		return err
	}
	if status != authOK {
		return &Error{Kind: ErrAuth, Message: errMsg, SQLState: "28000"}
	}
	if len(extra) > 0 {
		if err := scram.verifyServerFinal(string(extra)); err != nil {
			return err
		}
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
	return &Stmt{conn: c, query: query}, nil
}

func (c *Conn) Begin() (driver.Tx, error) {
	return c.BeginTx(context.Background(), driver.TxOptions{})
}

func (c *Conn) BeginTx(ctx context.Context, opts driver.TxOptions) (driver.Tx, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	isolation := byte(0)
	switch opts.Isolation {
	case driver.IsolationLevel(sql.LevelReadCommitted):
		isolation = 1
	case driver.IsolationLevel(sql.LevelSerializable):
		isolation = 2
	}
	msg, err := buildBegin(c.sessionID, isolation, opts.ReadOnly)
	if err != nil {
		return nil, err
	}
	if err := c.send(msg); err != nil {
		return nil, err
	}
	if err := c.drainUntilComplete(); err != nil {
		return nil, err
	}
	return &Tx{conn: c}, nil
}

func (c *Conn) ExecContext(ctx context.Context, query string, args []driver.NamedValue) (driver.Result, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	sql, err := rewriteQuery(query, args)
	if err != nil {
		return nil, err
	}
	msg, err := buildQuery(c.sessionID, sql, 0)
	if err != nil {
		return nil, err
	}
	if err := c.send(msg); err != nil {
		return nil, err
	}
	tag, rows, err := c.drainUntilComplete()
	if err != nil {
		return nil, err
	}
	return &Result{tag: tag, rowsAffected: rows}, nil
}

func (c *Conn) QueryContext(ctx context.Context, query string, args []driver.NamedValue) (driver.Rows, error) {
	if err := c.ensureOpen(ctx); err != nil {
		return nil, err
	}
	sql, err := rewriteQuery(query, args)
	if err != nil {
		return nil, err
	}
	msg, err := buildQuery(c.sessionID, sql, 0)
	if err != nil {
		return nil, err
	}
	if err := c.send(msg); err != nil {
		return nil, err
	}
	return &Rows{conn: c}, nil
}

func (c *Conn) Ping(ctx context.Context) error {
	if err := c.ensureOpen(ctx); err != nil {
		return err
	}
	msg, err := buildQuery(c.sessionID, "SELECT 1", 0)
	if err != nil {
		return err
	}
	if err := c.send(msg); err != nil {
		return err
	}
	_, _, err = c.drainUntilComplete()
	return err
}

func (c *Conn) ResetSession(ctx context.Context) error {
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
	if c.sessionID != nil {
		if msg, err := buildDisconnect(c.sessionID); err == nil {
			_ = c.send(msg)
		}
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

func (c *Conn) send(payload []byte) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.raw == nil {
		return errors.New("connection not open")
	}
	if c.config.SocketTimeout > 0 {
		_ = c.raw.SetWriteDeadline(time.Now().Add(c.config.SocketTimeout))
	}
	_, err := c.raw.Write(payload)
	return err
}

func (c *Conn) receive() (protocolMessage, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.raw == nil {
		return protocolMessage{}, errors.New("connection not open")
	}
	if c.config.SocketTimeout > 0 {
		_ = c.raw.SetReadDeadline(time.Now().Add(c.config.SocketTimeout))
	}
	return readMessage(c.raw)
}

func (c *Conn) drainUntilComplete() (string, int64, error) {
	var tag string
	var rows int64
	for {
		msg, err := c.receive()
		if err != nil {
			return "", 0, err
		}
		switch msg.typ {
		case msgQueryError:
			return "", 0, buildQueryError(msg.body)
		case msgCommandComplete:
			var err error
			tag, rows, err = parseCommandComplete(msg.body)
			if err != nil {
				return "", 0, err
			}
		case msgEndResults:
			return tag, rows, nil
		}
	}
}

func buildQueryError(payload []byte) error {
	code, sqlState, msg, detail, hint, err := parseQueryError(payload)
	if err != nil {
		return err
	}
	return &Error{
		Kind:     mapSQLState(sqlState),
		Code:     code,
		SQLState: sqlState,
		Message:  msg,
		Detail:   detail,
		Hint:     hint,
	}
}

type Stmt struct {
	conn  *Conn
	query string
}

func (s *Stmt) Close() error {
	return nil
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
	return s.conn.ExecContext(ctx, s.query, args)
}

func (s *Stmt) QueryContext(ctx context.Context, args []driver.NamedValue) (driver.Rows, error) {
	return s.conn.QueryContext(ctx, s.query, args)
}

type Tx struct {
	conn *Conn
}

func (t *Tx) Commit() error {
	msg, err := buildCommit(t.conn.sessionID)
	if err != nil {
		return err
	}
	if err := t.conn.send(msg); err != nil {
		return err
	}
	_, _, err = t.conn.drainUntilComplete()
	return err
}

func (t *Tx) Rollback() error {
	msg, err := buildRollback(t.conn.sessionID)
	if err != nil {
		return err
	}
	if err := t.conn.send(msg); err != nil {
		return err
	}
	_, _, err = t.conn.drainUntilComplete()
	return err
}
