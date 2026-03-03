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
use ScratchBird\PDO\Protocol;

final class ProtocolConnAuthTest extends TestCase
{
    public function testBuildStartupPayloadCarriesFeatureMaskAndParameters(): void
    {
        $payload = Protocol::buildStartupPayload(
            Protocol::FEATURE_STREAMING,
            ['database' => 'demo', 'user' => 'app']
        );
        $this->assertSame(Protocol::VERSION_MAJOR, ord($payload[0]));
        $this->assertSame(Protocol::VERSION_MINOR, ord($payload[1]));
        $parts = unpack('Vlow/Vhigh', substr($payload, 4, 8));
        $features = (int)($parts['low'] + ($parts['high'] << 32));
        $this->assertSame(Protocol::FEATURE_STREAMING, $features);
        $this->assertStringContainsString("database\0demo\0user\0app\0\0", substr($payload, 12));
    }

    public function testParseAuthRequestScramPayload(): void
    {
        $data = 'n,,n=app,r=clientnonce';
        $payload = chr(Protocol::AUTH_SCRAM_SHA256) . "\0\0\0" . $data;
        [$method, $parsed] = Protocol::parseAuthRequest($payload);
        $this->assertSame(Protocol::AUTH_SCRAM_SHA256, $method);
        $this->assertSame($data, $parsed);
    }

    public function testParseAuthContinueScramPayload(): void
    {
        $data = 'r=nonce,s=salt,i=4096';
        $payload = chr(Protocol::AUTH_SCRAM_SHA256) . chr(1) . "\0\0" . pack('V', strlen($data)) . $data;
        [$method, $stage, $parsed] = Protocol::parseAuthContinue($payload);
        $this->assertSame(Protocol::AUTH_SCRAM_SHA256, $method);
        $this->assertSame(1, $stage);
        $this->assertSame($data, $parsed);
    }

    public function testParseAuthOkPayload(): void
    {
        $sessionId = random_bytes(16);
        $info = 'v=server-signature';
        $payload = $sessionId . pack('V', strlen($info)) . $info;
        [$parsedSessionId, $parsedInfo] = Protocol::parseAuthOk($payload);
        $this->assertSame($sessionId, $parsedSessionId);
        $this->assertSame($info, $parsedInfo);
    }
}
