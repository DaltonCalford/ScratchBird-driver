// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Data.Common;

namespace ScratchBird.Data;

public class ScratchBirdException : DbException
{
    public string? SqlState { get; }
    public string? Detail { get; }
    public string? Hint { get; }

    public ScratchBirdException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message)
    {
        SqlState = sqlState;
        Detail = detail;
        Hint = hint;
    }
}

public class ScratchBirdWarning : ScratchBirdException
{
    public ScratchBirdWarning(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdNoDataException : ScratchBirdException
{
    public ScratchBirdNoDataException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdConnectionException : ScratchBirdException
{
    public ScratchBirdConnectionException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdNotSupportedException : ScratchBirdException
{
    public ScratchBirdNotSupportedException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdDataException : ScratchBirdException
{
    public ScratchBirdDataException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdIntegrityException : ScratchBirdException
{
    public ScratchBirdIntegrityException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdAuthException : ScratchBirdException
{
    public ScratchBirdAuthException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdTransactionException : ScratchBirdException
{
    public ScratchBirdTransactionException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdSyntaxException : ScratchBirdException
{
    public ScratchBirdSyntaxException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdResourceException : ScratchBirdException
{
    public ScratchBirdResourceException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdLimitException : ScratchBirdException
{
    public ScratchBirdLimitException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdOperatorInterventionException : ScratchBirdException
{
    public ScratchBirdOperatorInterventionException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdSystemException : ScratchBirdException
{
    public ScratchBirdSystemException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public class ScratchBirdInternalException : ScratchBirdException
{
    public ScratchBirdInternalException(string message, string? sqlState = null, string? detail = null, string? hint = null)
        : base(message, sqlState, detail, hint) { }
}

public static class ScratchBirdSqlStateMapper
{
    public static ScratchBirdException Create(string message, string? sqlState, string? detail, string? hint)
    {
        if (string.IsNullOrEmpty(sqlState) || sqlState.Length < 2)
        {
            return new ScratchBirdException(message, sqlState, detail, hint);
        }

        var cls = sqlState.Substring(0, 2);
        return cls switch
        {
            "01" => new ScratchBirdWarning(message, sqlState, detail, hint),
            "02" => new ScratchBirdNoDataException(message, sqlState, detail, hint),
            "08" => new ScratchBirdConnectionException(message, sqlState, detail, hint),
            "0A" => new ScratchBirdNotSupportedException(message, sqlState, detail, hint),
            "22" => new ScratchBirdDataException(message, sqlState, detail, hint),
            "23" => new ScratchBirdIntegrityException(message, sqlState, detail, hint),
            "28" => new ScratchBirdAuthException(message, sqlState, detail, hint),
            "40" => new ScratchBirdTransactionException(message, sqlState, detail, hint),
            "42" => new ScratchBirdSyntaxException(message, sqlState, detail, hint),
            "53" => new ScratchBirdResourceException(message, sqlState, detail, hint),
            "54" => new ScratchBirdLimitException(message, sqlState, detail, hint),
            "57" => new ScratchBirdOperatorInterventionException(message, sqlState, detail, hint),
            "58" => new ScratchBirdSystemException(message, sqlState, detail, hint),
            "XX" => new ScratchBirdInternalException(message, sqlState, detail, hint),
            _ => new ScratchBirdException(message, sqlState, detail, hint)
        };
    }
}
