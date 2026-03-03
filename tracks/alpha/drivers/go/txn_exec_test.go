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
	"database/sql"
	"database/sql/driver"
	"encoding/binary"
	"fmt"
	"net"
	"strings"
	"testing"
)

func TestBeginTxRejectsUnsupportedIsolation(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()

	conn := &Conn{
		config: defaultConfig(),
		raw:    client,
	}

	_, err := conn.BeginTx(context.Background(), driver.TxOptions{
		Isolation: driver.IsolationLevel(sql.LevelSnapshot),
	})
	requireDriverError(t, err, ErrNotSupported, "0A000")
}

func TestBeginTxEncodesIsolationAndReadOnly(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()

	errCh := make(chan error, 1)
	go func() {
		defer close(errCh)
		defer server.Close()

		msg, err := readMessage(server)
		if err != nil {
			errCh <- fmt.Errorf("read begin message: %w", err)
			return
		}
		if msg.header.typ != msgTxnBegin {
			errCh <- fmt.Errorf("expected %v, got %v", msgTxnBegin, msg.header.typ)
			return
		}
		if len(msg.body) < 12 {
			errCh <- fmt.Errorf("txn begin payload too short: %d", len(msg.body))
			return
		}

		flags := binary.LittleEndian.Uint16(msg.body[0:2])
		wantFlags := uint16(txnFlagHasIsolation | txnFlagHasAccess)
		if flags != wantFlags {
			errCh <- fmt.Errorf("unexpected txn flags: got %d want %d", flags, wantFlags)
			return
		}
		if msg.body[4] != isolationSerializable {
			errCh <- fmt.Errorf("unexpected isolation byte: got %d want %d", msg.body[4], isolationSerializable)
			return
		}
		if msg.body[5] != 1 {
			errCh <- fmt.Errorf("unexpected access mode byte: got %d want 1", msg.body[5])
			return
		}

		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 77, 0))); err != nil {
			errCh <- fmt.Errorf("write ready: %w", err)
			return
		}

		errCh <- nil
	}()

	conn := &Conn{
		config: defaultConfig(),
		raw:    client,
	}

	tx, err := conn.BeginTx(context.Background(), driver.TxOptions{
		Isolation: driver.IsolationLevel(sql.LevelSerializable),
		ReadOnly:  true,
	})
	if err != nil {
		t.Fatalf("begin tx failed: %v", err)
	}
	if tx == nil {
		t.Fatalf("expected tx, got nil")
	}
	if conn.txnID != 77 {
		t.Fatalf("expected txn id 77, got %d", conn.txnID)
	}
	if err := <-errCh; err != nil {
		t.Fatal(err)
	}
}

func TestSavepointLifecycleEncodesWireCalls(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()

	errCh := make(chan error, 1)
	go func() {
		defer close(errCh)
		defer server.Close()

		if err := expectMessage(server, msgTxnBegin); err != nil {
			errCh <- err
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 77, 0))); err != nil {
			errCh <- fmt.Errorf("write begin ready: %w", err)
			return
		}

		savepointMsg, err := readMessage(server)
		if err != nil {
			errCh <- fmt.Errorf("read savepoint message: %w", err)
			return
		}
		if savepointMsg.header.typ != msgTxnSavepoint {
			errCh <- fmt.Errorf("expected %v, got %v", msgTxnSavepoint, savepointMsg.header.typ)
			return
		}
		if !containsPayloadText(savepointMsg.body, "sp1") {
			errCh <- fmt.Errorf("savepoint payload missing name")
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 77, 0))); err != nil {
			errCh <- fmt.Errorf("write savepoint ready: %w", err)
			return
		}

		rollbackToMsg, err := readMessage(server)
		if err != nil {
			errCh <- fmt.Errorf("read rollback-to message: %w", err)
			return
		}
		if rollbackToMsg.header.typ != msgTxnRollbackTo {
			errCh <- fmt.Errorf("expected %v, got %v", msgTxnRollbackTo, rollbackToMsg.header.typ)
			return
		}
		if !containsPayloadText(rollbackToMsg.body, "sp1") {
			errCh <- fmt.Errorf("rollback-to payload missing name")
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 77, 0))); err != nil {
			errCh <- fmt.Errorf("write rollback-to ready: %w", err)
			return
		}

		releaseMsg, err := readMessage(server)
		if err != nil {
			errCh <- fmt.Errorf("read release message: %w", err)
			return
		}
		if releaseMsg.header.typ != msgTxnRelease {
			errCh <- fmt.Errorf("expected %v, got %v", msgTxnRelease, releaseMsg.header.typ)
			return
		}
		if !containsPayloadText(releaseMsg.body, "sp1") {
			errCh <- fmt.Errorf("release payload missing name")
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 77, 0))); err != nil {
			errCh <- fmt.Errorf("write release ready: %w", err)
			return
		}

		if err := expectMessage(server, msgTxnCommit); err != nil {
			errCh <- err
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 0, 0))); err != nil {
			errCh <- fmt.Errorf("write commit ready: %w", err)
			return
		}
		errCh <- nil
	}()

	conn := &Conn{
		config: defaultConfig(),
		raw:    client,
	}
	txDriver, err := conn.BeginTx(context.Background(), driver.TxOptions{})
	if err != nil {
		t.Fatalf("begin tx failed: %v", err)
	}
	tx, ok := txDriver.(*Tx)
	if !ok {
		t.Fatalf("expected *Tx, got %T", txDriver)
	}
	if err := tx.Savepoint("sp1"); err != nil {
		t.Fatalf("savepoint failed: %v", err)
	}
	if err := tx.RollbackToSavepoint("sp1"); err != nil {
		t.Fatalf("rollback to savepoint failed: %v", err)
	}
	if err := tx.ReleaseSavepoint("sp1"); err != nil {
		t.Fatalf("release savepoint failed: %v", err)
	}
	if err := tx.Commit(); err != nil {
		t.Fatalf("commit failed: %v", err)
	}
	if conn.txnID != 0 {
		t.Fatalf("expected txn id 0 after commit, got %d", conn.txnID)
	}
	if err := <-errCh; err != nil {
		t.Fatal(err)
	}
}

