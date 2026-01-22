<?php

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
}
