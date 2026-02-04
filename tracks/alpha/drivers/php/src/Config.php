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

namespace ScratchBird\PDO;

final class Config
{
    public string $host = 'localhost';
    public int $port = 3092;
    public string $database = '';
    public string $user = '';
    public string $password = '';
    public string $schema = '';
    public string $role = '';
    public string $sslMode = 'require';
    public ?string $sslRootCert = null;
    public ?string $sslCert = null;
    public ?string $sslKey = null;
    public ?string $sslPassword = null;
    public int $connectTimeoutMs = 30000;
    public int $socketTimeoutMs = 0;
    public string $applicationName = 'scratchbird_php';
    public bool $binaryTransfer = true;
    public string $compression = 'off';
    public int $fetchSize = 0;

    public static function fromDsn(string $dsn): self
    {
        $dsn = trim($dsn);
        if ($dsn === '') {
            return new self();
        }
        if (str_contains($dsn, '://')) {
            return self::parseUri($dsn);
        }
        return self::parseKeyValue($dsn);
    }

    private static function parseUri(string $dsn): self
    {
        $parts = parse_url($dsn);
        if ($parts === false || ($parts['scheme'] ?? '') !== 'scratchbird') {
            throw new \InvalidArgumentException('Unsupported DSN scheme');
        }
        $cfg = new self();
        if (!empty($parts['host'])) {
            $cfg->host = $parts['host'];
        }
        if (!empty($parts['port'])) {
            $cfg->port = (int)$parts['port'];
        }
        if (!empty($parts['user'])) {
            $cfg->user = urldecode($parts['user']);
        }
        if (!empty($parts['pass'])) {
            $cfg->password = urldecode($parts['pass']);
        }
        if (!empty($parts['path']) && $parts['path'] !== '/') {
            $cfg->database = ltrim($parts['path'], '/');
        }
        if (!empty($parts['query'])) {
            parse_str($parts['query'], $query);
            foreach ($query as $key => $value) {
                self::applyParam($cfg, (string)$key, (string)$value);
            }
        }
        return $cfg;
    }

    private static function parseKeyValue(string $dsn): self
    {
        $cfg = new self();
        $separator = str_contains($dsn, ';') ? ';' : ' ';
        $pairs = array_filter(array_map('trim', explode($separator, $dsn)));
        foreach ($pairs as $pair) {
            if (!str_contains($pair, '=')) {
                continue;
            }
            [$key, $value] = array_map('trim', explode('=', $pair, 2));
            $value = trim($value, '"');
            self::applyParam($cfg, $key, $value);
        }
        return $cfg;
    }

    private static function applyParam(self $cfg, string $key, string $value): void
    {
        switch (strtolower($key)) {
            case 'host':
            case 'server':
            case 'data source':
            case 'datasource':
                $cfg->host = $value;
                break;
            case 'port':
                $cfg->port = (int)$value;
                break;
            case 'database':
            case 'dbname':
            case 'initial catalog':
                $cfg->database = $value;
                break;
            case 'user':
            case 'username':
            case 'user id':
            case 'uid':
                $cfg->user = $value;
                break;
            case 'password':
            case 'pwd':
                $cfg->password = $value;
                break;
            case 'schema':
            case 'search_path':
            case 'searchpath':
            case 'currentschema':
                $cfg->schema = $value;
                break;
            case 'role':
                $cfg->role = $value;
                break;
            case 'sslmode':
            case 'ssl mode':
                $cfg->sslMode = $value;
                break;
            case 'sslrootcert':
                $cfg->sslRootCert = $value;
                break;
            case 'sslcert':
                $cfg->sslCert = $value;
                break;
            case 'sslkey':
                $cfg->sslKey = $value;
                break;
            case 'sslpassword':
                $cfg->sslPassword = $value;
                break;
            case 'connect_timeout':
            case 'connecttimeout':
            case 'timeout':
                $cfg->connectTimeoutMs = (int)$value * 1000;
                break;
            case 'socket_timeout':
            case 'sockettimeout':
                $cfg->socketTimeoutMs = (int)$value * 1000;
                break;
            case 'application_name':
            case 'applicationname':
                $cfg->applicationName = $value;
                break;
            case 'binary_transfer':
            case 'binarytransfer':
                $cfg->binaryTransfer = $value === '1' || strtolower($value) === 'true';
                break;
            case 'compression':
                $cfg->compression = strtolower($value) === 'zstd' ? 'zstd' : 'off';
                break;
            case 'fetch_size':
            case 'fetchsize':
            case 'default_fetch_size':
                $cfg->fetchSize = max(0, (int)$value);
                break;
        }
    }
}
