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

final class Connection
{
    private const QUERY_FLAG_BINARY_RESULT = 0x04;

    private Config $config;
    /** @var resource|null */
    private $socket = null;
    private string $attachmentId = '';
    private int $txnId = 0;
    private int $sequence = 0;
    private int $lastQuerySequence = 0;
    private int $lastMaxRows = 0;
    private bool $connected = false;
    private array $attributes = [];
    private array $parameters = [];
    private array $lastError = ['00000', 0, null];

    public function __construct(string $dsn, ?string $username = null, ?string $password = null, array $options = [])
    {
        $this->config = Config::fromDsn($dsn);
        if ($username !== null) {
            $this->config->user = $username;
        }
        if ($password !== null) {
            $this->config->password = $password;
        }
        $this->attributes = $options;
        $this->connect();
    }

    public function prepare(string $statement, array $options = []): Statement
    {
        return new Statement($this, $statement, $options);
    }

    public function query(string $statement, mixed ...$fetchModeArgs): Statement
    {
        $stmt = $this->prepare($statement);
        $stmt->execute();
        return $stmt;
    }

    public function exec(string $statement): int|false
    {
        try {
            $stmt = $this->prepare($statement);
            $stmt->execute();
            return $stmt->rowCount();
        } catch (\Throwable $ex) {
            $this->recordError($ex);
            return false;
        }
    }

    public function beginTransaction(): bool
    {
        return true;
    }

    public function commit(): bool
    {
        return $this->executeSimple('COMMIT');
    }

    public function rollBack(): bool
    {
        return $this->executeSimple('ROLLBACK');
    }

    public function lastInsertId(?string $name = null): string|false
    {
        return false;
    }

    public function setAttribute(int $attribute, mixed $value): bool
    {
        $this->attributes[$attribute] = $value;
        return true;
    }

    public function getAttribute(int $attribute): mixed
    {
        return $this->attributes[$attribute] ?? null;
    }

    public function errorInfo(): array
    {
        return $this->lastError;
    }

    public function errorCode(): ?string
    {
        return $this->lastError[0] ?? null;
    }

    public function close(): void
    {
        if ($this->socket === null) {
            return;
        }
        fclose($this->socket);
        $this->socket = null;
        $this->connected = false;
    }

    public function executeQuery(string $sql, array $params = [], ?int $maxRows = null): ResultStream
    {
        $pageSize = $maxRows ?? $this->config->fetchSize;
        if (empty($params)) {
            $this->sendSimpleQuery($sql, $pageSize);
        } else {
            $this->sendExtendedQuery($sql, $params, $pageSize);
        }
        return new ResultStream($this);
    }

    public function resumePortal(): void
    {
        $execPayload = Protocol::buildExecutePayload('', $this->lastMaxRows);
        $this->lastQuerySequence = $this->sendMessage(Protocol::MSG_EXECUTE, $execPayload, 0, false);
        $this->sendMessage(Protocol::MSG_SYNC, '', 0, false);
    }

    public function cancel(): void
    {
        $payload = Protocol::buildCancelPayload(0, $this->lastQuerySequence);
        $this->sendMessage(Protocol::MSG_CANCEL, $payload, Protocol::MSG_FLAG_URGENT, false);
    }

    public function sendMessage(int $type, string $payload, int $flags = 0, bool $forceZero = false): int
    {
        if ($this->socket === null) {
            throw new ScratchBirdConnectionException('Connection not open', '08006');
        }
        if ($this->config->socketTimeoutMs > 0) {
            stream_set_timeout($this->socket, 0, $this->config->socketTimeoutMs * 1000);
        }
        $sequence = $this->sequence++;
        $attachmentId = $forceZero ? str_repeat("\0", 16) : $this->attachmentId;
        $txnId = $forceZero ? 0 : $this->txnId;
        $payload = Protocol::encodeMessage($type, $payload, $flags, $sequence, $attachmentId, $txnId);
        $total = 0;
        $length = strlen($payload);
        while ($total < $length) {
            $written = fwrite($this->socket, substr($payload, $total));
            if ($written === false || $written === 0) {
                throw new ScratchBirdConnectionException('Connection closed', '08006');
            }
            $total += $written;
        }
        return $sequence;
    }

