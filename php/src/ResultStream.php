<?php

namespace ScratchBird\PDO;

final class ResultStream
{
    private Connection $connection;
    private array $columns = [];
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
        return $this->rowsAffected;
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
                case Protocol::MSG_ERROR:
                    throw $this->connection->buildQueryException($payload);
                case Protocol::MSG_ROW_DESCRIPTION:
                    $this->columns = Protocol::parseRowDescription($payload);
                    break;
                case Protocol::MSG_DATA_ROW:
                    $values = Protocol::parseDataRow($payload);
                    $row = [];
                    foreach ($values as $index => $value) {
                        $typeOid = $this->columns[$index]['typeOid'] ?? 0;
                        $format = $this->columns[$index]['format'] ?? TypeDecoder::FORMAT_BINARY;
                        $row[] = TypeDecoder::decode($typeOid, $value['data'], $format);
                    }
                    return $row;
                case Protocol::MSG_COMMAND_COMPLETE:
                    [, $rows, , $tag] = Protocol::parseCommandComplete($payload);
                    $this->commandTag = $tag;
                    $this->rowsAffected = (int)$rows;
                    break;
                case Protocol::MSG_READY:
                    $this->done = true;
                    return null;
                case Protocol::MSG_EMPTY_QUERY:
                    break;
            }
        }
    }
}
