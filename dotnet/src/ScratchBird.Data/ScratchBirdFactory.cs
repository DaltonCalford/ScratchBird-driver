// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Data.Common;

namespace ScratchBird.Data;

public sealed class ScratchBirdFactory : DbProviderFactory
{
    public static readonly ScratchBirdFactory Instance = new();

    public override DbConnection CreateConnection() => new ScratchBirdConnection();
    public override DbCommand CreateCommand() => new ScratchBirdCommand();
    public override DbParameter CreateParameter() => new ScratchBirdParameter();
}
