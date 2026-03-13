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
        if (strlen($sqlState) === 5) {
            $mapped = match ($sqlState) {
                '01000' => new ScratchBirdWarning($message, $sqlState, $detail, $hint),
                '02000' => new ScratchBirdNoDataException($message, $sqlState, $detail, $hint),
                '08001', '08003', '08004', '08006', '08P01' => new ScratchBirdConnectionException($message, $sqlState, $detail, $hint),
                '0A000' => new ScratchBirdNotSupportedException($message, $sqlState, $detail, $hint),
                '22001', '22003', '22007', '22012', '22023', '22P02', '22P03' => new ScratchBirdDataException($message, $sqlState, $detail, $hint),
                '23000', '23502', '23503', '23505', '23514' => new ScratchBirdIntegrityException($message, $sqlState, $detail, $hint),
                '28000', '28P01' => new ScratchBirdAuthException($message, $sqlState, $detail, $hint),
                '40001', '40P01' => new ScratchBirdTransactionException($message, $sqlState, $detail, $hint),
                '42501', '42601', '42703', '42704', '42710', '42883', '42P01', '42P07' => new ScratchBirdSyntaxException($message, $sqlState, $detail, $hint),
                '53P00', '53100', '53200', '53300' => new ScratchBirdResourceException($message, $sqlState, $detail, $hint),
                '54000' => new ScratchBirdLimitException($message, $sqlState, $detail, $hint),
                '57014', '57P01', '57P03' => new ScratchBirdOperatorInterventionException($message, $sqlState, $detail, $hint),
                '58000' => new ScratchBirdSystemException($message, $sqlState, $detail, $hint),
                'XX000' => new ScratchBirdInternalException($message, $sqlState, $detail, $hint),
                default => null,
            };
            if ($mapped !== null) {
                return $mapped;
            }

            return match (substr($sqlState, 0, 2)) {
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
        return new ScratchBirdException($message, $sqlState, $detail, $hint);
    }
}