    public function receive(): array
    {
        if ($this->socket === null) {
            throw new ScratchBirdConnectionException('Connection not open', '08006');
        }
        if ($this->config->socketTimeoutMs > 0) {
            stream_set_timeout($this->socket, 0, $this->config->socketTimeoutMs * 1000);
        }
        $header = $this->readExact(Protocol::HEADER_SIZE);
        [$type, $flags, $length, $sequence, $attachmentId, $txnId] = Protocol::decodeHeader($header);
        $payload = $length > 0 ? $this->readExact($length) : '';
        return [$type, $flags, $payload, $sequence, $attachmentId, $txnId];
    }

    public function drainUntilReady(): void
    {
        while (true) {
            [$type, , $payload] = $this->receive();
            if ($type === Protocol::MSG_ERROR) {
                throw $this->buildQueryException($payload);
            }
            if ($type === Protocol::MSG_READY) {
                [, $txnId] = Protocol::parseReady($payload);
                $this->txnId = $txnId;
                return;
            }
        }
    }

    private function connect(): void
    {
        if ($this->config->user === '' || $this->config->database === '') {
            throw new ScratchBirdConnectionException('user and database are required', '08001');
        }
        if (!$this->config->binaryTransfer) {
            throw new ScratchBirdNotSupportedException('binary_transfer=false is not supported', '0A000');
        }
        if (strtolower($this->config->compression) === 'zstd') {
            throw new ScratchBirdNotSupportedException('compression=zstd is not supported', '0A000');
        }
        $timeout = $this->config->connectTimeoutMs / 1000;
        $address = sprintf('tcp://%s:%d', $this->config->host, $this->config->port);
        $socket = @stream_socket_client($address, $errno, $errstr, $timeout);
        if ($socket === false) {
            throw new ScratchBirdConnectionException($errstr ?: 'Connection failed', '08001');
        }
        stream_set_blocking($socket, true);
        $this->socket = $socket;
        $this->applyTls();
        $this->handshake();
        $this->applySchema();
        $this->connected = true;
    }

    private function applyTls(): void
    {
        $mode = strtolower($this->config->sslMode ?: 'require');
        if ($mode === 'disable') {
            throw new ScratchBirdConnectionException('TLS is required for ScratchBird connections', '08001');
        }
        $options = [
            'ssl' => [
                'crypto_method' => STREAM_CRYPTO_METHOD_TLSv1_3_CLIENT,
                'verify_peer' => in_array($mode, ['verify-full', 'verify-ca', 'require'], true),
                'verify_peer_name' => $mode === 'verify-full',
            ],
        ];
        if ($this->config->sslRootCert) {
            $options['ssl']['cafile'] = $this->config->sslRootCert;
        }
        if ($this->config->sslCert && $this->config->sslKey) {
            $options['ssl']['local_cert'] = $this->config->sslCert;
            $options['ssl']['local_pk'] = $this->config->sslKey;
            if ($this->config->sslPassword) {
                $options['ssl']['passphrase'] = $this->config->sslPassword;
            }
        }
        stream_context_set_option($this->socket, $options);
        $result = @stream_socket_enable_crypto($this->socket, true, STREAM_CRYPTO_METHOD_TLSv1_3_CLIENT);
        if ($result !== true) {
            throw new ScratchBirdConnectionException('TLS handshake failed', '08001');
        }
    }

    private function applySchema(): void
    {
        $schema = trim($this->config->schema);
        if ($schema === '' || strtolower($schema) === 'public') {
            return;
        }
        $statement = $this->buildSchemaStatement($schema);
        if ($statement === '') {
            return;
        }
        $this->executeSimple($statement);
    }

