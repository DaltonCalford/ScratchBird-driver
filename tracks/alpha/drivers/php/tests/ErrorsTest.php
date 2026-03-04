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
use ScratchBird\PDO\Connection;
use ScratchBird\PDO\ErrorMapper;
use ScratchBird\PDO\ScratchBirdAuthException;
use ScratchBird\PDO\ScratchBirdConnectionException;
use ScratchBird\PDO\ScratchBirdDataException;
use ScratchBird\PDO\ScratchBirdException;
use ScratchBird\PDO\ScratchBirdIntegrityException;
use ScratchBird\PDO\ScratchBirdInternalException;
use ScratchBird\PDO\ScratchBirdNotSupportedException;
use ScratchBird\PDO\ScratchBirdSyntaxException;
use ScratchBird\PDO\ScratchBirdTransactionException;
use ScratchBird\PDO\ScratchBirdWarning;

final class ErrorsTest extends TestCase
{
    public function testErrorMapperMapsRepresentativeSqlStatesToTypedExceptions(): void
    {
        $cases = [
            ['01000', ScratchBirdWarning::class],
            ['08006', ScratchBirdConnectionException::class],
            ['0A000', ScratchBirdNotSupportedException::class],
            ['22P02', ScratchBirdDataException::class],
            ['23505', ScratchBirdIntegrityException::class],
            ['28P01', ScratchBirdAuthException::class],
            ['42601', ScratchBirdSyntaxException::class],
            ['40001', ScratchBirdTransactionException::class],
            ['XX000', ScratchBirdInternalException::class],
            ['99999', ScratchBirdException::class],
            ['1234', ScratchBirdException::class],
        ];

        foreach ($cases as [$sqlState, $expectedClass]) {
            $exception = ErrorMapper::map($sqlState, 'boom', 'detail', 'hint');
            $this->assertInstanceOf($expectedClass, $exception, "sqlstate {$sqlState}");
            $this->assertSame($sqlState, $exception->sqlState);
            $this->assertSame('detail', $exception->detail);
            $this->assertSame('hint', $exception->hint);
        }
    }

    public function testBuildQueryExceptionParsesDetailAndHintFromErrorPayload(): void
    {
        $connection = $this->newConnectionWithoutConstructor();
        $payload = 'SERROR' . "\0"
            . 'C23505' . "\0"
            . 'Mduplicate key' . "\0"
            . 'DKey (id)=(1) already exists.' . "\0"
            . 'HUse a new id.' . "\0"
            . "\0";

        $exception = $connection->buildQueryException($payload);

        $this->assertInstanceOf(ScratchBirdIntegrityException::class, $exception);
        $this->assertSame('23505', $exception->sqlState);
        $this->assertSame('duplicate key', $exception->getMessage());
        $this->assertSame('Key (id)=(1) already exists.', $exception->detail);
        $this->assertSame('Use a new id.', $exception->hint);
    }

    public function testRecordErrorStoresSqlStateAndMessageForScratchBirdException(): void
    {
        $connection = $this->newConnectionWithoutConstructor();
        $recordError = $this->recordErrorMethod();

        $recordError->invoke($connection, new ScratchBirdDataException('bad integer input', '22P02'));

        $this->assertSame(['22P02', 0, 'bad integer input'], $connection->errorInfo());
    }

    public function testRecordErrorUsesHy000ForNonScratchBirdExceptions(): void
    {
        $connection = $this->newConnectionWithoutConstructor();
        $recordError = $this->recordErrorMethod();

        $recordError->invoke($connection, new RuntimeException('socket read failed'));

        $this->assertSame(['HY000', 0, 'socket read failed'], $connection->errorInfo());
    }

    private function newConnectionWithoutConstructor(): Connection
    {
        $class = new ReflectionClass(Connection::class);
        /** @var Connection $connection */
        $connection = $class->newInstanceWithoutConstructor();
        return $connection;
    }

    private function recordErrorMethod(): ReflectionMethod
    {
        $class = new ReflectionClass(Connection::class);
        $method = $class->getMethod('recordError');
        $method->setAccessible(true);
        return $method;
    }
}
