// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Data;
using System.Data.Common;

namespace ScratchBird.Data;

public sealed class ScratchBirdTransaction : DbTransaction
{
    private readonly ScratchBirdConnection _connection;
    private readonly IsolationLevel _isolationLevel;
    private bool _completed;

    internal ScratchBirdTransaction(ScratchBirdConnection connection, IsolationLevel isolationLevel)
    {
        _connection = connection;
        _isolationLevel = isolationLevel;
    }

    public override IsolationLevel IsolationLevel => _isolationLevel;

    protected override DbConnection DbConnection => _connection;

    public override void Commit()
    {
        if (_completed)
        {
            return;
        }
        _connection.Client.Commit();
        _completed = true;
    }

    public override void Rollback()
    {
        if (_completed)
        {
            return;
        }
        _connection.Client.Rollback();
        _completed = true;
    }
}