    private function buildSchemaStatement(string $schema): string
    {
        $schema = trim($schema);
        if ($schema === '') {
            return '';
        }
        if (str_contains($schema, ',')) {
            $parts = array_filter(array_map('trim', explode(',', $schema)));
            if (!$parts) {
                return '';
            }
            $quoted = array_map([$this, 'quoteIdentifier'], $parts);
            return 'SET SEARCH_PATH TO ' . implode(', ', $quoted);
        }
        return 'SET SCHEMA ' . $this->quoteIdentifier($schema);
    }

    private function quoteIdentifier(string $name): string
    {
        return '"' . str_replace('"', '""', $name) . '"';
    }

    private function handshake(): void
    {
        $features = 0;
        if (strtolower($this->config->compression) === 'zstd') {
            $features |= Protocol::FEATURE_COMPRESSION;
        }
        if ($this->config->binaryTransfer) {
            $features |= Protocol::FEATURE_STREAMING;
        }
        $params = [
            'database' => $this->config->database,
            'user' => $this->config->user,
        ];
        if ($this->config->role !== '') {
            $params['role'] = $this->config->role;
        }
        if ($this->config->applicationName !== '') {
            $params['application_name'] = $this->config->applicationName;
        }
        $startup = Protocol::buildStartupPayload($features, $params);
        $this->sendMessage(Protocol::MSG_STARTUP, $startup, 0, true);

        $scram = null;

        while (true) {
            [$type, , $payload, , $attachmentId, $txnId] = $this->receive();
            switch ($type) {
                case Protocol::MSG_NEGOTIATE_VERSION:
                    continue;
                case Protocol::MSG_AUTH_REQUEST:
                    [$method, $data] = Protocol::parseAuthRequest($payload);
                    if ($method === Protocol::AUTH_OK) {
                        continue 2;
                    }
                    if ($method === Protocol::AUTH_PASSWORD) {
                        $this->sendMessage(Protocol::MSG_AUTH_RESPONSE, $this->config->password ?? '', 0, true);
                        continue 2;
                    }
                    if ($method === Protocol::AUTH_SCRAM_SHA256) {
                        if ($scram === null) {
                            $scram = new Scram($this->config->user);
                        }
                        $clientFirst = $scram->clientFirstMessage();
                        $this->sendMessage(Protocol::MSG_AUTH_RESPONSE, $clientFirst, 0, true);
                        continue 2;
                    }
                    throw new ScratchBirdAuthException('Unsupported auth method', '28000');
                case Protocol::MSG_AUTH_CONTINUE:
                    [$method, , $data] = Protocol::parseAuthContinue($payload);
                    if ($method !== Protocol::AUTH_SCRAM_SHA256 || $scram === null) {
                        throw new ScratchBirdAuthException('Unsupported auth continue', '28000');
                    }
                    $clientFinal = $scram->handleServerFirst($this->config->password, $data);
                    $this->sendMessage(Protocol::MSG_AUTH_RESPONSE, $clientFinal, 0, true);
                    continue 2;
                case Protocol::MSG_AUTH_OK:
                    [, $serverInfo] = Protocol::parseAuthOk($payload);
                    $this->attachmentId = $attachmentId;
                    $this->txnId = $txnId;
                    if ($scram !== null && $serverInfo !== '' && str_starts_with($serverInfo, 'v=')) {
                        $scram->verifyServerFinal($serverInfo);
                    }
                    continue 2;
                case Protocol::MSG_PARAMETER_STATUS:
                    [$name, $value] = Protocol::parseParameterStatus($payload);
                    $this->parameters[$name] = $value;
                    continue 2;
                case Protocol::MSG_READY:
                    [, $txnId] = Protocol::parseReady($payload);
                    $this->txnId = $txnId;
                    return;
                case Protocol::MSG_ERROR:
                    throw $this->buildQueryException($payload);
                default:
                    continue 2;
            }
        }
    }