func TestSavepointRejectsWhenTransactionInactive(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()

	conn := &Conn{
		config: defaultConfig(),
		raw:    client,
	}
	err := conn.Savepoint(context.Background(), "sp1")
	requireDriverError(t, err, ErrTransaction, "25000")
}

func TestSavepointRejectsBlankName(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()

	conn := &Conn{
		config: defaultConfig(),
		raw:    client,
		txnID:  99,
	}
	err := conn.Savepoint(context.Background(), "   ")
	requireDriverError(t, err, ErrSyntax, "42601")
}

func TestExecContextSimpleIgnoresFetchSizeForExec(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()

	errCh := make(chan error, 1)
	go func() {
		defer close(errCh)
		defer server.Close()

		msg, err := readMessage(server)
		if err != nil {
			errCh <- fmt.Errorf("read query message: %w", err)
			return
		}
		if msg.header.typ != msgQuery {
			errCh <- fmt.Errorf("expected %v, got %v", msgQuery, msg.header.typ)
			return
		}
		if len(msg.body) < 12 {
			errCh <- fmt.Errorf("query payload too short: %d", len(msg.body))
			return
		}
		maxRows := binary.LittleEndian.Uint32(msg.body[4:8])
		if maxRows != 0 {
			errCh <- fmt.Errorf("exec simple query maxRows mismatch: got %d want 0", maxRows)
			return
		}

		if _, err := server.Write(encodeMessage(messageHeader{typ: msgCommandComplete}, testCommandCompletePayload(3, 9, "UPDATE 3"))); err != nil {
			errCh <- fmt.Errorf("write command complete: %w", err)
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 88, 0))); err != nil {
			errCh <- fmt.Errorf("write ready: %w", err)
			return
		}

		errCh <- nil
	}()

	cfg := defaultConfig()
	cfg.FetchSize = 128
	conn := &Conn{
		config: cfg,
		raw:    client,
	}

	result, err := conn.ExecContext(context.Background(), "UPDATE demo SET value = 1", nil)
	if err != nil {
		t.Fatalf("exec failed: %v", err)
	}
	rows, err := result.RowsAffected()
	if err != nil {
		t.Fatalf("rows affected failed: %v", err)
	}
	if rows != 3 {
		t.Fatalf("rows affected mismatch: got %d want 3", rows)
	}
	lastID, err := result.LastInsertId()
	if err != nil {
		t.Fatalf("last insert id failed: %v", err)
	}
	if lastID != 9 {
		t.Fatalf("last insert id mismatch: got %d want 9", lastID)
	}
	if conn.txnID != 88 {
		t.Fatalf("expected txn id 88, got %d", conn.txnID)
	}
	if err := <-errCh; err != nil {
		t.Fatal(err)
	}
}

