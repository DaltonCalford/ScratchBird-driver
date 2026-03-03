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
use ScratchBird\PDO\ScratchBirdConnectionException;
use ScratchBird\PDO\ScratchBirdNotSupportedException;

final class ConnectionConnTest extends TestCase
{
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

    public function testBuildStartupFeaturesSkipsCompressionForS1Safety(): void
    {
        $cfg = new Config();
        $cfg->binaryTransfer = false;
        $cfg->compression = 'zstd';
        $conn = $this->newConnectionWithoutConstructor($cfg);
        $features = $this->invokeBuildStartupFeatures($conn);
        $this->assertSame(0, $features);
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

    private function invokeConnect(Connection $conn): void
    {
        $class = new ReflectionClass(Connection::class);
        $method = $class->getMethod('connect');
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
}
