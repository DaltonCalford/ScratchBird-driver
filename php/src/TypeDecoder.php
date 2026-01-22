<?php

namespace ScratchBird\PDO;

final class TypeDecoder
{
    public const WIRE_BOOL = 0x01;
    public const WIRE_INT16 = 0x02;
    public const WIRE_INT32 = 0x03;
    public const WIRE_INT64 = 0x04;
    public const WIRE_FLOAT32 = 0x05;
    public const WIRE_FLOAT64 = 0x06;
    public const WIRE_DECIMAL = 0x07;
    public const WIRE_VARCHAR = 0x08;
    public const WIRE_CHAR = 0x09;
    public const WIRE_BYTEA = 0x0A;
    public const WIRE_DATE = 0x0B;
    public const WIRE_TIME = 0x0C;
    public const WIRE_TIMESTAMP = 0x0D;
    public const WIRE_TIMESTAMPTZ = 0x0E;
    public const WIRE_INTERVAL = 0x0F;
    public const WIRE_UUID = 0x10;
    public const WIRE_JSON = 0x11;
    public const WIRE_JSONB = 0x12;
    public const WIRE_ARRAY = 0x13;
    public const WIRE_VECTOR = 0x16;
    public const WIRE_MONEY = 0x17;
    public const WIRE_XML = 0x18;
    public const WIRE_INET = 0x19;
    public const WIRE_CIDR = 0x1A;
    public const WIRE_TSVECTOR = 0x1C;
    public const WIRE_TSQUERY = 0x1D;

    public static function decode(int $wireType, ?string $data): mixed
    {
        if ($data === null) {
            return null;
        }
        return match ($wireType) {
            self::WIRE_BOOL => ord($data[0]) === 1,
            self::WIRE_INT16 => self::unpackInt16($data),
            self::WIRE_INT32 => self::unpackInt32($data),
            self::WIRE_INT64 => self::unpackInt64($data),
            self::WIRE_FLOAT32 => self::unpackFloat32($data),
            self::WIRE_FLOAT64 => self::unpackFloat64($data),
            self::WIRE_DECIMAL => $data,
            self::WIRE_VARCHAR,
            self::WIRE_CHAR,
            self::WIRE_JSON,
            self::WIRE_JSONB,
            self::WIRE_XML,
            self::WIRE_TSVECTOR,
            self::WIRE_TSQUERY => $data,
            self::WIRE_BYTEA => $data,
            self::WIRE_DATE => self::decodeDate($data),
            self::WIRE_TIME => self::decodeTime($data),
            self::WIRE_TIMESTAMP,
            self::WIRE_TIMESTAMPTZ => self::decodeTimestamp($data),
            self::WIRE_INTERVAL => self::decodeInterval($data),
            self::WIRE_UUID => self::decodeUuid($data),
            self::WIRE_MONEY => self::decodeMoney($data),
            self::WIRE_INET,
            self::WIRE_CIDR => $data,
            self::WIRE_ARRAY => self::parseArrayLiteral($data),
            self::WIRE_VECTOR => self::parseVectorLiteral($data),
            default => $data,
        };
    }

    public static function wireTypeName(int $wireType): string
    {
        return match ($wireType) {
            self::WIRE_BOOL => 'boolean',
            self::WIRE_INT16 => 'int16',
            self::WIRE_INT32 => 'int32',
            self::WIRE_INT64 => 'int64',
            self::WIRE_FLOAT32 => 'float32',
            self::WIRE_FLOAT64 => 'float64',
            self::WIRE_DECIMAL => 'decimal',
            self::WIRE_VARCHAR => 'varchar',
            self::WIRE_CHAR => 'char',
            self::WIRE_BYTEA => 'bytea',
            self::WIRE_DATE => 'date',
            self::WIRE_TIME => 'time',
            self::WIRE_TIMESTAMP => 'timestamp',
            self::WIRE_TIMESTAMPTZ => 'timestamptz',
            self::WIRE_INTERVAL => 'interval',
            self::WIRE_UUID => 'uuid',
            self::WIRE_JSON => 'json',
            self::WIRE_JSONB => 'jsonb',
            self::WIRE_ARRAY => 'array',
            self::WIRE_VECTOR => 'vector',
            self::WIRE_MONEY => 'money',
            self::WIRE_XML => 'xml',
            self::WIRE_INET => 'inet',
            self::WIRE_CIDR => 'cidr',
            default => 'unknown',
        };
    }

    private static function unpackInt16(string $data): int
    {
        $value = unpack('v', $data)[1];
        if ($value >= 0x8000) {
            $value -= 0x10000;
        }
        return $value;
    }

    private static function unpackInt32(string $data): int
    {
        $value = unpack('V', $data)[1];
        if ($value >= 0x80000000) {
            $value -= 0x100000000;
        }
        return $value;
    }

    private static function unpackInt64(string $data): int
    {
        return unpack('q', $data)[1];
    }