func TestExecContextExtendedIgnoresFetchSizeForExec(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()

	errCh := make(chan error, 1)
	go func() {
		defer close(errCh)
		defer server.Close()

		if err := expectMessage(server, msgParse); err != nil {
			errCh <- err
			return
		}
		if err := expectMessage(server, msgDescribe); err != nil {
			errCh <- err
			return
		}
		if err := expectMessage(server, msgSync); err != nil {
			errCh <- err
			return
		}

		if _, err := server.Write(encodeMessage(messageHeader{typ: msgParameterDescription}, testParameterDescriptionPayload(oidInt4))); err != nil {
			errCh <- fmt.Errorf("write parameter description: %w", err)
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 90, 0))); err != nil {
			errCh <- fmt.Errorf("write describe ready: %w", err)
			return
		}

		if err := expectMessage(server, msgBind); err != nil {
			errCh <- err
			return
		}

		execMsg, err := readMessage(server)
		if err != nil {
			errCh <- fmt.Errorf("read execute message: %w", err)
			return
		}
		if execMsg.header.typ != msgExecute {
			errCh <- fmt.Errorf("expected %v, got %v", msgExecute, execMsg.header.typ)
			return
		}
		maxRows, err := executeMaxRows(execMsg.body)
		if err != nil {
			errCh <- err
			return
		}
		if maxRows != 0 {
			errCh <- fmt.Errorf("exec extended maxRows mismatch: got %d want 0", maxRows)
			return
		}

		if err := expectMessage(server, msgSync); err != nil {
			errCh <- err
			return
		}

		if _, err := server.Write(encodeMessage(messageHeader{typ: msgCommandComplete}, testCommandCompletePayload(1, 0, "UPDATE 1"))); err != nil {
			errCh <- fmt.Errorf("write command complete: %w", err)
			return
		}
		if _, err := server.Write(encodeMessage(messageHeader{typ: msgReady}, testReadyPayload(0, 91, 0))); err != nil {
			errCh <- fmt.Errorf("write ready: %w", err)
			return
		}

		errCh <- nil
	}()

	cfg := defaultConfig()
	cfg.FetchSize = 64
	conn := &Conn{
		config: cfg,
		raw:    client,
	}

	args := []driver.NamedValue{
		{Ordinal: 1, Value: int64(42)},
	}
	result, err := conn.ExecContext(context.Background(), "UPDATE demo SET value = ?", args)
	if err != nil {
		t.Fatalf("exec failed: %v", err)
	}
	rows, err := result.RowsAffected()
	if err != nil {
		t.Fatalf("rows affected failed: %v", err)
	}
	if rows != 1 {
		t.Fatalf("rows affected mismatch: got %d want 1", rows)
	}
	if conn.txnID != 91 {
		t.Fatalf("expected txn id 91, got %d", conn.txnID)
	}
	if err := <-errCh; err != nil {
		t.Fatal(err)
	}
}

func expectMessage(conn net.Conn, want messageType) error {
	msg, err := readMessage(conn)
	if err != nil {
		return fmt.Errorf("read %v message: %w", want, err)
	}
	if msg.header.typ != want {
		return fmt.Errorf("expected %v, got %v", want, msg.header.typ)
	}
	return nil
}

func executeMaxRows(payload []byte) (uint32, error) {
	if len(payload) < 8 {
		return 0, fmt.Errorf("execute payload too short: %d", len(payload))
	}
	portalLen := int(binary.LittleEndian.Uint32(payload[0:4]))
	if len(payload) < 4+portalLen+4 {
		return 0, fmt.Errorf("execute payload truncated: %d", len(payload))
	}
	return binary.LittleEndian.Uint32(payload[4+portalLen : 8+portalLen]), nil
}

func containsPayloadText(payload []byte, value string) bool {
	return strings.Contains(string(payload), value)
}

func testReadyPayload(status byte, txnID, epoch uint64) []byte {
	payload := make([]byte, 20)
	payload[0] = status
	binary.LittleEndian.PutUint64(payload[4:12], txnID)
	binary.LittleEndian.PutUint64(payload[12:20], epoch)
	return payload
}

func testCommandCompletePayload(rows, lastID uint64, tag string) []byte {
	payload := make([]byte, 20+len(tag)+1)
	binary.LittleEndian.PutUint64(payload[4:12], rows)
	binary.LittleEndian.PutUint64(payload[12:20], lastID)
	copy(payload[20:], []byte(tag))
	return payload
}

func testParameterDescriptionPayload(typeOIDs ...uint32) []byte {
	payload := make([]byte, 4+len(typeOIDs)*4)
	binary.LittleEndian.PutUint16(payload[0:2], uint16(len(typeOIDs)))
	offset := 4
	for _, oid := range typeOIDs {
		binary.LittleEndian.PutUint32(payload[offset:offset+4], oid)
		offset += 4
	}
	return payload
}
