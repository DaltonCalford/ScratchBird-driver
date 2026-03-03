<?php
/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */

require_once __DIR__ . '/bootstrap.php';

use PHPUnit\Framework\TestCase;
use ScratchBird\PDO\Config;
use ScratchBird\PDO\Connection;
use ScratchBird\PDO\Protocol;
use ScratchBird\PDO\ScratchBirdTransactionException;

final class ConnectionTxnExecTest extends TestCase
{
    public function testCommitWithoutActiveTransactionThrows(): void
    {
        [$client, $server] = $this->newSocketPair();
        $conn = $this->newConnectionWithSocket($client);

        try {
            $conn->commit();
            $this->fail('Expected commit() to reject when no transaction is active');
        } catch (ScratchBirdTransactionException $ex) {
            $this->assertStringContainsString('No active transaction', $ex->getMessage());
            $this->assertSame('25000', $ex->sqlState);
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    public function testTransactionLifecycleTracksStateAndWireMessages(): void
    {
        [$client, $server] = $this->newSocketPair();
        $conn = $this->newConnectionWithSocket($client);

        try {
            $this->queueReady($server, 11);
            $this->assertTrue($conn->beginTransaction());
            $this->assertTrue($conn->inTransaction());
            $this->assertSame(Protocol::MSG_TXN_BEGIN, $this->readSentMessageType($server));

            $this->queueReady($server, 11);
            $conn->savepoint('sp_one');
            $this->assertSame(Protocol::MSG_TXN_SAVEPOINT, $this->readSentMessageType($server));

            $this->queueReady($server, 0);
            $this->assertTrue($conn->commit());
            $this->assertFalse($conn->inTransaction());
            $this->assertSame(Protocol::MSG_TXN_COMMIT, $this->readSentMessageType($server));
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    public function testSavepointRejectsBlankName(): void
    {
        [$client, $server] = $this->newSocketPair();
        $conn = $this->newConnectionWithSocket($client);
        $this->setPrivate($conn, 'inTransaction', true);
        $this->setPrivate($conn, 'txnId', 12);

        try {
            $conn->savepoint('   ');
            $this->fail('Expected blank savepoint name to fail validation');
        } catch (ScratchBirdTransactionException $ex) {
            $this->assertStringContainsString('must not be empty', $ex->getMessage());
            $this->assertSame('3B001', $ex->sqlState);
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    public function testExecReturnsRowsAffectedFromCommandComplete(): void
    {
        [$client, $server] = $this->newSocketPair();
        $conn = $this->newConnectionWithSocket($client);

        try {
            $this->queueCommandComplete($server, 3, 'UPDATE 3');
            $this->queueReady($server, 0);
            $this->assertSame(3, $conn->exec('UPDATE t SET v = 1'));
            $this->assertSame(Protocol::MSG_QUERY, $this->readSentMessageType($server));
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    public function testExecReturnsFalseAndRecordsErrorState(): void
    {
        [$client, $server] = $this->newSocketPair();
        $conn = $this->newConnectionWithSocket($client);

        try {
            $this->queueError($server, '23505', 'duplicate key');
            $this->assertFalse($conn->exec('INSERT INTO t(v) VALUES (1)'));
            $this->assertSame('23505', $conn->errorCode());
            $this->assertSame('duplicate key', $conn->errorInfo()[2]);
            $this->assertSame(Protocol::MSG_QUERY, $this->readSentMessageType($server));
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    private function newConnectionWithSocket($socket): Connection
    {
        $class = new ReflectionClass(Connection::class);
        /** @var Connection $conn */
        $conn = $class->newInstanceWithoutConstructor();
        $cfg = new Config();
        $cfg->socketTimeoutMs = 0;
        $this->setPrivate($conn, 'config', $cfg);
        $this->setPrivate($conn, 'socket', $socket);
        $this->setPrivate($conn, 'attachmentId', str_repeat("\0", 16));
        $this->setPrivate($conn, 'txnId', 0);
        $this->setPrivate($conn, 'inTransaction', false);
        $this->setPrivate($conn, 'sequence', 1);
        $this->setPrivate($conn, 'lastQuerySequence', 0);
        $this->setPrivate($conn, 'lastMaxRows', 0);
        $this->setPrivate($conn, 'connected', true);
        $this->setPrivate($conn, 'attributes', []);
        $this->setPrivate($conn, 'parameters', []);
        $this->setPrivate($conn, 'lastError', ['00000', 0, null]);
        $this->setPrivate($conn, 'notificationHandlers', []);
        $this->setPrivate($conn, 'lastPlan', null);
        $this->setPrivate($conn, 'lastSblr', null);
        return $conn;
    }

    private function setPrivate(object $object, string $property, mixed $value): void
    {
        $class = new ReflectionClass($object);
        $prop = $class->getProperty($property);
        $prop->setAccessible(true);
        $prop->setValue($object, $value);
    }

    private function newSocketPair(): array
    {
        $pair = stream_socket_pair(STREAM_PF_UNIX, STREAM_SOCK_STREAM, STREAM_IPPROTO_IP);
        if ($pair === false) {
            $this->fail('stream_socket_pair() is required for wire-fixture tests');
        }
        stream_set_blocking($pair[0], true);
        stream_set_blocking($pair[1], true);
        return $pair;
    }

    private function readSentMessageType($server): int
    {
        $header = $this->readExact($server, Protocol::HEADER_SIZE);
        [$type, , $length] = Protocol::decodeHeader($header);
        if ($length > 0) {
            $this->readExact($server, $length);
        }
        return $type;
    }

    private function queueReady($server, int $txnId): void
    {
        $payload = chr(0) . "\0\0\0" . $this->uint64Le($txnId) . $this->uint64Le(0);
        $this->sendServerMessage($server, Protocol::MSG_READY, $payload);
    }

    private function queueCommandComplete($server, int $rows, string $tag): void
    {
        $payload = chr(0) . "\0\0\0" . $this->uint64Le($rows) . $this->uint64Le(0) . $tag . "\0";
        $this->sendServerMessage($server, Protocol::MSG_COMMAND_COMPLETE, $payload);
    }

    private function queueError($server, string $sqlState, string $message): void
    {
        $payload = 'SERROR' . "\0" . 'C' . $sqlState . "\0" . 'M' . $message . "\0" . "\0";
        $this->sendServerMessage($server, Protocol::MSG_ERROR, $payload);
    }

    private function sendServerMessage($server, int $type, string $payload): void
    {
        $frame = Protocol::encodeMessage($type, $payload, 0, 1, str_repeat("\0", 16), 0);
        $this->writeExact($server, $frame);
    }

    private function writeExact($stream, string $data): void
    {
        $offset = 0;
        $length = strlen($data);
        while ($offset < $length) {
            $written = fwrite($stream, substr($data, $offset));
            if ($written === false || $written === 0) {
                $this->fail('Failed writing fixture message');
            }
            $offset += $written;
        }
    }

    private function readExact($stream, int $length): string
    {
        $data = '';
        while (strlen($data) < $length) {
            $chunk = fread($stream, $length - strlen($data));
            if ($chunk === false || $chunk === '') {
                $this->fail('Failed reading fixture message');
            }
            $data .= $chunk;
        }
        return $data;
    }

    private function uint64Le(int $value): string
    {
        $lo = $value & 0xFFFFFFFF;
        $hi = ($value >> 32) & 0xFFFFFFFF;
        return pack('V2', $lo, $hi);
    }
}
