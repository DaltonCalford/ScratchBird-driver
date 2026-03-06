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
use ScratchBird\PDO\ScratchBirdAuthException;
use ScratchBird\PDO\ScratchBirdConnectionException;
use ScratchBird\PDO\ScratchBirdNotSupportedException;

final class ConnectionConnTest extends TestCase
{
    private const MCP_MSG_CONNECT_RESPONSE = 0x02;
    private const MCP_MSG_AUTH_CHALLENGE = 0x12;
    private const MCP_MSG_AUTH_RESPONSE = 0x11;
    private const MCP_MSG_STATUS_RESPONSE = 0x64;
    private const MCP_MSG_HELLO = 0x65;
    private const MCP_MSG_AUTH_START = 0x66;
    private const MCP_MSG_AUTH_CONTINUE = 0x67;
    private const MCP_MSG_DB_CONNECT = 0x69;

    public function testBinaryTransferFalseDoesNotThrowNotSupportedDuringConnect(): void
    {
        $conn = $this->newConnectionWithoutConstructor(
            Config::fromDsn('scratchbird://user:pass@127.0.0.1:1/mydb?connect_timeout=1&binary_transfer=false')
        );

        try {
            $this->invokeConnect($conn);
            $this->fail('Expected connect to fail without a running server');
        } catch (ScratchBirdNotSupportedException $ex) {
            $this->fail('binary_transfer=false should not be rejected at connect validation');
        } catch (ScratchBirdConnectionException $ex) {
            $this->assertNotSame('0A000', $ex->sqlState);
        }
    }

    public function testCompressionZstdDoesNotThrowNotSupportedDuringConnect(): void
    {
        $conn = $this->newConnectionWithoutConstructor(
            Config::fromDsn('scratchbird://user:pass@127.0.0.1:1/mydb?connect_timeout=1&compression=zstd')
        );

        try {
            $this->invokeConnect($conn);
            $this->fail('Expected connect to fail without a running server');
        } catch (ScratchBirdNotSupportedException $ex) {
            $this->fail('compression=zstd should not be rejected at connect validation');
        } catch (ScratchBirdConnectionException $ex) {
            $this->assertNotSame('0A000', $ex->sqlState);
        }
    }

    public function testBuildStartupFeaturesIncludesStreamingWhenBinaryTransferEnabled(): void
    {
        $cfg = new Config();
        $cfg->binaryTransfer = true;
        $cfg->compression = 'off';
        $conn = $this->newConnectionWithoutConstructor($cfg);
        $features = $this->invokeBuildStartupFeatures($conn);
        $this->assertSame(Protocol::FEATURE_STREAMING, $features);
    }

    public function testBuildStartupFeaturesIncludesCompressionWhenConfigured(): void
    {
        $cfg = new Config();
        $cfg->binaryTransfer = false;
        $cfg->compression = 'zstd';
        $conn = $this->newConnectionWithoutConstructor($cfg);
        $features = $this->invokeBuildStartupFeatures($conn);
        $this->assertSame(Protocol::FEATURE_COMPRESSION, $features);
    }

    public function testBuildStartupFeaturesIncludesCompressionAndStreamingTogether(): void
    {
        $cfg = new Config();
        $cfg->binaryTransfer = true;
        $cfg->compression = 'zstd';
        $conn = $this->newConnectionWithoutConstructor($cfg);
        $features = $this->invokeBuildStartupFeatures($conn);
        $this->assertSame(Protocol::FEATURE_COMPRESSION | Protocol::FEATURE_STREAMING, $features);
    }

