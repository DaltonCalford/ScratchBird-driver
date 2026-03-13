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

final class Statement
{
    private Connection $connection;
    private string $sql;
    private array $options;
    private array $boundValues = [];
    private array $boundParams = [];
    private ?ResultStream $stream = null;
    private array $currentRow = [];
    private int $fetchMode = \PDO::FETCH_ASSOC;
    private int $rowCount = 0;
    private ?int $lastInsertId = null;
    private string $statusMessage = '';
    /** @var array<int, array{0: int}> */
    private array $generatedKeys = [];
    private int $lastCompletionCount = 0;

    public function __construct(Connection $connection, string $sql, array $options = [])
    {
        $this->connection = $connection;
        $this->sql = $sql;
        $this->options = $options;
    }

    public function bindParam(string|int $param, mixed &$var, int $type = \PDO::PARAM_STR, int $length = 0, mixed $driverOptions = null): bool
    {
        $this->boundParams[$param] = &$var;
        return true;
    }

    public function bindValue(string|int $param, mixed $value, int $type = \PDO::PARAM_STR): bool
    {
        $this->boundValues[$param] = $value;
        return true;
    }

    public function execute(?array $params = null): bool
    {
        $finalParams = $this->gatherParams($params);
        $normalized = Sql::normalize($this->sql, $finalParams);
        $this->stream = $this->connection->executeQuery($normalized['sql'], $normalized['params']);
        $this->resetExecutionState();
        return true;
    }

    public function fetch(int $mode = \PDO::FETCH_ASSOC, mixed ...$args): mixed
    {
        if ($this->stream === null) {
            return false;
        }
        $row = $this->stream->readRow();
        if ($row === null) {
            $this->rowCount = $this->stream->rowsAffected();
            $this->statusMessage = $this->stream->commandTag();
            $this->lastInsertId = $this->stream->lastInsertId();
            $completionCount = $this->stream->completionCount();
            if ($completionCount > $this->lastCompletionCount) {
                $this->lastCompletionCount = $completionCount;
                $this->captureGeneratedKey($this->lastInsertId);
            }
            return false;
        }
        $this->currentRow = $row;
        return $this->formatRow($row, $mode);
    }

    public function fetchAll(int $mode = \PDO::FETCH_ASSOC, mixed ...$args): array
    {
        $rows = [];
        while (true) {
            $row = $this->fetch($mode);
            if ($row === false) {
                break;
            }
            $rows[] = $row;
        }
        return $rows;
    }

    public function fetchColumn(int $column = 0): mixed
    {
        $row = $this->fetch(\PDO::FETCH_NUM);
        if ($row === false) {
            return false;
        }
        return $row[$column] ?? false;
    }

    public function rowCount(): int
    {
        return $this->rowCount;
    }

    public function columnCount(): int
    {
        return $this->stream ? count($this->stream->columns()) : 0;
    }

    public function getColumnMeta(int $column): array
    {
        $meta = $this->stream?->columns()[$column] ?? null;
        if ($meta === null) {
            return [];
        }
        return [
            'name' => $meta['name'],
            'native_type' => TypeDecoder::oidName($meta['typeOid']),
            'len' => $meta['typeModifier'],
            'format' => $meta['format'],
        ];
    }

    public function closeCursor(): bool
    {
        $this->stream = null;
        $this->resetExecutionState();
        return true;
    }

    public function setFetchMode(int $mode, mixed ...$args): bool
    {
        $this->fetchMode = $mode;
        return true;
    }

    public function nextRowset(): bool
    {
        if ($this->stream === null) {
            return false;
        }
        while ($this->stream->readRow() !== null) {
            // Drain active result set before advancing.
        }
        if (!$this->stream->hasNextResultSet()) {
            return false;
        }
        if (!$this->stream->nextResultSet()) {
            return false;
        }
        $this->rowCount = 0;
        $this->currentRow = [];
        $this->lastInsertId = null;
        $this->statusMessage = '';
        return true;
    }

    public function nextset(): bool
    {
        return $this->nextRowset();
    }

    public function statusMessage(): string
    {
        return $this->statusMessage;
    }

    public function lastInsertId(): int|false
    {
        return $this->lastInsertId ?? false;
    }

    /**
     * @return array<int, array{0: int}>
     */
    public function getGeneratedKeys(): array
    {
        return $this->generatedKeys;
    }

    public function fields(): array
    {
        return $this->stream?->columns() ?? [];
    }

    private function gatherParams(?array $params): array
    {
        $finalParams = [];
        foreach ($this->boundParams as $key => $value) {
            $finalParams[$key] = $value;
        }
        foreach ($this->boundValues as $key => $value) {
            $finalParams[$key] = $value;
        }
        if ($params !== null) {
            foreach ($params as $key => $value) {
                $finalParams[$key] = $value;
            }
        }
        return $finalParams;
    }

    private function formatRow(array $row, int $mode): array
    {
        $columns = $this->stream?->columns() ?? [];
        if ($mode === \PDO::FETCH_NUM) {
            return array_values($row);
        }
        if ($mode === \PDO::FETCH_ASSOC) {
            $assoc = [];
            foreach ($row as $idx => $value) {
                $name = $columns[$idx]['name'] ?? (string)$idx;
                $assoc[$name] = $value;
            }
            return $assoc;
        }
        if ($mode === \PDO::FETCH_BOTH) {
            $assoc = $this->formatRow($row, \PDO::FETCH_ASSOC);
            foreach ($row as $idx => $value) {
                $assoc[$idx] = $value;
            }
            return $assoc;
        }
        return $row;
    }

    private function resetExecutionState(): void
    {
        $this->rowCount = 0;
        $this->currentRow = [];
        $this->lastInsertId = null;
        $this->statusMessage = '';
        $this->generatedKeys = [];
        $this->lastCompletionCount = 0;
    }

    private function captureGeneratedKey(?int $lastInsertId): void
    {
        if ($lastInsertId === null) {
            return;
        }
        $this->generatedKeys[] = [$lastInsertId];
    }
}
