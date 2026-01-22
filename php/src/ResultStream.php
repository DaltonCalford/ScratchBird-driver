<?php

namespace ScratchBird\PDO;

final class ResultStream
{
    private Connection $connection;
    private array $columns = [];
    private int $rowCountHint = -1;
    private int $rowsAffected = -1;
    private string $commandTag = '';
    private bool $done = false;

    public function __construct(Connection $connection)
    {
        $this->connection = $connection;
    }

    public function columns(): array
    {
        return $this->columns;
    }

    public function rowsAffected(): int
    {
        return $this->rowsAffected >= 0 ? $this->rowsAffected : $this->rowCountHint;
    }

    public function commandTag(): string
    {
        return $this->commandTag;
    }

    public function readRow(): ?array
    {
        if ($this->done) {
            return null;
        }
        while (true) {
            [$type, , $payload] = $this->connection->receive();
            switch ($type) {
                case Protocol::MSG_QUERY_ERROR:
                    throw $this->connection->buildQueryException($payload);
                case Protocol::MSG_QUERY_RESULT:
                    [, , $rows] = Protocol::parseQueryResult($payload);
                    $this->rowCountHint = $rows;
                    break;
                case Protocol::MSG_ROW_DESCRIPTION:
                    $this->columns = Protocol::parseRowDescription($payload);
                    break;
                case Protocol::MSG_ROW_DATA:
                    $values = Protocol::parseRowData($payload);
                    $row = [];
                    foreach ($values as $index => $value) {
                        $wireType = $this->columns[$index]['wireType'] ?? 0;
                        $row[] = TypeDecoder::decode($wireType, $value['data']);
                    }
                    return $row;
                case Protocol::MSG_COMMAND_COMPLETE:
                    [$tag, $rows] = Protocol::parseCommandComplete($payload);
                    $this->commandTag = $tag;
                    $this->rowsAffected = $rows;
                    break;
                case Protocol::MSG_END_RESULTS:
                    $this->done = true;
                    return null;
            }
        }
    }
}
