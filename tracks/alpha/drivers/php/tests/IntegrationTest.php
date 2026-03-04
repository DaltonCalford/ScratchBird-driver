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

use PHPUnit\Framework\TestCase;
use ScratchBird\PDO\ScratchBirdPDO;
use ScratchBird\PDO\ScratchBirdException;
use ScratchBird\PDO\ScratchBirdNotSupportedException;

final class IntegrationTest extends TestCase
{
    public function testSelect(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $pdo = new ScratchBirdPDO($dsn);
        $stmt = $pdo->query('SELECT 1');
        $row = $stmt->fetch(\PDO::FETCH_NUM);
        $this->assertSame(1, (int)$row[0]);
    }

    public function testPrepareBind(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $pdo = new ScratchBirdPDO($dsn);
        $stmt = $pdo->prepare('SELECT ?::INTEGER');
        $stmt->execute([42]);
        $row = $stmt->fetch(\PDO::FETCH_NUM);
        $this->assertSame(42, (int)$row[0]);
    }

    public function testTypesFixture(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $pdo = new ScratchBirdPDO($dsn);
        $stmt = $pdo->query('SELECT * FROM type_coverage');
        $row = $stmt->fetch(\PDO::FETCH_NUM);
        $this->assertNotFalse($row);
    }

    public function testConnectWithCompatibilityConnOptions(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $separator = str_contains($dsn, '?') ? '&' : '?';
        $pdo = new ScratchBirdPDO($dsn . $separator . 'binary_transfer=false&compression=zstd');
        $stmt = $pdo->query('SELECT 1');
        $row = $stmt->fetch(\PDO::FETCH_NUM);
        $this->assertSame(1, (int)$row[0]);
    }

    public function testCancel(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $cancelSql = getenv('SCRATCHBIRD_PHP_CANCEL_SQL');
        if (!$cancelSql) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_CANCEL_SQL not set');
        }
        $conn = new \ScratchBird\PDO\Connection($dsn);
        $stream = $conn->executeQuery($cancelSql);
        $conn->cancel();
        $this->expectException(\Throwable::class);
        $stream->readRow();
    }

    public function testQueryMultiReturnsIndependentResultSets(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $pdo = new ScratchBirdPDO($dsn);
        try {
            $results = $pdo->queryMulti('SELECT 1 AS first_value; SELECT 2 AS second_value');
        } catch (\Throwable $ex) {
            $this->skipIfFeatureUnsupported($ex, 'queryMulti');
            throw $ex;
        }
        $this->assertCount(2, $results);
        $this->assertSame(1, (int)($results[0]['rows'][0]['first_value'] ?? 0));
        $this->assertSame(2, (int)($results[1]['rows'][0]['second_value'] ?? 0));
    }

    public function testExecuteMultiAliasReturnsIndependentResultSets(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $pdo = new ScratchBirdPDO($dsn);
        try {
            $results = $pdo->executeMulti('SELECT 3 AS third_value; SELECT 4 AS fourth_value');
        } catch (\Throwable $ex) {
            $this->skipIfFeatureUnsupported($ex, 'executeMulti');
            throw $ex;
        }
        $this->assertCount(2, $results);
        $this->assertSame(3, (int)($results[0]['rows'][0]['third_value'] ?? 0));
        $this->assertSame(4, (int)($results[1]['rows'][0]['fourth_value'] ?? 0));
    }

    public function testExecuteBatchReturnsPerItemSummary(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $pdo = new ScratchBirdPDO($dsn);
        $batch = $pdo->executeBatch('SELECT ?::INTEGER AS value', [[11], [22], [33]]);
        $this->assertCount(3, $batch['items']);
        $this->assertSame(0, $batch['items'][0]['index']);
        $this->assertSame(1, $batch['items'][0]['rowCount']);
        $this->assertSame(3, $batch['totalRowCount']);
    }

    public function testCallExecutesJdbcCallableEscapeSyntax(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $pdo = new ScratchBirdPDO($dsn);
        try {
            $stmt = $pdo->call('{ ? = call abs(?) }', [-3]);
        } catch (\Throwable $ex) {
            $this->skipIfFeatureUnsupported($ex, 'call');
            throw $ex;
        }
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);
        $this->assertNotFalse($row);
        $firstValue = $row['return_value'] ?? array_values($row)[0] ?? null;
        $this->assertSame(3, (int)$firstValue);
    }

    public function testStatementNextRowsetTraversesMultipleResults(): void
    {
        $dsn = getenv('SCRATCHBIRD_PHP_URL');
        if (!$dsn) {
            $this->markTestSkipped('SCRATCHBIRD_PHP_URL not set');
        }
        $pdo = new ScratchBirdPDO($dsn);
        try {
            $stmt = $pdo->query('SELECT 10 AS first_value; SELECT 20 AS second_value');
        } catch (\Throwable $ex) {
            $this->skipIfFeatureUnsupported($ex, 'nextRowset');
            throw $ex;
        }
        $first = $stmt->fetch(\PDO::FETCH_ASSOC);
        $this->assertSame(10, (int)$first['first_value']);
        $this->assertTrue($stmt->nextRowset());
        $second = $stmt->fetch(\PDO::FETCH_ASSOC);
        $this->assertSame(20, (int)$second['second_value']);
        $this->assertFalse($stmt->nextRowset());
    }

    private function skipIfFeatureUnsupported(\Throwable $ex, string $feature): void
    {
        if ($ex instanceof ScratchBirdNotSupportedException) {
            $this->markTestSkipped($feature . ' not supported by runtime: ' . $ex->getMessage());
        }
        if ($ex instanceof ScratchBirdException && $ex->sqlState === '0A000') {
            $this->markTestSkipped($feature . ' not supported by runtime: ' . $ex->getMessage());
        }
    }
}
