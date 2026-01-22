<?php

namespace ScratchBird\PDO;

final class Sql
{
    public static function substitute(string $sql, array $params): string
    {
        if (empty($params)) {
            return $sql;
        }
        if (self::hasNamedParameters($sql)) {
            return self::substituteNamed($sql, $params);
        }
        return self::substitutePositional($sql, $params);
    }

    private static function hasNamedParameters(string $sql): bool
    {
        $len = strlen($sql);
        for ($i = 0; $i < $len - 1; $i++) {
            $ch = $sql[$i];
            if (($ch === '@' || $ch === ':') && ctype_alpha($sql[$i + 1])) {
                return true;
            }
        }
        return false;
    }

    private static function substituteNamed(string $sql, array $params): string
    {
        $lookup = [];
        foreach ($params as $key => $value) {
            if (is_string($key)) {
                $lookup[ltrim($key, '@:')] = $value;
            }
        }
        $out = '';
        $i = 0;
        $len = strlen($sql);
        while ($i < $len) {
            $ch = $sql[$i];
            if ($ch === '\'' && $i + 1 < $len) {
                $out .= $ch;
                $i++;
                while ($i < $len) {
                    $out .= $sql[$i];
                    if ($sql[$i] === '\'' && ($i + 1 >= $len || $sql[$i + 1] !== '\'')) {
                        $i++;
                        break;
                    }
                    if ($sql[$i] === '\'' && $i + 1 < $len && $sql[$i + 1] === '\'') {
                        $i++;
                    }
                    $i++;
                }
                continue;
            }
            if (($ch === '@' || $ch === ':') && $i + 1 < $len && ctype_alpha($sql[$i + 1])) {
                $j = $i + 1;
                while ($j < $len && (ctype_alnum($sql[$j]) || $sql[$j] === '_')) {
                    $j++;
                }
                $name = substr($sql, $i + 1, $j - $i - 1);
                if (array_key_exists($name, $lookup)) {
                    $out .= self::formatValue($lookup[$name]);
                } else {
                    $out .= substr($sql, $i, $j - $i);
                }
                $i = $j;
                continue;
            }
            $out .= $ch;
            $i++;
        }
        return $out;
    }

    private static function substitutePositional(string $sql, array $params): string
    {
        $out = '';
        $i = 0;
        $index = 0;
        $len = strlen($sql);
        while ($i < $len) {
            $ch = $sql[$i];
            if ($ch === '?') {
                if (array_key_exists($index, $params)) {
                    $out .= self::formatValue($params[$index]);
                    $index++;
                } else {
                    $out .= $ch;
                }
                $i++;
                continue;
            }
            if ($ch === '$' && $i + 1 < $len && ctype_digit($sql[$i + 1])) {
                $j = $i + 1;
                $num = 0;
                while ($j < $len && ctype_digit($sql[$j])) {
                    $num = $num * 10 + (int)$sql[$j];
                    $j++;
                }
                if ($num > 0 && isset($params[$num - 1])) {
                    $out .= self::formatValue($params[$num - 1]);
                } else {
                    $out .= substr($sql, $i, $j - $i);
                }
                $i = $j;
                continue;
            }
            if ($ch === '\'' && $i + 1 < $len) {
                $out .= $ch;
                $i++;
                while ($i < $len) {
                    $out .= $sql[$i];
                    if ($sql[$i] === '\'' && ($i + 1 >= $len || $sql[$i + 1] !== '\'')) {
                        $i++;
                        break;
                    }
                    if ($sql[$i] === '\'' && $i + 1 < $len && $sql[$i + 1] === '\'') {
                        $i++;
                    }
                    $i++;
                }
                continue;
            }
            $out .= $ch;
            $i++;
        }
        return $out;
    }

    public static function formatValue(mixed $value): string
    {
        if ($value === null) {
            return 'NULL';
        }
        if (is_bool($value)) {
            return $value ? 'TRUE' : 'FALSE';
        }
        if (is_int($value) || is_float($value)) {
            return (string)$value;
        }
        if ($value instanceof \DateTimeInterface) {
            return "'" . $value->format('Y-m-d H:i:s.u') . "'";
        }
        if (is_string($value)) {
            return "'" . self::escape($value) . "'";
        }
        if (is_array($value)) {
            return self::formatArray($value);
        }
        if (is_object($value) && method_exists($value, '__toString')) {
            return "'" . self::escape((string)$value) . "'";
        }
        return "'" . self::escape((string)$value) . "'";
    }

    private static function formatArray(array $values): string
    {
        $items = [];
        foreach ($values as $value) {
            $items[] = self::formatValue($value);
        }
        return 'ARRAY[' . implode(', ', $items) . ']';
    }

    private static function escape(string $value): string
    {
        return str_replace(["\\", "'"], ["\\\\", "''"], $value);
    }
}
