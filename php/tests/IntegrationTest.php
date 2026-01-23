<?php

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
}