    public function testApplyTlsAllowsSslModeDisableWithoutHandshake(): void
    {
        [$client, $server] = $this->newSocketPair();
        $cfg = Config::fromDsn('scratchbird://user:pass@localhost:3092/mydb?sslmode=disable');
        $conn = $this->newConnectionWithSocket($cfg, $client);

        try {
            $this->invokeApplyTls($conn);
            fwrite($client, "PING");
            $this->assertSame("PING", $this->readExact($server, 4));
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    public function testPerformManagerConnectSuccessFastPath(): void
    {
        [$client, $server] = $this->newSocketPair();
        $cfg = Config::fromDsn('scratchbird://user:pass@localhost:3092/mydb?front_door_mode=manager_proxy&manager_auth_token=token');
        $conn = $this->newConnectionWithSocket($cfg, $client);

        try {
            $this->queueManagerFrame($server, self::MCP_MSG_STATUS_RESPONSE, '');
            $this->queueManagerFrame($server, self::MCP_MSG_AUTH_RESPONSE, $this->managerAuthPayloadSuccess());
            $this->queueManagerFrame($server, self::MCP_MSG_CONNECT_RESPONSE, $this->managerConnectPayloadSuccess());

            $this->invokePerformManagerConnect($conn);

            $types = [
                $this->readManagerFrameType($server),
                $this->readManagerFrameType($server),
                $this->readManagerFrameType($server),
            ];
            $this->assertSame(
                [self::MCP_MSG_HELLO, self::MCP_MSG_AUTH_START, self::MCP_MSG_DB_CONNECT],
                $types
            );
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    public function testPerformManagerConnectSuccessChallengePath(): void
    {
        [$client, $server] = $this->newSocketPair();
        $cfg = Config::fromDsn('scratchbird://user:pass@localhost:3092/mydb?front_door_mode=manager_proxy&manager_auth_token=token');
        $cfg->managerAuthFastPath = false;
        $conn = $this->newConnectionWithSocket($cfg, $client);

        try {
            $this->queueManagerFrame($server, self::MCP_MSG_STATUS_RESPONSE, '');
            $this->queueManagerFrame($server, self::MCP_MSG_AUTH_CHALLENGE, '');
            $this->queueManagerFrame($server, self::MCP_MSG_AUTH_RESPONSE, $this->managerAuthPayloadSuccess());
            $this->queueManagerFrame($server, self::MCP_MSG_CONNECT_RESPONSE, $this->managerConnectPayloadSuccess());

            $this->invokePerformManagerConnect($conn);

            $types = [
                $this->readManagerFrameType($server),
                $this->readManagerFrameType($server),
                $this->readManagerFrameType($server),
                $this->readManagerFrameType($server),
            ];
            $this->assertSame(
                [self::MCP_MSG_HELLO, self::MCP_MSG_AUTH_START, self::MCP_MSG_AUTH_CONTINUE, self::MCP_MSG_DB_CONNECT],
                $types
            );
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    public function testPerformManagerConnectMapsAuthFailureToTypedException(): void
    {
        [$client, $server] = $this->newSocketPair();
        $cfg = Config::fromDsn('scratchbird://user:pass@localhost:3092/mydb?front_door_mode=manager_proxy&manager_auth_token=token');
        $conn = $this->newConnectionWithSocket($cfg, $client);

        try {
            $this->queueManagerFrame($server, self::MCP_MSG_STATUS_RESPONSE, '');
            $this->queueManagerFrame($server, self::MCP_MSG_AUTH_RESPONSE, $this->managerAuthPayloadFailure('bad token'));

            try {
                $this->invokePerformManagerConnect($conn);
                $this->fail('Expected manager auth failure to throw');
            } catch (ScratchBirdAuthException $ex) {
                $this->assertStringContainsString('bad token', $ex->getMessage());
                $this->assertSame('28000', $ex->sqlState);
            }
        } finally {
            fclose($client);
            fclose($server);
        }
    }

    private function newConnectionWithoutConstructor(Config $cfg): Connection
    {
        $class = new ReflectionClass(Connection::class);
        /** @var Connection $conn */
        $conn = $class->newInstanceWithoutConstructor();
        $prop = $class->getProperty('config');
        $prop->setAccessible(true);
        $prop->setValue($conn, $cfg);
        return $conn;
    }

    private function newConnectionWithSocket(Config $cfg, $socket): Connection
    {
        $class = new ReflectionClass(Connection::class);
        /** @var Connection $conn */
        $conn = $class->newInstanceWithoutConstructor();
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
        $this->setPrivate($conn, 'hasLastInsertId', false);
        $this->setPrivate($conn, 'lastInsertIdValue', 0);
        return $conn;
    }

    private function newSocketPair(): array
    {
        $pair = stream_socket_pair(STREAM_PF_UNIX, STREAM_SOCK_STREAM, STREAM_IPPROTO_IP);
        if ($pair === false) {
            $this->fail('stream_socket_pair() is required for manager wire-fixture tests');
        }
        stream_set_blocking($pair[0], true);
        stream_set_blocking($pair[1], true);
        return $pair;
    }

    private function setPrivate(object $object, string $property, mixed $value): void
    {
        $class = new ReflectionClass($object);
        $prop = $class->getProperty($property);
        $prop->setAccessible(true);
        $prop->setValue($object, $value);
    }

    private function invokeConnect(Connection $conn): void
    {
        $class = new ReflectionClass(Connection::class);
        $method = $class->getMethod('connect');
        $method->setAccessible(true);
        $method->invoke($conn);
    }

    private function invokePerformManagerConnect(Connection $conn): void
    {
        $class = new ReflectionClass(Connection::class);
        $method = $class->getMethod('performManagerConnect');
        $method->setAccessible(true);
        $method->invoke($conn);
    }

    private function invokeBuildStartupFeatures(Connection $conn): int
    {
        $class = new ReflectionClass(Connection::class);
        $method = $class->getMethod('buildStartupFeatures');
        $method->setAccessible(true);
        /** @var int $features */
        $features = $method->invoke($conn);
        return $features;
    }

    private function invokeApplyTls(Connection $conn): void
    {
        $class = new ReflectionClass(Connection::class);
        $method = $class->getMethod('applyTls');
        $method->setAccessible(true);
        $method->invoke($conn);
    }

    private function queueManagerFrame($server, int $type, string $payload): void
    {
        $frame = pack('V', 0x42444253)
            . pack('v', 0x0101)
            . chr($type)
            . chr(0)
            . pack('V', strlen($payload))
            . $payload;
        $this->writeExact($server, $frame);
    }

    private function readManagerFrameType($server): int
    {
        $header = $this->readExact($server, 12);
        $magic = unpack('V', substr($header, 0, 4))[1];
        $this->assertSame(0x42444253, $magic);
        $version = unpack('v', substr($header, 4, 2))[1];
        $this->assertSame(0x0101, $version);
        $type = ord($header[6]);
        $length = unpack('V', substr($header, 8, 4))[1];
        if ($length > 0) {
            $this->readExact($server, $length);
        }
        return $type;
    }

    private function managerAuthPayloadSuccess(): string
    {
        return chr(0) . pack('V', 0) . str_repeat("\0", 256);
    }

    private function managerAuthPayloadFailure(string $message): string
    {
        return chr(1) . pack('V', 0) . str_pad($message, 256, "\0");
    }

    private function managerConnectPayloadSuccess(): string
    {
        return chr(0) . str_repeat("\0", 1 + 2 + 2 + 16 + 64 + 32 - 1);
    }

    private function writeExact($stream, string $data): void
    {
        $offset = 0;
        $length = strlen($data);
        while ($offset < $length) {
            $written = fwrite($stream, substr($data, $offset));
            if ($written === false || $written === 0) {
                $this->fail('Failed writing fixture frame');
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
                $this->fail('Failed reading fixture frame');
            }
            $data .= $chunk;
        }
        return $data;
    }
}
