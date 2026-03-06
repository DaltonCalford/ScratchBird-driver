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

    public function nativeSql(string $sql, array $params = []): string
    {
        return $this->connection->nativeSql($sql, $params);
    }

    public function nativeCallableSql(string $sql, array $params = []): string
    {
        return $this->connection->nativeCallableSql($sql, $params);
    }

    public function call(string $sql, array $params = []): Statement
    {
        return $this->connection->call($sql, $params);
    }

    /**
     * @return array<int, array{rows: array, rowCount: int, fields: array, command: string, lastId: int|false}>
     */
    public function queryMulti(string $sql, array $params = []): array
    {
        return $this->connection->queryMulti($sql, $params);
    }

    /**
     * @return array<int, array{rows: array, rowCount: int, fields: array, command: string, lastId: int|false}>
     */
    public function executeMulti(string $sql, array $params = []): array
    {
        return $this->connection->executeMulti($sql, $params);
    }

    /**
     * @return array{items: array<int, array{index: int, rowCount: int, fields: array, command: string, lastId: int|false}>, totalRowCount: int}
     */
    public function executeBatch(string $sql, iterable $batchParams): array
    {
        return $this->connection->executeBatch($sql, $batchParams);
    }

    /**
     * @return array{items: array<int, array{index: int, rowCount: int, fields: array, command: string, lastId: int|false}>, totalRowCount: int}
     */
    public function queryBatch(string $sql, iterable $batchParams): array
    {
        return $this->connection->queryBatch($sql, $batchParams);
    }

    /**
     * @return array<int, array{0: int}>
     */
    public function executeWithGeneratedKeys(string $sql, array $params = []): array
    {
        return $this->connection->executeWithGeneratedKeys($sql, $params);
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    public function getSchema(string $collectionName = 'tables', array $restrictions = []): array
    {
        return $this->connection->getSchema($collectionName, $restrictions);
    }

    /**
     * @return array{database: ?string, schemas: array<int, array{name: string, path: string, terminal: bool, children: array}>}
     */
    public function getSchemaTree(?bool $expandParents = null, ?string $database = null, array $restrictions = []): array
    {
        return $this->connection->getSchemaTree($expandParents, $database, $restrictions);
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

    public function inTransaction(): bool
    {
        return $this->connection->inTransaction();
    }

    public function rollBack(): bool
    {
        return $this->connection->rollBack();
    }

    public function savepoint(string $name): void
    {
        $this->connection->savepoint($name);
    }

    public function releaseSavepoint(string $name): void
    {
        $this->connection->releaseSavepoint($name);
    }

    public function rollbackToSavepoint(string $name): void
    {
        $this->connection->rollbackToSavepoint($name);
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
