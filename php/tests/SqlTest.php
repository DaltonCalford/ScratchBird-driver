<?php

use PHPUnit\Framework\TestCase;
use ScratchBird\PDO\Sql;

final class SqlTest extends TestCase
{
    public function testNormalizePositional(): void
    {
        $sql = 'SELECT * FROM t WHERE id = ? AND name = ?';
        $out = Sql::normalize($sql, [42, 'Ada']);
        $this->assertSame('SELECT * FROM t WHERE id = $1 AND name = $2', $out['sql']);
        $this->assertSame([42, 'Ada'], $out['params']);
    }

    public function testNormalizeNamed(): void
    {
        $sql = 'SELECT * FROM users WHERE name = @name AND active = :active';
        $out = Sql::normalize($sql, ['name' => 'Ada', 'active' => true]);
        $this->assertSame('SELECT * FROM users WHERE name = $1 AND active = $2', $out['sql']);
        $this->assertSame(['Ada', true], $out['params']);
    }
}
