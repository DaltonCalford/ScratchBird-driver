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

final class Sql
{
    public static function normalize(string $sql, array $params): array
    {
        if (empty($params)) {
            return ['sql' => $sql, 'params' => []];
        }

        if (self::hasNamedParameters($sql)) {
            return self::rewriteNamed($sql, $params);
        }

        if (str_contains($sql, '?')) {
            return self::rewritePositional($sql, $params);
        }

        return ['sql' => $sql, 'params' => array_values($params)];
    }

    private static function hasNamedParameters(string $sql): bool
    {
        $len = strlen($sql);
        $inString = false;
        for ($i = 0; $i + 1 < $len; $i++) {
            $ch = $sql[$i];
            if ($ch === "'") {
                $inString = !$inString;
                continue;
            }
            if ($inString) {
                continue;
            }
            if (self::isNamedParameterStart($sql, $i)) {
                return true;
            }
        }
        return false;
    }

    private static function rewriteNamed(string $sql, array $params): array
    {
        $lookup = [];
        foreach ($params as $key => $value) {
            if (is_string($key)) {
                $lookup[ltrim($key, '@:')] = $value;
            }
        }
        $ordered = [];
        $out = '';
        $len = strlen($sql);
        $inString = false;
        for ($i = 0; $i < $len;) {
            $ch = $sql[$i];
            if ($ch === "'") {
                $inString = !$inString;
                $out .= $ch;
                $i++;
                continue;
            }
            if (!$inString && self::isNamedParameterStart($sql, $i)) {
                $j = $i + 1;
                while ($j < $len && (ctype_alnum($sql[$j]) || $sql[$j] === '_')) {
                    $j++;
                }
                $name = substr($sql, $i + 1, $j - $i - 1);
                if (!array_key_exists($name, $lookup)) {
                    throw new \InvalidArgumentException("missing named parameter: {$name}");
                }
                $ordered[] = $lookup[$name];
                $out .= '$' . count($ordered);
                $i = $j;
                continue;
            }
            $out .= $ch;
            $i++;
        }
        return ['sql' => $out, 'params' => $ordered];
    }

    private static function rewritePositional(string $sql, array $params): array
    {
        $ordered = [];
        $out = '';
        $len = strlen($sql);
        $inString = false;
        $index = 0;
        for ($i = 0; $i < $len;) {
            $ch = $sql[$i];
            if ($ch === "'") {
                $inString = !$inString;
                $out .= $ch;
                $i++;
                continue;
            }
            if (!$inString && $ch === '?') {
                if (!array_key_exists($index, $params)) {
                    throw new \InvalidArgumentException('not enough parameters');
                }
                $ordered[] = $params[$index];
                $index++;
                $out .= '$' . count($ordered);
                $i++;
                continue;
            }
            $out .= $ch;
            $i++;
        }
        if ($index < count($params)) {
            throw new \InvalidArgumentException('too many parameters');
        }
        return ['sql' => $out, 'params' => $ordered];
    }

    private static function isNamedParameterStart(string $sql, int $index): bool
    {
        $len = strlen($sql);
        if ($index < 0 || $index + 1 >= $len) {
            return false;
        }

        $marker = $sql[$index];
        if ($marker !== ':' && $marker !== '@') {
            return false;
        }
        if (!ctype_alpha($sql[$index + 1])) {
            return false;
        }
        if ($marker === ':' && $index > 0 && $sql[$index - 1] === ':') {
            return false;
        }
        return true;
    }
}
