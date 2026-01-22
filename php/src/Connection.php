<?php

namespace ScratchBird\PDO;

final class Connection
{
    private Config $config;
    /** @var resource|null */
    private $socket = null;
    private string $sessionId = '';
    private bool $inTransaction = false;
    private array $attributes = [];
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
        try {
            $payload = Protocol::buildBegin($this->sessionId, 0, false);
            $this->send($payload);
            $this->drainUntilComplete();
            $this->inTransaction = true;
            return true;
        } catch (\Throwable $ex) {
            $this->recordError($ex);
            return false;
        }
    }

    public function commit(): bool
    {
        try {
            $payload = Protocol::buildCommit($this->sessionId);
            $this->send($payload);
            $this->drainUntilComplete();
            $this->inTransaction = false;
            return true;
        } catch (\Throwable $ex) {
            $this->recordError($ex);
            return false;
        }
    }

    public function rollBack(): bool
    {
        try {
            $payload = Protocol::buildRollback($this->sessionId);
            $this->send($payload);
            $this->drainUntilComplete();
            $this->inTransaction = false;
            return true;
        } catch (\Throwable $ex) {
            $this->recordError($ex);
            return false;
        }
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
        try {
            if ($this->sessionId !== '') {
                $payload = Protocol::buildDisconnect($this->sessionId);
                $this->send($payload);
            }
        } catch (\Throwable) {
        }
        fclose($this->socket);
        $this->socket = null;
    }

    public function executeQuery(string $sql): ResultStream
    {
        $payload = Protocol::buildQuery($this->sessionId, $sql, 0);
        $this->send($payload);
        return new ResultStream($this);
    }

    public function send(string $payload): void
    {
        if ($this->socket === null) {
            throw new ScratchBirdConnectionException('Connection not open', '08006');
        }
        if ($this->config->socketTimeoutMs > 0) {
            stream_set_timeout($this->socket, 0, $this->config->socketTimeoutMs * 1000);
        }
        $total = 0;
        $length = strlen($payload);
        while ($total < $length) {
            $written = fwrite($this->socket, substr($payload, $total));
            if ($written === false || $written === 0) {
                throw new ScratchBirdConnectionException('Connection closed', '08006');
            }
            $total += $written;
        }
    }

    public function receive(): array
    {
        if ($this->socket === null) {
            throw new ScratchBirdConnectionException('Connection not open', '08006');
        }
        if ($this->config->socketTimeoutMs > 0) {
            stream_set_timeout($this->socket, 0, $this->config->socketTimeoutMs * 1000);
        }
        $header = $this->readExact(12);
        [$type, $flags, $length] = Protocol::decodeHeader($header);
        $payload = $length > 0 ? $this->readExact($length) : '';
        return [$type, $flags, $payload];
    }

    public function drainUntilComplete(): array
    {
        $tag = '';
        $rows = 0;
        while (true) {
            [$type, , $payload] = $this->receive();
            if ($type === Protocol::MSG_QUERY_ERROR) {
                throw $this->buildQueryException($payload);
            }
            if ($type === Protocol::MSG_COMMAND_COMPLETE) {
                [$tag, $rows] = Protocol::parseCommandComplete($payload);
            }
            if ($type === Protocol::MSG_END_RESULTS) {
                return [$tag, $rows];
            }
        }
    }

    private function connect(): void
    {
        $timeout = $this->config->connectTimeoutMs / 1000;
        $address = sprintf('tcp://%s:%d', $this->config->host, $this->config->port);
        $socket = @stream_socket_client($address, $errno, $errstr, $timeout);
        if ($socket === false) {
            throw new ScratchBirdConnectionException($errstr ?: 'Connection failed', '08001');
        }
        stream_set_blocking($socket, true);
        $this->socket = $socket;
        $this->applyTls($address);
        $this->handshake();
    }

    private function applyTls(string $address): void
    {
        $mode = strtolower($this->config->sslMode ?: 'prefer');
        if ($mode === 'disable') {
            return;
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
        }
        stream_context_set_option($this->socket, $options);
        $result = @stream_socket_enable_crypto($this->socket, true, STREAM_CRYPTO_METHOD_TLSv1_3_CLIENT);
        if ($result === true) {
            return;
        }
        if (in_array($mode, ['allow', 'prefer'], true)) {
            fclose($this->socket);
            $timeout = $this->config->connectTimeoutMs / 1000;
            $socket = @stream_socket_client($address, $errno, $errstr, $timeout);
            if ($socket === false) {
                throw new ScratchBirdConnectionException($errstr ?: 'Connection failed', '08001');
            }
            stream_set_blocking($socket, true);
            $this->socket = $socket;
            return;
        }
        throw new ScratchBirdConnectionException('TLS handshake failed', '08001');
    }

    private function handshake(): void
    {
        $payload = Protocol::buildConnectRequest($this->config->database, $this->config->applicationName, getmypid());
        $this->send($payload);
        [$type, , $body] = $this->receive();
        if ($type !== Protocol::MSG_CONNECT_RESPONSE) {
            throw new ScratchBirdConnectionException('Unexpected connect response', '08001');
        }
        [$ok, $sessionId, , , , $error] = Protocol::parseConnectResponse($body);
        if (!$ok) {
            throw new ScratchBirdConnectionException($error, '08001');
        }
        $this->sessionId = $sessionId;
        if ($this->config->user !== '') {
            $this->authenticate();
        }
    }

    private function authenticate(): void
    {
        $scram = new Scram($this->config->user);
        $first = $scram->clientFirstMessage();
        $payload = Protocol::buildAuthRequest($this->sessionId, $this->config->user, Protocol::AUTH_SCRAM_SHA256, $first);
        $this->send($payload);
        [$type, , $body] = $this->receive();
        if ($type !== Protocol::MSG_AUTH_RESPONSE) {
            throw new ScratchBirdAuthException('Unexpected auth response', '28000');
        }
        [$status, , $error, $extra] = Protocol::parseAuthResponse($body);
        if ($status !== 2) {
            throw new ScratchBirdAuthException($error, '28000');
        }
        $final = $scram->handleServerFirst($this->config->password, $extra);
        $payload = Protocol::buildAuthRequest($this->sessionId, $this->config->user, Protocol::AUTH_SCRAM_SHA256, $final);
        $this->send($payload);
        [$type, , $body] = $this->receive();
        if ($type !== Protocol::MSG_AUTH_RESPONSE) {
            throw new ScratchBirdAuthException('Unexpected SCRAM final', '28000');
        }
        [$status, , $error, $extra] = Protocol::parseAuthResponse($body);
        if ($status !== 0) {
            throw new ScratchBirdAuthException($error, '28000');
        }
        if ($extra !== '') {
            $scram->verifyServerFinal($extra);
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
        [, $sqlState, $message, $detail, $hint] = Protocol::parseQueryError($payload);
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
