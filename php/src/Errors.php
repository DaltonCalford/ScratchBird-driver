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

class ScratchBirdException extends \RuntimeException
{
    public string $sqlState = '';
    public string $detail = '';
    public string $hint = '';

    public function __construct(string $message, string $sqlState = '', string $detail = '', string $hint = '')
    {
        parent::__construct($message);
        $this->sqlState = $sqlState;
        $this->detail = $detail;
        $this->hint = $hint;
    }
}

class ScratchBirdWarning extends ScratchBirdException {}
class ScratchBirdNoDataException extends ScratchBirdException {}
class ScratchBirdConnectionException extends ScratchBirdException {}
class ScratchBirdNotSupportedException extends ScratchBirdException {}
class ScratchBirdDataException extends ScratchBirdException {}
class ScratchBirdIntegrityException extends ScratchBirdException {}
class ScratchBirdAuthException extends ScratchBirdException {}
class ScratchBirdTransactionException extends ScratchBirdException {}
class ScratchBirdSyntaxException extends ScratchBirdException {}
class ScratchBirdResourceException extends ScratchBirdException {}
class ScratchBirdLimitException extends ScratchBirdException {}
class ScratchBirdOperatorInterventionException extends ScratchBirdException {}
class ScratchBirdSystemException extends ScratchBirdException {}
class ScratchBirdInternalException extends ScratchBirdException {}

final class ErrorMapper
{
    public static function map(string $sqlState, string $message, string $detail = '', string $hint = ''): ScratchBirdException
    {
        $prefix = substr($sqlState, 0, 2);
        return match ($prefix) {
            '01' => new ScratchBirdWarning($message, $sqlState, $detail, $hint),
            '02' => new ScratchBirdNoDataException($message, $sqlState, $detail, $hint),
            '08' => new ScratchBirdConnectionException($message, $sqlState, $detail, $hint),
            '0A' => new ScratchBirdNotSupportedException($message, $sqlState, $detail, $hint),
            '22' => new ScratchBirdDataException($message, $sqlState, $detail, $hint),
            '23' => new ScratchBirdIntegrityException($message, $sqlState, $detail, $hint),
            '28' => new ScratchBirdAuthException($message, $sqlState, $detail, $hint),
            '40' => new ScratchBirdTransactionException($message, $sqlState, $detail, $hint),
            '42' => new ScratchBirdSyntaxException($message, $sqlState, $detail, $hint),
            '53' => new ScratchBirdResourceException($message, $sqlState, $detail, $hint),
            '54' => new ScratchBirdLimitException($message, $sqlState, $detail, $hint),
            '57' => new ScratchBirdOperatorInterventionException($message, $sqlState, $detail, $hint),
            '58' => new ScratchBirdSystemException($message, $sqlState, $detail, $hint),
            'XX' => new ScratchBirdInternalException($message, $sqlState, $detail, $hint),
            default => new ScratchBirdException($message, $sqlState, $detail, $hint),
        };
    }
}
