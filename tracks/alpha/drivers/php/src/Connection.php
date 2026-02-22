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

use ScratchBird\CircuitBreaker;
use ScratchBird\TelemetryCollector;
use ScratchBird\KeepaliveManager;
use ScratchBird\KeepaliveTracker;
use ScratchBird\LeakDetector;
use ScratchBird\LeakDetectionGuard;

final class Connection
{
    private const QUERY_FLAG_BINARY_RESULT = 0x04;
    private const MANAGER_PROTOCOL_MAGIC = 0x42444253; // SBDB
    private const MANAGER_PROTOCOL_VERSION = 0x0101;
    private const MANAGER_HEADER_SIZE = 12;
    private const MANAGER_MAX_PAYLOAD_SIZE = 16777216;
    private const MCP_PROTOCOL_VERSION = 0x0100;
    private const MCP_MSG_CONNECT_RESPONSE = 0x02;
    private const MCP_MSG_AUTH_CHALLENGE = 0x12;
    private const MCP_MSG_AUTH_RESPONSE = 0x11;
    private const MCP_MSG_STATUS_RESPONSE = 0x64;
    private const MCP_MSG_HELLO = 0x65;
    private const MCP_MSG_AUTH_START = 0x66;
    private const MCP_MSG_AUTH_CONTINUE = 0x67;
    private const MCP_MSG_DB_CONNECT = 0x69;
    private const MCP_AUTH_METHOD_TOKEN = 4;
    private static int $connectionCounter = 0;

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
    private array $notificationHandlers = [];
    private ?array $lastPlan = null;
    private ?array $lastSblr = null;
    private string $connectionId;
    private CircuitBreaker $circuitBreaker;
    private TelemetryCollector $telemetry;
    private KeepaliveManager $keepaliveManager;
    private ?KeepaliveTracker $keepaliveTracker = null;
    private LeakDetector $leakDetector;
    private ?LeakDetectionGuard $leakGuard = null;

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
        self::$connectionCounter++;
        $this->connectionId = 'conn-' . self::$connectionCounter;
        $this->circuitBreaker = new CircuitBreaker();
        $this->telemetry = new TelemetryCollector();
        $this->keepaliveManager = new KeepaliveManager();
        $this->leakDetector = new LeakDetector();
        $this->keepaliveManager->start();
        $this->leakDetector->start();
        $this->connect();
        $this->keepaliveTracker = $this->keepaliveManager->register(
            $this->connectionId,
            $this,
            function (): bool {
                $this->ping();
                return true;
            }
        );
        $this->leakGuard = $this->leakDetector->checkout($this->connectionId, ['driver' => 'php']);
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
        $payload = Protocol::buildTxnBeginPayload(0, 0, 0, Protocol::ISOLATION_READ_COMMITTED, 0, 0, 0, 0);
        $this->sendMessage(Protocol::MSG_TXN_BEGIN, $payload, 0, false);
        $this->drainUntilReady();
        return true;
    }

    public function commit(): bool
    {
        $payload = Protocol::buildTxnCommitPayload(0);
        $this->sendMessage(Protocol::MSG_TXN_COMMIT, $payload, 0, false);
        $this->drainUntilReady();
        return true;
    }

    public function rollBack(): bool
    {
        $payload = Protocol::buildTxnRollbackPayload(0);
        $this->sendMessage(Protocol::MSG_TXN_ROLLBACK, $payload, 0, false);
        $this->drainUntilReady();
        return true;
    }

    public function savepoint(string $name): void
    {
        $payload = Protocol::buildTxnSavepointPayload($name);
        $this->sendMessage(Protocol::MSG_TXN_SAVEPOINT, $payload, 0, false);
        $this->drainUntilReady();
    }

    public function releaseSavepoint(string $name): void
    {
        $payload = Protocol::buildTxnReleasePayload($name);
        $this->sendMessage(Protocol::MSG_TXN_RELEASE, $payload, 0, false);
        $this->drainUntilReady();
    }

    public function rollbackToSavepoint(string $name): void
    {
        $payload = Protocol::buildTxnRollbackToPayload($name);
        $this->sendMessage(Protocol::MSG_TXN_ROLLBACK_TO, $payload, 0, false);
        $this->drainUntilReady();
    }

    public function setOption(string $name, string $value): void
    {
        $payload = Protocol::buildSetOptionPayload($name, $value);
        $this->sendMessage(Protocol::MSG_SET_OPTION, $payload, 0, false);
        $this->drainUntilReady();
    }

    public function ping(): void
    {
        $this->sendMessage(Protocol::MSG_PING, '', 0, false);
        while (true) {
            [$type, , $payload] = $this->receive();
            if ($this->handleAsyncMessage($type, $payload)) {
                continue;
            }
            if ($type === Protocol::MSG_PONG || $type === Protocol::MSG_READY) {
                if ($type === Protocol::MSG_READY) {
                    [, $txnId] = Protocol::parseReady($payload);
                    $this->txnId = $txnId;
                }
                return;
            }
            if ($type === Protocol::MSG_ERROR) {
                throw $this->buildQueryException($payload);
            }
        }
    }

    public function subscribe(string $channel, int $subType = Protocol::SUB_TYPE_CHANNEL, string $filterExpr = ''): void
    {
        $payload = Protocol::buildSubscribePayload($subType, $channel, $filterExpr);
        $this->sendMessage(Protocol::MSG_SUBSCRIBE, $payload, 0, false);
        $this->drainUntilReady();
    }

    public function unsubscribe(string $channel): void
    {
        $payload = Protocol::buildUnsubscribePayload($channel);
        $this->sendMessage(Protocol::MSG_UNSUBSCRIBE, $payload, 0, false);
        $this->drainUntilReady();
    }

    public function executeSblr(int $hash, ?string $bytecode = null, array $params = []): ResultStream
    {
        return $this->withResilience('sblr_execute', null, function () use ($hash, $bytecode, $params): ResultStream {
            $paramValues = [];
            foreach ($params as $param) {
                $encoded = TypeCodec::encodeParam($param);
                $paramValues[] = $encoded['param'];
            }
            $payload = Protocol::buildSblrExecutePayload($hash, $bytecode, $paramValues);
            $this->sendMessage(Protocol::MSG_SBLR_EXECUTE, $payload, 0, false);
            $this->sendMessage(Protocol::MSG_SYNC, '', 0, false);
            return new ResultStream($this);
        });
    }

    public function streamControl(int $controlType, int $windowSize, int $timeoutMs): void
    {
        $payload = Protocol::buildStreamControlPayload($controlType, $windowSize, $timeoutMs);
        $this->sendMessage(Protocol::MSG_STREAM_CONTROL, $payload, 0, false);
    }

    public function attachCreate(string $emulationMode, string $dbName): void
    {
        $payload = Protocol::buildAttachCreatePayload($emulationMode, $dbName);
        $this->sendMessage(Protocol::MSG_ATTACH_CREATE, $payload, 0, false);
        $this->drainUntilReady();
    }

    public function attachDetach(): void
    {
        $this->sendMessage(Protocol::MSG_ATTACH_DETACH, '', 0, false);
        $this->drainUntilReady();
    }

    public function attachList(): ResultStream
    {
        $this->sendMessage(Protocol::MSG_ATTACH_LIST, '', 0, false);
        $this->sendMessage(Protocol::MSG_SYNC, '', 0, false);
        return new ResultStream($this);
    }

    public function onNotification(callable $handler): void
    {
        $this->notificationHandlers[] = $handler;
    }

    public function lastPlan(): ?array
    {
        return $this->lastPlan;
    }

    public function lastSblr(): ?array
    {
        return $this->lastSblr;
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
        if ($this->keepaliveTracker !== null) {
            $this->keepaliveManager->unregister($this->connectionId);
            $this->keepaliveTracker = null;
        }
        if ($this->leakGuard !== null) {
            $this->leakGuard->release();
            $this->leakGuard = null;
        }
        $this->keepaliveManager->stop();
        $this->leakDetector->stop();
    }

    private function withResilience(string $operation, ?string $sql, callable $fn): mixed
    {
        if (!$this->circuitBreaker->allowRequest()) {
            throw new ScratchBirdConnectionException('Circuit breaker is OPEN', '08006');
        }
        if ($this->keepaliveTracker !== null && $this->keepaliveTracker->needsValidation()) {
            $this->ping();
            $this->keepaliveTracker->markActive();
        }

        $span = $this->telemetry->startSpan($operation);
        if ($span && $sql) {
            $span->withAttribute('db.statement', TelemetryCollector::sanitizeQuery($sql));
        }

        $success = false;
        try {
            $result = $fn();
            $success = true;
            $this->circuitBreaker->recordSuccess();
            if ($this->keepaliveTracker !== null) {
                $this->keepaliveTracker->markActive();
            }
            return $result;
        } catch (\Throwable $ex) {
            $this->circuitBreaker->recordFailure();
            throw $ex;
        } finally {
            $this->telemetry->endSpan($span, $success);
        }
    }

    public function executeQuery(string $sql, array $params = [], ?int $maxRows = null): ResultStream
    {
        return $this->withResilience('query', $sql, function () use ($sql, $params, $maxRows): ResultStream {
            $pageSize = $maxRows ?? $this->config->fetchSize;
            if (empty($params)) {
                $this->sendSimpleQuery($sql, $pageSize);
            } else {
                $this->sendExtendedQuery($sql, $params, $pageSize);
            }
            return new ResultStream($this);
        });
    }

    public function resumePortal(): void
    {
        $execPayload = Protocol::buildExecutePayload('', $this->lastMaxRows);
        $this->lastQuerySequence = $this->sendMessage(Protocol::MSG_EXECUTE, $execPayload, 0, false);
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

    public function handleAsyncMessage(int $type, string $payload): bool
    {
        if ($type === Protocol::MSG_PARAMETER_STATUS) {
            [$name, $value] = Protocol::parseParameterStatus($payload);
            $this->parameters[$name] = $value;
            if ($name === 'attachment_id') {
                $parsed = $this->parseUuidBytes($value);
                if ($parsed !== null) {
                    $this->attachmentId = $parsed;
                }
            }
            if ($name === 'current_txn_id') {
                $parsed = $this->parseUint64($value);
                if ($parsed !== null) {
                    $this->txnId = $parsed;
                }
            }
            return true;
        }
        if ($type === Protocol::MSG_NOTIFICATION) {
            $notice = Protocol::parseNotification($payload);
            foreach ($this->notificationHandlers as $handler) {
                $handler($notice);
            }
            return true;
        }
        if ($type === Protocol::MSG_QUERY_PLAN) {
            $this->lastPlan = Protocol::parseQueryPlan($payload);
            return true;
        }
        if ($type === Protocol::MSG_SBLR_COMPILED) {
            $this->lastSblr = Protocol::parseSblrCompiled($payload);
            return true;
        }
        return false;
    }

    public function drainUntilReady(): void
    {
        while (true) {
            [$type, , $payload] = $this->receive();
            if ($this->handleAsyncMessage($type, $payload)) {
                continue;
            }
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
        $this->config->protocol = $this->normalizeNativeProtocol($this->config->protocol ?? 'native');
        $this->config->frontDoorMode = $this->normalizeFrontDoorMode($this->config->frontDoorMode ?? 'direct');
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
        if ($this->config->frontDoorMode === 'manager_proxy') {
            $this->performManagerConnect();
        }
        $this->handshake();
        $this->applySchema();
        $this->connected = true;
    }

    private function normalizeNativeProtocol(string $value): string
    {
        $normalized = strtolower(trim($value));
        if ($normalized === '' ||
            $normalized === 'native' ||
            $normalized === 'scratchbird' ||
            $normalized === 'scratchbird-native' ||
            $normalized === 'scratchbird_native') {
            return 'native';
        }
        throw new ScratchBirdNotSupportedException(
            'Only protocol=native is supported; connect to the native parser listener/port.',
            '0A000'
        );
    }

    private function normalizeFrontDoorMode(string $value): string
    {
        $normalized = strtolower(trim($value));
        if ($normalized === '' || $normalized === 'direct') {
            return 'direct';
        }
        if ($normalized === 'manager_proxy' || $normalized === 'manager-proxy' || $normalized === 'managed') {
            return 'manager_proxy';
        }
        throw new ScratchBirdNotSupportedException('front_door_mode must be direct or manager_proxy.', '0A000');
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

    private function managerLpref(string $value): string
    {
        return pack('V', strlen($value)) . $value;
    }

    private function sendManagerFrame(int $type, string $payload): void
    {
        $frame = pack('V', self::MANAGER_PROTOCOL_MAGIC)
            . pack('v', self::MANAGER_PROTOCOL_VERSION)
            . chr($type)
            . chr(0)
            . pack('V', strlen($payload))
            . $payload;
        $total = 0;
        $length = strlen($frame);
        while ($total < $length) {
            $written = fwrite($this->socket, substr($frame, $total));
            if ($written === false || $written === 0) {
                throw new ScratchBirdConnectionException('Manager frame write failed', '08006');
            }
            $total += $written;
        }
    }

    private function recvManagerFrame(): array
    {
        $header = $this->readExact(self::MANAGER_HEADER_SIZE);
        $magic = unpack('V', substr($header, 0, 4))[1];
        if ($magic !== self::MANAGER_PROTOCOL_MAGIC) {
            throw new ScratchBirdConnectionException('Manager frame magic mismatch', '08P01');
        }
        $version = unpack('v', substr($header, 4, 2))[1];
        if ($version !== self::MANAGER_PROTOCOL_VERSION) {
            throw new ScratchBirdConnectionException('Manager frame version mismatch', '08P01');
        }
        $type = ord($header[6]);
        $length = unpack('V', substr($header, 8, 4))[1];
        if ($length > self::MANAGER_MAX_PAYLOAD_SIZE) {
            throw new ScratchBirdConnectionException('Manager payload too large', '08P01');
        }
        $payload = $length > 0 ? $this->readExact($length) : '';
        return [$type, $payload];
    }

    private function performManagerConnect(): void
    {
        if ($this->config->managerAuthToken === '') {
            throw new ScratchBirdConnectionException('manager_proxy mode requires manager_auth_token', '08001');
        }
        $managerUser = $this->config->managerUsername !== ''
            ? $this->config->managerUsername
            : ($this->config->user !== '' ? $this->config->user : 'admin');
        $managerDatabase = $this->config->managerDatabase !== '' ? $this->config->managerDatabase : $this->config->database;
        $managerProfile = $this->config->managerConnectionProfile !== '' ? $this->config->managerConnectionProfile : 'native_v3';
        $managerIntent = $this->config->managerClientIntent !== '' ? $this->config->managerClientIntent : 'native_v3';
        $managerFlags = $this->config->managerClientFlags & 0xFFFF;
        $authFastPath = $this->config->managerAuthFastPath !== false;

        $helloPayload = pack('vv', self::MCP_PROTOCOL_VERSION, $managerFlags);
        $this->sendManagerFrame(self::MCP_MSG_HELLO, $helloPayload);
        [$type] = $this->recvManagerFrame();
        if ($type !== self::MCP_MSG_STATUS_RESPONSE) {
            throw new ScratchBirdConnectionException('Expected MCP hello status response', '08P01');
        }

        $authStart = $this->managerLpref($managerUser)
            . chr(self::MCP_AUTH_METHOD_TOKEN);
        if ($authFastPath) {
            $token = $this->config->managerAuthToken;
            $authStart .= pack('V', strlen($token)) . $token;
        } else {
            $authStart .= pack('V', 0);
        }
        $this->sendManagerFrame(self::MCP_MSG_AUTH_START, $authStart);
        [$type, $payload] = $this->recvManagerFrame();
        if ($type === self::MCP_MSG_AUTH_CHALLENGE) {
            $token = $this->config->managerAuthToken;
            $this->sendManagerFrame(self::MCP_MSG_AUTH_CONTINUE, pack('V', strlen($token)) . $token);
            [$type, $payload] = $this->recvManagerFrame();
        }
        if ($type !== self::MCP_MSG_AUTH_RESPONSE) {
            throw new ScratchBirdConnectionException('Expected MCP auth response', '08P01');
        }
        if (strlen($payload) < (1 + 4 + 256)) {
            throw new ScratchBirdConnectionException('Truncated MCP auth response', '08P01');
        }
        if (ord($payload[0]) !== 0) {
            $err = rtrim(substr($payload, 5, 256), "\0");
            throw new ScratchBirdAuthException($err !== '' ? $err : 'MCP authentication failed', '28000');
        }

        $nonce = random_bytes(16);
        $dbConnect = 'MCP1'
            . $this->managerLpref($managerDatabase)
            . $this->managerLpref($managerProfile)
            . $this->managerLpref($managerIntent)
            . pack('v', strlen($nonce))
            . $nonce;
        $this->sendManagerFrame(self::MCP_MSG_DB_CONNECT, $dbConnect);
        [$type, $payload] = $this->recvManagerFrame();
        if ($type !== self::MCP_MSG_CONNECT_RESPONSE) {
            throw new ScratchBirdConnectionException('Expected MCP connect response', '08P01');
        }
        if (strlen($payload) < (1 + 2 + 2 + 16 + 64 + 32)) {
            throw new ScratchBirdConnectionException('Truncated MCP connect response', '08P01');
        }
        if (ord($payload[0]) !== 0) {
            $err = 'MCP database connect failed';
            $errOffset = 1 + 2 + 2 + 16 + 64 + 32;
            if (strlen($payload) >= $errOffset + 4) {
                $errLen = unpack('V', substr($payload, $errOffset, 4))[1];
                if (strlen($payload) >= $errOffset + 4 + $errLen) {
                    $err = substr($payload, $errOffset + 4, $errLen);
                }
            }
            throw new ScratchBirdAuthException($err, '28000');
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
        if ($maxRows === 0) {
            $this->sendMessage(Protocol::MSG_SYNC, '', 0, false);
        }
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

    private function parseUuidBytes(string $value): ?string
    {
        $hex = strtolower(str_replace('-', '', trim($value)));
        if (!preg_match('/^[0-9a-f]{32}$/', $hex)) {
            return null;
        }
        $bin = @hex2bin($hex);
        if ($bin === false || strlen($bin) !== 16) {
            return null;
        }
        return $bin;
    }

    private function parseUint64(string $value): ?int
    {
        $trimmed = trim($value);
        if ($trimmed === '') {
            return null;
        }
        if (!ctype_digit($trimmed)) {
            return null;
        }
        return (int) $trimmed;
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
