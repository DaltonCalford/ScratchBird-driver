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
        $stmt = $pdo->query('SELECT * FROM sb_conformance.type_coverage');
        $row = $stmt->fetch(\PDO::FETCH_NUM);
        $this->assertNotFalse($row);
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
}
