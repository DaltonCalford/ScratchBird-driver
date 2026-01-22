<?php

namespace ScratchBird\PDO;

final class Protocol
{
    public const MAGIC = 0x42444253;
    public const VERSION = 0x0100;

    public const MSG_CONNECT_REQUEST = 0x01;
    public const MSG_CONNECT_RESPONSE = 0x02;
    public const MSG_DISCONNECT = 0x03;
    public const MSG_AUTH_REQUEST = 0x10;
    public const MSG_AUTH_RESPONSE = 0x11;
    public const MSG_QUERY = 0x20;
    public const MSG_QUERY_RESULT = 0x21;
    public const MSG_QUERY_ERROR = 0x22;
    public const MSG_QUERY_CANCEL = 0x23;
    public const MSG_PREPARE = 0x30;
    public const MSG_PREPARE_RESPONSE = 0x31;
    public const MSG_EXECUTE = 0x32;
    public const MSG_CLOSE_STATEMENT = 0x33;
    public const MSG_DESCRIBE = 0x34;
    public const MSG_DESCRIBE_RESPONSE = 0x35;
    public const MSG_BEGIN = 0x40;
    public const MSG_COMMIT = 0x41;
    public const MSG_ROLLBACK = 0x42;
    public const MSG_ROW_DESCRIPTION = 0x50;
    public const MSG_ROW_DATA = 0x51;
    public const MSG_END_RESULTS = 0x52;
    public const MSG_COMMAND_COMPLETE = 0x53;

    public const AUTH_SCRAM_SHA256 = 2;

    public static function encodeMessage(int $type, string $payload, int $flags = 0): string
    {
        $header = pack('VvCCV', self::MAGIC, self::VERSION, $type, $flags, strlen($payload));
        return $header . $payload;
    }

    public static function decodeHeader(string $header): array
    {
        if (strlen($header) !== 12) {
            throw new \RuntimeException('Invalid header length');
        }
        [$magic, $version, $type, $flags, $length] = array_values(unpack('Vmagic/vversion/Ctype/Cflags/Vlen', $header));
        if ($magic !== self::MAGIC) {
            throw new \RuntimeException('Invalid protocol magic');
        }
        return [$type, $flags, $length];
    }

    public static function buildConnectRequest(string $database, string $clientName, int $pid): string
    {
        $payload = pack('vvV', self::VERSION, 0, $pid)
            . self::writeNullTerminated($database, 256)
            . self::writeNullTerminated($clientName, 64)
            . self::writeNullTerminated('1.0.0', 32);
        return self::encodeMessage(self::MSG_CONNECT_REQUEST, $payload);
    }

    public static function parseConnectResponse(string $payload): array
    {
        if (strlen($payload) < 1 + 2 + 2 + 16 + 64 + 32) {
            throw new \RuntimeException('Connect response truncated');
        }
        $offset = 0;
        $status = ord($payload[$offset]);
        $offset += 1;
        $version = unpack('v', substr($payload, $offset, 2))[1];
        $offset += 2;
        $offset += 2;
        $sessionId = substr($payload, $offset, 16);
        $offset += 16;
        $serverName = self::readNullTerminated(substr($payload, $offset, 64));
        $offset += 64;
        $serverVersion = self::readNullTerminated(substr($payload, $offset, 32));
        $offset += 32;
        $error = '';
        if ($status !== 0 && $offset + 2 <= strlen($payload)) {
            $len = unpack('v', substr($payload, $offset, 2))[1];
            $offset += 2;
            $error = substr($payload, $offset, $len);
        }
        return [$status === 0, $sessionId, $version, $serverName, $serverVersion, $error];
    }

    public static function buildAuthRequest(string $sessionId, string $username, int $method, string $payload): string
    {
        if (strlen($sessionId) !== 16) {
            throw new \RuntimeException('sessionId must be 16 bytes');
        }
        $buffer = $sessionId
            . self::writeNullTerminated($username, 64)
            . pack('C', $method)
            . pack('v', strlen($payload))
            . $payload;
        return self::encodeMessage(self::MSG_AUTH_REQUEST, $buffer);
    }

    public static function parseAuthResponse(string $payload): array
    {
        if (strlen($payload) < 1 + 4 + 256) {
            throw new \RuntimeException('Auth response truncated');
        }
        $status = ord($payload[0]);
        $userId = unpack('V', substr($payload, 1, 4))[1];
        $error = self::readNullTerminated(substr($payload, 5, 256));
        $extra = substr($payload, 5 + 256);
        return [$status, $userId, $error, $extra];
    }