    private function sendSimpleQuery(string $sql, int $maxRows): void
    {
        $flags = $this->config->binaryTransfer ? self::QUERY_FLAG_BINARY_RESULT : 0;
        $payload = Protocol::buildQueryPayload($sql, $flags, $maxRows, 0);
        $this->lastMaxRows = max(0, $maxRows);
        $this->lastQuerySequence = $this->sendMessage(Protocol::MSG_QUERY, $payload, 0, false);
    }

    private function sendExtendedQuery(string $sql, array $params, int $maxRows): void
    {
        $paramValues = [];
        $paramTypes = [];
        foreach ($params as $param) {
            $encoded = TypeDecoder::encodeParam($param);
            $paramValues[] = $encoded['param'];
            $paramTypes[] = $encoded['oid'];
        }
        $parsePayload = Protocol::buildParsePayload('', $sql, $paramTypes);
        $this->sendMessage(Protocol::MSG_PARSE, $parsePayload, 0, false);
        $paramCount = $this->describeStatement('');
        if ($paramCount >= 0 && $paramCount !== count($paramTypes)) {
            throw new ScratchBirdException('parameter count mismatch', '07001');
        }

        $resultFormats = $this->config->binaryTransfer ? [TypeDecoder::FORMAT_BINARY] : [];
        $bindPayload = Protocol::buildBindPayload('', '', $paramValues, $resultFormats);
        $this->sendMessage(Protocol::MSG_BIND, $bindPayload, 0, false);

        $execPayload = Protocol::buildExecutePayload('', $maxRows);
        $this->lastMaxRows = max(0, $maxRows);
        $this->lastQuerySequence = $this->sendMessage(Protocol::MSG_EXECUTE, $execPayload, 0, false);
        $this->sendMessage(Protocol::MSG_SYNC, '', 0, false);
    }

    private function describeStatement(string $name): int
    {
        $payload = Protocol::buildDescribePayload(ord('S'), $name);
        $this->sendMessage(Protocol::MSG_DESCRIBE, $payload, 0, false);
        $this->sendMessage(Protocol::MSG_SYNC, '', 0, false);
        $paramCount = -1;
        while (true) {
            [$type, , $payload] = $this->receive();
            if ($type === Protocol::MSG_ERROR) {
                throw $this->buildQueryException($payload);
            }
            if ($type === Protocol::MSG_PARAMETER_DESCRIPTION) {
                $paramCount = count(Protocol::parseParameterDescription($payload));
                continue;
            }
            if ($type === Protocol::MSG_PARAMETER_STATUS) {
                [$name, $value] = Protocol::parseParameterStatus($payload);
                $this->parameters[$name] = $value;
                continue;
            }
            if ($type === Protocol::MSG_READY) {
                [, $txnId] = Protocol::parseReady($payload);
                $this->txnId = $txnId;
                return $paramCount;
            }
        }
    }

    private function executeSimple(string $sql): bool
    {
        try {
            $this->sendSimpleQuery($sql, 0);
            $this->drainUntilReady();
            return true;
        } catch (\Throwable $ex) {
            $this->recordError($ex);
            return false;
        }
    }

    private function readExact(int $length): string
    {
        $data = '';
        while (strlen($data) < $length) {
            $chunk = fread($this->socket, $length - strlen($data));
            if ($chunk === false || $chunk === '') {
                throw new ScratchBirdConnectionException('Connection closed', '08006');
            }
            $data .= $chunk;
        }
        return $data;
    }

    public function buildQueryException(string $payload): ScratchBirdException
    {
        [, $sqlState, $message, $detail, $hint] = Protocol::parseErrorMessage($payload);
        return ErrorMapper::map($sqlState, $message, $detail, $hint);
    }

    private function recordError(\Throwable $ex): void
    {
        if ($ex instanceof ScratchBirdException) {
            $this->lastError = [$ex->sqlState, $ex->getCode(), $ex->getMessage()];
        } else {
            $this->lastError = ['HY000', 0, $ex->getMessage()];
        }
    }
}
