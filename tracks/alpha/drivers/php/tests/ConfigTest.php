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
use ScratchBird\PDO\Config;

final class ConfigTest extends TestCase
{
    public function testParseUri(): void
    {
        $cfg = Config::fromDsn('scratchbird://user:pass@localhost:3092/mydb?sslmode=require&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd');
        $this->assertSame('localhost', $cfg->host);
        $this->assertSame(3092, $cfg->port);
        $this->assertSame('mydb', $cfg->database);
        $this->assertSame('user', $cfg->user);
        $this->assertSame('pass', $cfg->password);
        $this->assertSame('require', $cfg->sslMode);
        $this->assertSame(3000, $cfg->connectTimeoutMs);
        $this->assertSame('app', $cfg->applicationName);
        $this->assertFalse($cfg->binaryTransfer);
        $this->assertSame('zstd', $cfg->compression);
    }

    public function testParseKeyValue(): void
    {
        $cfg = Config::fromDsn('Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;Timeout=5;Socket_Timeout=7');
        $this->assertSame('server', $cfg->host);
        $this->assertSame(4000, $cfg->port);
        $this->assertSame('db', $cfg->database);
        $this->assertSame('me', $cfg->user);
        $this->assertSame('secret', $cfg->password);
        $this->assertSame(5000, $cfg->connectTimeoutMs);
        $this->assertSame(7000, $cfg->socketTimeoutMs);
    }

    public function testParseManagerProxyParams(): void
    {
        $cfg = Config::fromDsn('scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token&manager_client_flags=7');
        $this->assertSame('manager_proxy', $cfg->frontDoorMode);
        $this->assertSame('token', $cfg->managerAuthToken);
        $this->assertSame(7, $cfg->managerClientFlags);
    }
}
