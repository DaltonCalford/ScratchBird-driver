<?php

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
        $query = Sql::substitute($this->sql, $finalParams);
        $this->stream = $this->connection->executeQuery($query);
        $this->rowCount = 0;
        $this->currentRow = [];
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
            'native_type' => TypeDecoder::wireTypeName($meta['wireType']),
            'len' => $meta['typeModifier'],
            'format' => $meta['formatCode'],
        ];
    }

    public function closeCursor(): bool
    {
        $this->stream = null;
        return true;
    }

    public function setFetchMode(int $mode, mixed ...$args): bool
    {
        $this->fetchMode = $mode;
        return true;
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
}
