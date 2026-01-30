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
