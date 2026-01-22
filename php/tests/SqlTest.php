<?php

use PHPUnit\Framework\TestCase;
use ScratchBird\PDO\Sql;

final class SqlTest extends TestCase
{
    public function testSubstitutePositional(): void
    {
        $sql = 'SELECT * FROM t WHERE id = ? AND name = ?';
        $out = Sql::substitute($sql, [42, 'Ada']);
        $this->assertSame("SELECT * FROM t WHERE id = 42 AND name = 'Ada'", $out);
    }

    public function testSubstituteNamed(): void
    {
        $sql = 'SELECT * FROM users WHERE name = @name AND active = :active';
        $out = Sql::substitute($sql, ['name' => 'Ada', 'active' => true]);
        $this->assertSame("SELECT * FROM users WHERE name = 'Ada' AND active = TRUE", $out);
    }
}
