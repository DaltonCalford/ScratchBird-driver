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
require_once dirname(__DIR__) . '/src/CircuitBreaker.php';

if (!class_exists('ScratchBird\\TelemetryCollector')) {
    class MetadataExecutionTelemetryCollectorStub
    {
        public function startSpan(string $name): mixed
        {
            return null;
        }

        public function endSpan(mixed $span, bool $success = true): void
        {
        }

        public static function sanitizeQuery(?string $sql): ?string
        {
            return $sql;
        }
    }
    class_alias(MetadataExecutionTelemetryCollectorStub::class, 'ScratchBird\\TelemetryCollector');
}

use PHPUnit\Framework\TestCase;
use ScratchBird\CircuitBreaker;
use ScratchBird\TelemetryCollector;
use ScratchBird\PDO\Config;
use ScratchBird\PDO\Connection;
use ScratchBird\PDO\Metadata;
use ScratchBird\PDO\Protocol;
use ScratchBird\PDO\ScratchBirdNotSupportedException;

final class MetadataExecutionTest extends TestCase
{
    public function testNormalizeCollectionNameSupportsExtendedAliases(): void
    {
        $this->assertSame('catalogs', Metadata::normalizeCollectionName('catalog'));
        $this->assertSame('primary_keys', Metadata::normalizeCollectionName('primaryKeys'));
        $this->assertSame('foreign_keys', Metadata::normalizeCollectionName('foreign-keys'));
        $this->assertSame('table_privileges', Metadata::normalizeCollectionName('table privileges'));
        $this->assertSame('column_privileges', Metadata::normalizeCollectionName('columnprivilege'));
        $this->assertSame('type_info', Metadata::normalizeCollectionName('typeinfo'));
    }

    public function testResolveCollectionQuerySupportsExtendedFamilies(): void
    {
        $this->assertSame(Metadata::CATALOGS_QUERY, Metadata::resolveCollectionQuery('catalog'));
        $this->assertSame(Metadata::PRIMARY_KEYS_QUERY, Metadata::resolveCollectionQuery('primarykeys'));
        $this->assertSame(Metadata::FOREIGN_KEYS_QUERY, Metadata::resolveCollectionQuery('foreign_keys'));
        $this->assertSame(Metadata::TABLE_PRIVILEGES_QUERY, Metadata::resolveCollectionQuery('tableprivileges'));
        $this->assertSame(Metadata::COLUMN_PRIVILEGES_QUERY, Metadata::resolveCollectionQuery('column_privileges'));
        $this->assertSame(Metadata::TYPE_INFO_QUERY, Metadata::resolveCollectionQuery('type_info'));
    }

    public function testGetSchemaExecutesResolvedMetadataQuery(): void
    {
        [$client, $server] = $this->newSocketPair();
        $conn = $this->newConnectionWithSocket($client);

        try {
            $this->queueCommandComplete($server, 0, 'SELECT 0');
            $this->queueReady($server, 0);

            $rows = $conn->getSchema('primaryKeys');
            $this->assertSame([], $rows);

            [$type, $payload] = $this->readSentMessage($server);
            $this->assertSame(Protocol::MSG_QUERY, $type);
            $this->assertSame(Metadata::PRIMARY_KEYS_QUERY, $this->extractQuerySql($payload));
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    public function testGetSchemaRejectsUnsupportedCollection(): void
    {
        [$client, $server] = $this->newSocketPair();
        $conn = $this->newConnectionWithSocket($client);

        try {
            $conn->getSchema('unsupported_collection');
            $this->fail('Expected unsupported metadata collection to throw');
        } catch (ScratchBirdNotSupportedException $ex) {
            $this->assertSame('0A000', $ex->sqlState);
            $this->assertStringContainsString('not supported', strtolower($ex->getMessage()));
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
        $this->setPrivate($conn, 'circuitBreaker', new CircuitBreaker());
        $this->setPrivate($conn, 'telemetry', new TelemetryCollector());
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
            $this->fail('stream_socket_pair() is required for metadata wire-fixture tests');
        }
        stream_set_blocking($pair[0], true);
        stream_set_blocking($pair[1], true);
        return $pair;
    }

    private function readSentMessage($server): array
    {
        $header = $this->readExact($server, Protocol::HEADER_SIZE);
        [$type, , $length] = Protocol::decodeHeader($header);
        $payload = $length > 0 ? $this->readExact($server, $length) : '';
        return [$type, $payload];
    }

    private function extractQuerySql(string $payload): string
    {
        if (strlen($payload) < 13) {
            $this->fail('query payload truncated');
        }
        $sqlPayload = substr($payload, 12);
        $terminator = strpos($sqlPayload, "\0");
        if ($terminator === false) {
            $this->fail('query payload missing terminator');
        }
        return substr($sqlPayload, 0, $terminator);
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
