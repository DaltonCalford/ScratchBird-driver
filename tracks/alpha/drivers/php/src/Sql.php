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

    public static function normalizeCallable(string $sql, array $params): array
    {
        return self::normalize(self::normalizeCallableSql($sql), $params);
    }

    public static function normalizeCallableSql(string $sql): string
    {
        $trimmed = trim($sql);
        if (!str_starts_with($trimmed, '{') || !str_ends_with($trimmed, '}')) {
            return $sql;
        }
        $inner = trim(substr($trimmed, 1, -1));
        if ($inner === '') {
            return $sql;
        }

        if (preg_match('/^\?\s*=\s*call\s+([\s\S]+)$/i', $inner, $matches) === 1) {
            $parsed = self::parseCallableInvocation(trim($matches[1]));
            if ($parsed === null) {
                throw new \InvalidArgumentException('invalid JDBC escape call syntax');
            }
            [$routine, $args, $hasParens] = $parsed;
            $callArgs = $hasParens ? $args : '';
            return sprintf('select %s(%s) as return_value', $routine, $callArgs);
        }

        if (preg_match('/^call\s+([\s\S]+)$/i', $inner, $matches) === 1) {
            $parsed = self::parseCallableInvocation(trim($matches[1]));
            if ($parsed === null) {
                throw new \InvalidArgumentException('invalid JDBC escape call syntax');
            }
            [$routine, $args, $hasParens] = $parsed;
            if ($hasParens) {
                return sprintf('call %s(%s)', $routine, $args);
            }
            return sprintf('call %s', $routine);
        }

        return $sql;
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

    /**
     * @return array{0: string, 1: string, 2: bool}|null
     */
    private static function parseCallableInvocation(string $text): ?array
    {
        $openParen = strpos($text, '(');
        if ($openParen === false) {
            $routine = trim($text);
            if ($routine === '') {
                return null;
            }
            return [$routine, '', false];
        }

        $inSingle = false;
        $inDouble = false;
        $depth = 0;
        $closeParen = -1;
        $len = strlen($text);
        for ($i = $openParen; $i < $len; $i++) {
            $ch = $text[$i];
            if ($ch === "'" && !$inDouble) {
                $inSingle = !$inSingle;
                continue;
            }
            if ($ch === '"' && !$inSingle) {
                $inDouble = !$inDouble;
                continue;
            }
            if ($inSingle || $inDouble) {
                continue;
            }
            if ($ch === '(') {
                $depth++;
                continue;
            }
            if ($ch === ')') {
                $depth--;
                if ($depth === 0) {
                    $closeParen = $i;
                    break;
                }
            }
        }

        if ($closeParen < 0) {
            return null;
        }
        $routine = trim(substr($text, 0, $openParen));
        if ($routine === '') {
            return null;
        }
        $trailing = trim(substr($text, $closeParen + 1));
        if ($trailing !== '') {
            return null;
        }
        $args = trim(substr($text, $openParen + 1, $closeParen - $openParen - 1));
        return [$routine, $args, true];
    }
}
