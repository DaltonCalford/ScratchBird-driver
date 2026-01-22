<?php

namespace ScratchBird\PDO;

final class ScratchBirdPDO
{
    private Connection $connection;

    public function __construct(string $dsn, ?string $username = null, ?string $password = null, array $options = [])
    {
        $this->connection = new Connection($dsn, $username, $password, $options);
    }

    public function prepare(string $statement, array $options = []): Statement|false
    {
        try {
            return $this->connection->prepare($statement, $options);
        } catch (\Throwable) {
            return false;
        }
    }

    public function query(string $statement, mixed ...$fetchModeArgs): Statement|false
    {
        try {
            return $this->connection->query($statement, ...$fetchModeArgs);
        } catch (\Throwable) {
            return false;
        }
    }

    public function exec(string $statement): int|false
    {
        return $this->connection->exec($statement);
    }

    public function beginTransaction(): bool
    {
        return $this->connection->beginTransaction();
    }

    public function commit(): bool
    {
        return $this->connection->commit();
    }

    public function rollBack(): bool
    {
        return $this->connection->rollBack();
    }

    public function lastInsertId(?string $name = null): string|false
    {
        return $this->connection->lastInsertId($name);
    }

    public function setAttribute(int $attribute, mixed $value): bool
    {
        return $this->connection->setAttribute($attribute, $value);
    }

    public function getAttribute(int $attribute): mixed
    {
        return $this->connection->getAttribute($attribute);
    }

    public function errorInfo(): array
    {
        return $this->connection->errorInfo();
    }

    public function errorCode(): ?string
    {
        return $this->connection->errorCode();
    }

    public function close(): void
    {
        $this->connection->close();
    }
}