    private static function unpackFloat32(string $data): float
    {
        return unpack('g', $data)[1];
    }

    private static function unpackFloat64(string $data): float
    {
        return unpack('e', $data)[1];
    }

    private static function decodeDate(string $data): \DateTimeImmutable
    {
        $days = self::unpackInt32($data);
        $base = new \DateTimeImmutable('2000-01-01 00:00:00', new \DateTimeZone('UTC'));
        return $base->modify("+{$days} days");
    }

    private static function decodeTime(string $data): \DateTimeImmutable
    {
        $micros = (int)self::unpackInt64($data);
        $seconds = intdiv($micros, 1000000);
        $microPart = $micros % 1000000;
        $time = new \DateTimeImmutable('@' . $seconds);
        $time = $time->setTimezone(new \DateTimeZone('UTC'));
        return $time->modify(sprintf('+0 seconds'))->setTime(
            (int)$time->format('H'),
            (int)$time->format('i'),
            (int)$time->format('s'),
            $microPart
        );
    }

    private static function decodeTimestamp(string $data): \DateTimeImmutable
    {
        $micros = (int)self::unpackInt64($data);
        $seconds = intdiv($micros, 1000000);
        $microPart = $micros % 1000000;
        $dt = new \DateTimeImmutable('@' . $seconds);
        $dt = $dt->setTimezone(new \DateTimeZone('UTC'));
        return $dt->setTime(
            (int)$dt->format('H'),
            (int)$dt->format('i'),
            (int)$dt->format('s'),
            $microPart
        );
    }

    private static function decodeInterval(string $data): array
    {
        $months = unpack('V', substr($data, 0, 4))[1];
        $days = unpack('V', substr($data, 4, 4))[1];
        $micros = self::unpackInt64(substr($data, 8, 8));
        return ['months' => $months, 'days' => $days, 'micros' => $micros];
    }

    private static function decodeUuid(string $data): string
    {
        $hex = bin2hex($data);
        if (strlen($hex) !== 32) {
            return $hex;
        }
        return substr($hex, 0, 8) . '-' . substr($hex, 8, 4) . '-' . substr($hex, 12, 4) . '-' . substr($hex, 16, 4) . '-' . substr($hex, 20);
    }

    private static function decodeMoney(string $data): string
    {
        $cents = (string)self::unpackInt64($data);
        if (strlen($cents) <= 2) {
            return '0.' . str_pad($cents, 2, '0', STR_PAD_LEFT);
        }
        return substr($cents, 0, -2) . '.' . substr($cents, -2);
    }

    private static function parseArrayLiteral(string $text): array
    {
        $trimmed = trim($text);
        if ($trimmed === '' || $trimmed === '{}') {
            return [];
        }
        if ($trimmed[0] === '{' && $trimmed[strlen($trimmed) - 1] === '}') {
            $trimmed = substr($trimmed, 1, -1);
        }
        return self::splitArrayItems($trimmed);
    }

    private static function splitArrayItems(string $text): array
    {
        $items = [];
        $depth = 0;
        $buffer = '';
        $chars = str_split($text);
        foreach ($chars as $ch) {
            if ($ch === '{') {
                $depth++;
                $buffer .= $ch;
                continue;
            }
            if ($ch === '}') {
                $depth = max(0, $depth - 1);
                $buffer .= $ch;
                continue;
            }
            if ($ch === ',' && $depth === 0) {
                $items[] = self::parseArrayItem($buffer);
                $buffer = '';
                continue;
            }
            $buffer .= $ch;
        }
        if ($buffer !== '' || $text !== '') {
            $items[] = self::parseArrayItem($buffer);
        }
        return $items;
    }

    private static function parseArrayItem(string $raw): mixed
    {
        $token = trim($raw);
        if (strcasecmp($token, 'NULL') === 0) {
            return null;
        }
        if (str_starts_with($token, '{') && str_ends_with($token, '}')) {
            return self::parseArrayLiteral($token);
        }
        if (str_starts_with($token, '[') && str_ends_with($token, ']')) {
            return self::parseVectorLiteral($token);
        }
        if (strcasecmp($token, 'true') === 0 || strcasecmp($token, 'false') === 0) {
            return strcasecmp($token, 'true') === 0;
        }
        if (is_numeric($token)) {
            return strpos($token, '.') !== false ? (float)$token : (int)$token;
        }
        return $token;
    }

    private static function parseVectorLiteral(string $text): array
    {
        $trimmed = trim($text);
        if (str_starts_with($trimmed, '[') && str_ends_with($trimmed, ']')) {
            $trimmed = substr($trimmed, 1, -1);
        }
        if ($trimmed === '') {
            return [];
        }
        $parts = explode(',', $trimmed);
        $out = [];
        foreach ($parts as $part) {
            $value = trim($part);
            $out[] = is_numeric($value) ? (float)$value : 0.0;
        }
        return $out;
    }
}
