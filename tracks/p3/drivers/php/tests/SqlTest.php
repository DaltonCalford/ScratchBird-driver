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

    public function testNormalizeNamedIgnoresPostgresCastMarkers(): void
    {
        $sql = 'SELECT :id::int AS id, created_at::timestamp AS created_at';
        $out = Sql::normalize($sql, ['id' => 42]);
        $this->assertSame('SELECT $1::int AS id, created_at::timestamp AS created_at', $out['sql']);
        $this->assertSame([42], $out['params']);
    }

    public function testNormalizePositionalKeepsCastSyntaxIntact(): void
    {
        $sql = 'SELECT ?::bigint AS id';
        $out = Sql::normalize($sql, [7]);
        $this->assertSame('SELECT $1::bigint AS id', $out['sql']);
        $this->assertSame([7], $out['params']);
    }

    public function testNormalizeCallableProcedureEscape(): void
    {
        $sql = '{call admin.refresh_cache(?)}';
        $out = Sql::normalizeCallable($sql, [42]);
        $this->assertSame('call admin.refresh_cache($1)', $out['sql']);
        $this->assertSame([42], $out['params']);
    }

    public function testNormalizeCallableFunctionEscape(): void
    {
        $sql = '{? = call math.add(?, ?)}';
        $out = Sql::normalizeCallable($sql, [5, 7]);
        $this->assertSame('select math.add($1, $2) as return_value', $out['sql']);
        $this->assertSame([5, 7], $out['params']);
    }

    public function testNormalizeCallableRejectsInvalidEscapeSyntax(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        Sql::normalizeCallableSql('{call bad(}');
    }
}