    public static function buildQuery(string $sessionId, string $sql, int $flags = 0): string
    {
        if (strlen($sessionId) !== 16) {
            throw new \RuntimeException('sessionId must be 16 bytes');
        }
        $sqlBytes = $sql;
        $payload = $sessionId
            . pack('V', strlen($sqlBytes))
            . pack('C', $flags)
            . $sqlBytes;
        return self::encodeMessage(self::MSG_QUERY, $payload);
    }

    public static function parseRowDescription(string $payload): array
    {
        if (strlen($payload) < 2) {
            throw new \RuntimeException('Row description truncated');
        }
        $offset = 0;
        $count = unpack('v', substr($payload, $offset, 2))[1];
        $offset += 2;
        $columns = [];
        for ($i = 0; $i < $count; $i++) {
            $nameLen = unpack('v', substr($payload, $offset, 2))[1];
            $offset += 2;
            $name = substr($payload, $offset, $nameLen);
            $offset += $nameLen;
            $wireType = ord($payload[$offset]);
            $offset += 1;
            $modifier = unpack('V', substr($payload, $offset, 4))[1];
            $offset += 4;
            $format = unpack('v', substr($payload, $offset, 2))[1];
            $offset += 2;
            $columns[] = [
                'name' => $name,
                'wireType' => $wireType,
                'typeModifier' => $modifier,
                'formatCode' => $format,
            ];
        }
        return $columns;
    }

    public static function parseRowData(string $payload): array
    {
        if (strlen($payload) < 2) {
            throw new \RuntimeException('Row data truncated');
        }
        $offset = 0;
        $count = unpack('v', substr($payload, $offset, 2))[1];
        $offset += 2;
        $values = [];
        for ($i = 0; $i < $count; $i++) {
            $length = unpack('V', substr($payload, $offset, 4))[1];
            $offset += 4;
            if ($length >= 0x80000000) {
                $values[] = ['data' => null];
                continue;
            }
            $data = substr($payload, $offset, $length);
            $offset += $length;
            $values[] = ['data' => $data];
        }
        return $values;
    }

    public static function parseCommandComplete(string $payload): array
    {
        if (strlen($payload) < 64 + 8) {
            throw new \RuntimeException('Command complete truncated');
        }
        $tag = self::readNullTerminated(substr($payload, 0, 64));
        $rows = unpack('P', substr($payload, 64, 8))[1];
        return [$tag, (int)$rows];
    }

    public static function parseQueryResult(string $payload): array
    {
        if (strlen($payload) < 1 + 4 + 8) {
            throw new \RuntimeException('Query result truncated');
        }
        $status = ord($payload[0]);
        $count = unpack('V', substr($payload, 1, 4))[1];
        $rows = unpack('P', substr($payload, 5, 8))[1];
        return [$status, $count, (int)$rows];
    }

    public static function parseQueryError(string $payload): array
    {
        if (strlen($payload) < 4 + 6 + 2 + 2 + 2) {
            throw new \RuntimeException('Query error truncated');
        }
        $offset = 0;
        $code = unpack('V', substr($payload, $offset, 4))[1];
        $offset += 4;
        $sqlState = self::readNullTerminated(substr($payload, $offset, 6));
        $offset += 6;
        $msgLen = unpack('v', substr($payload, $offset, 2))[1];
        $offset += 2;
        $detailLen = unpack('v', substr($payload, $offset, 2))[1];
        $offset += 2;
        $hintLen = unpack('v', substr($payload, $offset, 2))[1];
        $offset += 2;
        $message = substr($payload, $offset, $msgLen);
        $offset += $msgLen;
        $detail = substr($payload, $offset, $detailLen);
        $offset += $detailLen;
        $hint = substr($payload, $offset, $hintLen);
        return [$code, $sqlState, $message, $detail, $hint];
    }

    public static function buildBegin(string $sessionId, int $isolation = 0, bool $readOnly = false): string
    {
        $payload = $sessionId . pack('CC', $isolation, $readOnly ? 1 : 0);
        return self::encodeMessage(self::MSG_BEGIN, $payload);
    }

    public static function buildCommit(string $sessionId): string
    {
        return self::encodeMessage(self::MSG_COMMIT, $sessionId);
    }

    public static function buildRollback(string $sessionId): string
    {
        return self::encodeMessage(self::MSG_ROLLBACK, $sessionId);
    }

    public static function buildDisconnect(string $sessionId): string
    {
        return self::encodeMessage(self::MSG_DISCONNECT, $sessionId);
    }

    private static function writeNullTerminated(string $value, int $length): string
    {
        $value = substr($value, 0, $length - 1);
        return str_pad($value, $length, "\0");
    }

    private static function readNullTerminated(string $data): string
    {
        $pos = strpos($data, "\0");
        if ($pos === false) {
            return $data;
        }
        return substr($data, 0, $pos);
    }
}
